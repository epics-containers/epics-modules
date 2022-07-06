# EPICS Dockerfile for Asyn and other fundamental support modules
# This image also adds the minimal Generic IOC support

##### build stage ##############################################################
ARG TARGET_ARCHITECTURE=linux

FROM  ghcr.io/epics-containers/epics-base-${TARGET_ARCHITECTURE}-developer:0.5.0 AS developer

ARG TARGET_ARCHITECTURE
ENV TARGET_ARCHITECTURE=${TARGET_ARCHITECTURE}
ENV PYTHON_PKG ${EPICS_ROOT}/python
# [TODO restore below for ubuntu 22.04]
# ENV PYTHONPATH=${PYTHON_PKG}/local/lib/python3.10/dist-packages/ 
# ENV PATH="${PYTHON_PKG}/local/bin:${PATH}"
ENV PYTHONPATH=${PYTHON_PKG}/lib/python3.8/site-packages/
ENV PATH="${PYTHON_PKG}/bin:${PATH}"
ENV SUPPORT ${EPICS_ROOT}/support
ENV IOC ${EPICS_ROOT}/ioc

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


# import support folder root files
COPY ./support/. ${SUPPORT}/
RUN pip install --prefix=${PYTHON_PKG} -r ${SUPPORT}/requirements.txt

WORKDIR ${SUPPORT}

# add the generic IOC source code
COPY ioc ${IOC}

# get standard support modules
RUN ./get_source.sh

# compile the support modules and the IOC
RUN make && \
    make -j clean

##### runtime stage ############################################################

FROM ghcr.io/epics-containers/epics-base-${TARGET_ARCHITECTURE}-runtime:0.5.0 AS runtime


RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    busybox-static \
    libusb-1.0-0 \
    libpython3-stdlib \
    python3-minimal \
    && rm -rf /var/lib/apt/lists/*


# get the products from the build stage
COPY --from=developer ${PYTHON_PKG} ${PYTHON_PKG}
COPY --from=developer ${SUPPORT} ${SUPPORT}
COPY --from=developer ${IOC} ${IOC}
