Repository for building and executing the `OCTOPUS code
<http://octopus-code.org>`__ package in a Docker container. 

Use case: run Octopus (for small calculations and tutorials) conveniently in a
container, in particular on MacOS and Windows where compilation of Octopus may be non trivial.


Octopus in Docker container
===========================

Quick start
-----------


1. `Install docker <https://docs.docker.com/get-docker/>`__ on your machine.

   Check to confirm: run ``docker --version``. Expected output is something like this::

     $ docker --version
     Docker version 20.10.12, build e91ed57

2. Change into the directory that contains your ``inp`` file.


3. Then run::

    docker run --rm -ti -v $PWD:/io fangohr/octopus octopus
  
   The first time you run this, Docker needs to download the image
   ``fangohr/octopus`` from DockerHub. This could take a while (depending on your
   internet connection, the image size is about 850MB).

   Meaning of the switches:
   
   - ``--rm`` remove docker container after it has been carried out (good practice to reduce disk usage).
   - ``-ti`` start an ``i``nteractive  pseudo-``t``ty shell in the container 
   - ``-v $PWD:/io``: take the current working directory (``$PWD``) and mount it
     in the container in the location ``/io``. This is also the default working
     directory of the container.
   - ``fangohr/octopus`` is the name of the container image. The next 
   - ``octopus`` is the name of the executable to run in the container. You can
     replace this with ``bash`` if you want to start octopus manually from inside
     the container.

   This is tested and known to work on OSX and Windows. On Linux, there is a
   permissions issue if (numerical) user id on the host system and in the
   container deviate. Moreover, in Linux, the files generated would be owned by root,
   and thus could cause issues with further file manipulation (such as deleting files).

   To check which Octopus version you have in the container, you can use::
 
      docker run --rm -ti -v $PWD:/io fangohr/octopus octopus --version

   If you want to use multiple MPI processes (for example 4), change the above line to::
   
       docker run --rm -ti -v $PWD:/io fangohr/octopus mpirun -np 4 octopus

   If you want to use a different Octopus version you can check the `available
   versions <https://hub.docker.com/r/fangohr/octopus/tags>`__, and then add the
   version (for example `13.0`) to the Docker image in the command line::

      docker run --rm -ti -v $PWD:/io fangohr/octopus:13.0 octopus --version
  
Typical workflow with Octopus in container
------------------------------------------

- edit your ``inp`` file and save it  (on the host computer)

- call Octopus (in the container) by running ::

      docker run --rm -ti -v $PWD:/io fangohr/octopus octopus
  
  Only the ``octopus`` command will be carried out in the
  container. Any output files are written to the current directory on the host.

- carry out data analysis on the host

If you want to work interactively *inside* the container, replace the name of the executable with ``bash``::

  docker run --rm -ti -v $PWD:/io fangohr/octopus bash
  
You are then the root user in the container. Octopus was compiled in ``/opt/octopus*``. There are also some trivial example input files in ``/opt/octopus-examples``.

What follows is more detailed documentation which is hopefully not needed for most people.



Documentation for advanced users and developers
===============================================

.. sectnum::

.. contents:: 


Introduction
------------

If you have difficulties compiling Octopus, it might be useful to be able to run
it in a container (for example on Windows or MacOS).

The container provides a mini (Linux) Operating system, in which we can compile
Octopus using a recipe (this is the Dockerfile, see below).

One can then use the editor and analysis tools of your normal operating system
and computer, and carry out the running of the actual Octopus calculations
inside the container.

There are two steps required:

- Step 1: build the container image (only once) or download it (only once).

- Step 2: use the container to execute Octopus inside the container


Step 1: How obtain a Docker container image with Octopus
--------------------------------------------------------

In this repository we provide a `Dockerfile <Dockerfile>`__ to compile Octopus
13.0 and `Dockerfile-develop <Dockerfile-develop>`__ to compile the ``develop``
branch of the Octopus repository in a container.

The following examples are for the 13.0 release version. (To build a container
for the latest Octopus version from the ``develop`` branch, replace
``Dockerfile`` with ``Dockerfile-develop``.)

Option A: Build the Docker image on your computer
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

First clone this repository. Then run::

  docker build -f Dockerfile -t octimage .

On Linux, you need to prefix all docker calls with ``sudo``::

  sudo docker build -f Dockerfile -t octimage .

This will take some time to complete.

Option B: Download Docker image from Dockerhub
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Instead of building it yourself, you can also pull an image from Dockerhub
(`available versions <https://hub.docker.com/r/fangohr/octopus/tags>`__) using::

  docker pull fangohr/octopus:13.0

and then move on to using this image in the next section, where you replace
``octimage`` with ``fangohr/octopus:13.0``.

If the ``docker pull`` command is not run, then docker will execute it
automatically when a ``docker run`` command needs a particular image (such as
``fangohr/octopus:13.0``).


Step 2: Use the Docker image
----------------------------

To use the Docker image::

  docker run --rm -ti -v $PWD:/io octimage octopus

See Quick start section above for more details.


Information for developers: available architectures
---------------------------------------------------

The DockerHub images are available for x86 (AMD64) and M1/M2/M3 (ARM64)
architectures. Docker will download the correct one automatically. (You can use
``docker inspect fangohr/octopus | grep Arch`` to check the architecture
for which you have the image available on your machine,
or use ``uname -m`` inside the container.)


.. |stable| image:: https://github.com/fangohr/octopus-in-docker/actions/workflows/stable.yml/badge.svg
   :target: https://github.com/fangohr/octopus-in-docker/actions/workflows/stable.yml

.. |develop| image:: https://github.com/fangohr/octopus-in-docker/actions/workflows/develop.yml/badge.svg
   :target: https://github.com/fangohr/octopus-in-docker/actions/workflows/debian-develop.yml


Status
======

Status of building the Docker images:

|stable| Debian Bookworm (12), Latest Octopus release (13.0)

|develop| Debian Bookworm (12), Octopus develop branch

