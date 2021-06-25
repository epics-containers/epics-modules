# EPICS Dockerfile for Asyn and other fundamental support modules
ARG REGISTRY=ghcr.io/epics-containers
ARG EPICS_VERSION=7.0.5r2.0

FROM ${REGISTRY}/epics-base:${EPICS_VERSION}

# install additional tools
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libc-dev-bin \
    libusb-1.0-0-dev \
    python3-pip \
    python3.8-minimal \
    re2c \
    wget \
    && rm -rf /var/lib/apt/lists/*

# environment
ENV SUPPORT ${EPICS_ROOT}/support
WORKDIR ${SUPPORT}

# setup module.py for managing support module dependencies
COPY --chown=${USER_UID}:${USER_GID} ./support/. ${SUPPORT}/
RUN chown ${USERNAME} ${SUPPORT} && \
    pip install -r requirements.txt

USER ${USERNAME}

# initialize the global support/configure/RELEASE
RUN python3 module.py init

# get basic support modules in order of dependencies
RUN python3 module.py add-tar http://www-csr.bessy.de/control/SoftDist/sequencer/releases/seq-{TAG}.tar.gz seq SNCSEQ 2.2.8 && \
    python3 module.py add epics-modules sscan SSCAN R2-11-4 && \
    python3 module.py add epics-modules calc CALC R3-7-4 && \
    python3 module.py add epics-modules asyn ASYN R4-41 && \
    python3 module.py add epics-modules alive ALIVE R1-3-1 && \
    python3 module.py add epics-modules autosave AUTOSAVE  R5-10-2 && \
    python3 module.py add epics-modules busy BUSY R1-7-3 && \
    python3 module.py add epics-modules iocStats DEVIOCSTATS 3.1.16 && \
    python3 module.py add epics-modules std STD R3-6-2 && \
    python3 module.py add paulscherrerinstitute StreamDevice STREAM 2.8.16

# patch support modules and fix up all dependencies
RUN echo IOC=${EPICS_ROOT}/ioc >> configure/RELEASE && \
    ./patch_modules.sh && \
    python3 module.py dependencies

# add the generic IOC source code
COPY --chown=${USER_UID}:${USER_GID} ioc ${EPICS_ROOT}/ioc

# compile the support modules and the IOC
RUN cat /epics/support/seq-2-2-8/configure/RELEASE && \
    make && \
    make -j clean
