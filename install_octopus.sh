#!/bin/bash
# This script prepares the download of octopus in the right location given the version number, location to untar / clone and install prefix
# the final argument is the level of checks to be run
# 0: no checks
# 1: check-short
# 2: check-long
# 3: check-short and check-long

# example run:
# $ ./install_octopus.sh 13.0 /opt/octopus /home/user/octopus-bin
# $ ./install_octopus.sh 13.0 /opt/octopus /home/user/octopus-bin 3
# $ ./install_octopus.sh develop /opt/octopus
# Consider runing install_dependencies.sh first to install all the dependencies on a debian based system

# exit on error and print each command
set -xe

# Check if the version number and location is provided
if [ -z "$1" ]
  then
    echo "No version number provided"
    exit 1
else
  version=$1
fi
if [ -z "$2" ]
  then
    echo "No download location provided"
    exit 1
else
    location=$2
fi
if [ -z "$3" ]
  then
    echo "No install prefix provided using default location"
    prefix=/usr/local
else
    prefix=$3
fi
if [ -z "$4" ]
  then
    echo "Tests not requsted, skipping make check"
    check_level=0
else
    check_level=$4
fi

# make the location if it does not exist
if [ ! -d $location ]; then
  mkdir -p $location
fi
cd $location

# if develop is provided, clone the main branch

if [ $version == "develop" ]; then
  git clone https://gitlab.com/octopus-code/octopus.git .
else
    # download the tar file
    wget https://octopus-code.org/download/${version}/octopus-${version}.tar.gz
    tar -xvf octopus-${version}.tar.gz
    mv octopus-$version/* .
    rm -rf octopus-$version
    # rm octopus-$version.tar.gz
fi

date=$(date)

# Record the version number and date
if [ $version == "develop" ]; then
    # Record which version we are using
    git show > octopus-source-version
    echo "octopus-source-clone-date: $date " >> octopus-source-version
else
    # Record which version we are using
    echo "octopus-source-version: $version " > octopus-source-version
    echo "octopus-source-download-date: $date " >> octopus-source-version
fi

autoreconf -i

# We need to set FCFLAGS_ELPA as the octopus m4 has a bug
# see https://gitlab.com/octopus-code/octopus/-/issues/900
export FCFLAGS_ELPA="-I/usr/include -I/usr/include/elpa/modules"
mkdir _build && pushd _build
# configure
../configure --enable-mpi --enable-openmp --with-blacs="-lscalapack-openmpi" --prefix=$prefix

# Which optional dependencies are missing?
cat config.log | grep WARN > octopus-configlog-warnings
cat octopus-configlog-warnings

# all in one line to make image smaller
make -j && make install



if [ $version == "develop" ]; then
  # Set ENV variable for external libs (only needed for octopus14.0 onwards)
  echo "Section Issue 9 starts here. --------------"
  echo "Issue 9: https://github.com/fangohr/octopus-in-docker/issues/9"
  # DEBUG output
  ldd /usr/local/bin/octopus | grep libsym
  echo $LD_LIBRARY_PATH
  # Setting LD_LIBRARY_PATH as follows works around the octopus bug described in
  # https://github.com/fangohr/octopus-in-docker/issues/9 and also referenced in
  # https://gitlab.com/octopus-code/octopus/-/issues/886
  export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
  echo $LD_LIBRARY_PATH
  echo "Section Issue 9 ends here. ----------------"
fi

# Run the tests if requested
# setup the currect number of cpus and threads to be used.
# octopus by default uses 2 mpi tasks per test
# we can set each task  to use 1 thread
# then the number of tests to run in parallel is number of cpus / (2*1)
if [ "$check_level" -gt 0 ]
then
  NUM_CPUS=$(nproc)
  export OMP_NUM_THREADS=1
  export OCT_TEST_NJOBS=1
  # export OCT_TEST_NJOBS=$((NUM_CPUS/2))

  if [ "$check_level" -eq 1 ]; then make check-short; fi
  if [ "$check_level" -eq 2 ]; then make check-long; fi
  if [ "$check_level" -eq 3 ]; then make check; fi
fi

# Clean up
make clean && make distclean