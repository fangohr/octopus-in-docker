FROM debian:bookworm

# install Octopus (latest stable or develop) on Debian

# the version to install (latest stable or develop) is set by buildarg VERSION_OCTOPUS
ARG VERSION_OCTOPUS=develop

# One can run the tests in the container after compiling the code
# by setting the CHECK_LEVEL variable
# 0: no checks
# 1: check-short
# 2: check-long
# 3: check-short and check-long
ARG CHECK_LEVEL=0

## Set the environment variables
# allow root execution of mpirun
ENV OMPI_ALLOW_RUN_AS_ROOT=1
ENV OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

# set number of OpenMP threads to 1 by default
ENV OMP_NUM_THREADS=1


# Install octopus dependencies and compile octopus.
WORKDIR /opt
COPY *.sh /opt
RUN bash /opt/install_dependencies.sh
#   bash /opt/install_octopus.sh $VERSION_OCTOPUS $OCTOPUS_SOURCE_DIR $OCTOPUS_INSTALL_DIR $CHECK_LEVEL
RUN bash /opt/install_octopus.sh $VERSION_OCTOPUS /opt/octopus /usr/local ${CHECK_LEVEL}

# on octopus>13 libsym (external-lib) is dynamically linked and hence needs LD_LIBRARY_PATH set
# see https://github.com/fangohr/octopus-in-docker/issues/9
ENV LD_LIBRARY_PATH="/usr/local/lib"

WORKDIR /opt/octopus

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



# offer directory for mounting container
WORKDIR /io

CMD bash -l
