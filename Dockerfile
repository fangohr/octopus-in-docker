FROM debian:bookworm

# install Octopus 13.0 on Debian

# Convenience tools (up to emacs)
# Libraries that octopus needs
# and optional dependencies (in alphabetical order)
RUN apt-get -y update && apt-get -y install wget time nano vim emacs \
    autoconf \
    automake \
    build-essential \
    g++ \
    gcc \
    gfortran \
    git \
    libatlas-base-dev \
    libblas-dev \
    libboost-dev \
    libcgal-dev \
    libelpa-dev \
    libetsf-io-dev \
    libfftw3-dev \
    libgmp-dev \
    libgsl-dev \
    liblapack-dev \
    liblapack-dev \
    libmpfr-dev \
    libnetcdff-dev \
    libnlopt-dev \
    libopenmpi-dev \
    libscalapack-mpi-dev \
    libspfft-dev \
    libtool \
    libxc-dev \
    libyaml-dev \
    openscad \
    openctm-tools \
    pkg-config \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Add optional packages not needed by octopus (for visualization)
RUN apt-get -y update && apt-get -y install gnuplot \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN wget -O oct.tar.gz https://octopus-code.org/download/13.0/octopus-13.0.tar.gz && tar xfvz oct.tar.gz && rm oct.tar.gz

WORKDIR /opt/octopus-13.0
RUN autoreconf -i
# We need to set FCFLAGS_ELPA as the octopus m4 has a bug
# see https://gitlab.com/octopus-code/octopus/-/issues/900
RUN export FCFLAGS_ELPA="-I/usr/include -I/usr/include/elpa/modules" && \
    ./configure --enable-mpi --enable-openmp --with-blacs="-lscalapack-openmpi"

# Which optional dependencies are missing?
RUN cat config.log | grep WARN > octopus-configlog-warnings
RUN cat octopus-configlog-warnings

# all in one line to make image smaller
RUN make -j && make install && make clean && make distclean

RUN octopus --version > octopus-version
RUN octopus --version

# The next command returns an error code as some tests fail
# RUN make check-short

RUN mkdir -p /opt/octopus-examples
COPY examples /opt/octopus-examples

# Instead of tests, run two short examples
RUN cd /opt/octopus-examples/recipe && octopus
RUN cd /opt/octopus-examples/h-atom && octopus
RUN cd /opt/octopus-examples/he && octopus

# allow root execution of mpirun
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# set number of OpenMP threads to 1 by default
ENV OMP_NUM_THREADS=1

# run one MPI-enabled version
RUN cd /opt/octopus-examples/he && mpirun -np 1 octopus
RUN cd /opt/octopus-examples/he && mpirun -np 2 octopus

# test the libraries used by octopus
RUN cd /opt/octopus-examples/recipe && octopus > /tmp/octopus-recipe.out
# test that the libraries are mentioned in the configuration options section of octopus output
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "openmp"
RUN grep "Configuration options" /tmp/octopus-recipe.out | grep "mpi"
# test that the libraries are mentioned in the optional libraries section of octopus output
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "cgal"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "scalapack"
RUN grep "Optional libraries" /tmp/octopus-recipe.out | grep "ELPA"

# make optional libraries information available as part of container
RUN grep "Optional libraries" /tmp/octopus-recipe.out > octopus-optional-libraries

# offer directory for mounting container
WORKDIR /io

CMD bash -l
