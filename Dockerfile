# EPICS SynApps Dockerfile
ARG REGISTRY=gcr.io/diamond-pubreg/controls/prod
ARG EPICS_VERSION=7.0.5b2.0

FROM ${REGISTRY}/epics/epics-base:${EPICS_VERSION}

ARG VERSION=R0-1

# install additional tools
USER root

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libc-dev-bin \
    libusb-1.0-0-dev \
    python3-pip \
    python3.8 \
    re2c \
    wget \
    && rm -rf /var/lib/apt/lists/*


ENV SUPPORT ${EPICS_ROOT}/support
WORKDIR ${SUPPORT}

COPY --chown=${USER_UID}:${USER_GID} root/* ${SUPPORT}/
RUN chown ${USERNAME} ${SUPPORT}

USER ${USERNAME}
RUN pip install -r requirements.txt


# get the build script and remove apps in ${SKIP_APPS}
RUN git config --global advice.detachedHead false && \
    python3 module.py init

# get basic support modules in order of depenencies
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

RUN ./patch_modules.sh && \
    python3 module.py dependencies

# compile all synapps modules
RUN make && \
    make clean

# # add the generic IOC source and add_module.sh
# COPY --chown=${USER_UID}:${USER_GID} ioc ioc

# # make generic IOC (separate step for efficient image layering)
# RUN echo 'IOC=$(SUPPORT)/ioc' >> configure/RELEASE && \
#     make release && \
#     make && \
#     make clean
