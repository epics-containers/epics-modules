# EPICS Dockerfile for Asyn and other fundamental support modules

##### build stage ##############################################################

ARG BASE=ghcr.io/epics-containers/epics-base:1.0.0

FROM  ${BASE} AS developer

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    locales \
    libc-dev-bin \
    libusb-1.0-0-dev \
    python3-pip \
    python3.10-minimal \
    re2c \
    wget \
    && rm -rf /var/lib/apt/lists/*

# import support folder root files
COPY ./support/. ${SUPPORT}/

WORKDIR ${SUPPORT}

# setup module.py for managing support module dependencies
RUN  pip install -r requirements.txt

# initialize the global support/configure/RELEASE
RUN python3 module.py init

# get basic support modules in order of dependencies
RUN python3 module.py add-tar http://www-csr.bessy.de/control/SoftDist/sequencer/releases/seq-{TAG}.tar.gz seq SNCSEQ 2.2.9 && \
    python3 module.py add epics-modules sscan SSCAN R2-11-5 && \
    python3 module.py add epics-modules calc CALC R3-7-4 && \
    python3 module.py add epics-modules asyn ASYN R4-42 && \
    python3 module.py add epics-modules alive ALIVE R1-3-1 && \
    python3 module.py add epics-modules autosave AUTOSAVE  R5-10-2 && \
    python3 module.py add epics-modules busy BUSY R1-7-3 && \
    python3 module.py add epics-modules iocStats DEVIOCSTATS 3.1.16 && \
    python3 module.py add epics-modules std STD R3-6-3 && \
    python3 module.py add paulscherrerinstitute StreamDevice STREAM 2.8.22

# patch support modules and fix up all dependencies
RUN echo IOC=${IOC} >> configure/RELEASE && \
    ./patch_modules.sh && \
    python3 module.py dependencies

# add the generic IOC source code
COPY ioc ${IOC}

# compile the support modules and the IOC
RUN make && \
    make -j clean

##### runtime stage ############################################################

FROM ${BASE}.run AS runtime

# install runtime libraries from additional packages section above
# also add busybox to aid debugging the runtime image

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    busybox-static \
    libusb-1.0-0 \
    && rm -rf /var/lib/apt/lists/*


# get the products from the build stage
COPY --from=developer ${SUPPORT} ${SUPPORT}
COPY --from=developer ${IOC} ${IOC}
