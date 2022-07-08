# EPICS Dockerfile for adding Asyn and other fundamental support modules
# Also adds the minimal Generic IOC support

##### build stage ##############################################################

ARG TARGET_ARCHITECTURE=linux

FROM  ghcr.io/epics-containers/epics-base-${TARGET_ARCHITECTURE}-developer:dev AS developer

ARG TARGET_ARCHITECTURE
ENV TARGET_ARCHITECTURE=${TARGET_ARCHITECTURE}

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    locales \
    libc-dev-bin \
    libusb-1.0-0-dev \
    libpython3-stdlib \
    python3-minimal \
    python3-dev \
    python3-pip \
    re2c \
    wget \
    && rm -rf /var/lib/apt/lists/*

COPY ./support/. ${SUPPORT}/
RUN pip install --prefix=${PYTHON_PKG} -r ${SUPPORT}/requirements.txt

WORKDIR ${SUPPORT}

# add the generic IOC source code
COPY ioc ${IOC}

# get standard support modules
RUN bash scripts/get_source.sh

# compile the support modules and the IOC
RUN make && \
    make clean


##### runtime preparation stage ################################################

FROM developer as runtime_prep

RUN bash ${EPICS_ROOT}/minimize.sh ${SUPPORT} /MIN_SUPPORT

##### runtime stage ############################################################

FROM ghcr.io/epics-containers/epics-base-${TARGET_ARCHITECTURE}-runtime:dev AS runtime

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    busybox-static \
    libusb-1.0-0 \
    libpython3-stdlib \
    python3-minimal \
    && rm -rf /var/lib/apt/lists/*

WORKDIR ${EPICS_ROOT}

# get the products from the build stage
COPY --from=developer ${PYTHON_PKG} ${PYTHON_PKG}
COPY --from=runtime_prep /MIN_SUPPORT ${SUPPORT}
COPY --from=developer ${IOC} ${IOC}
