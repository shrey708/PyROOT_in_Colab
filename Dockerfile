# https://mybinder.readthedocs.io/en/latest/tutorials/dockerfile.html

ARG BASE_CONTAINER=ubuntu:focal-20210921

FROM $BASE_CONTAINER

LABEL maintainer="Kohei ISHIZAKI <ishizaki_at_phi.phys.nagoya-u_dot_ac_dot_jp>"


#########################################################
#########################################################

ARG NB_USER=phi
ARG cern_root_version="v6-24-06"

#########################################################
#########################################################

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash

RUN apt update && \
    apt install -y --install-recommends \
    curl \
    git \
    sudo \
    wget; \
    apt install -yq --no-install-recommends \
    cmake \
    ca-certificates \
    emacs \
    locales \
    fonts-liberation \
    run-one \
    build-essential \
    python3-dev \
    vim-tiny \
    inkscape \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    nodejs \
    tzdata \
    unzip \
    nano-tiny \
    python3-pip \
    llvm \
    llvm-12-dev; \
    ## Install ROOT prerequisite
    apt install -yq --no-install-recommends \
    dpkg-dev \
    binutils \
    libx11-dev \
    libxpm-dev \
    libxft-dev \
    libxext-dev \
    libssl-dev \
    gfortran \
    libpcre3-dev \
    xlibmesa-glu-dev \
    libglew1.5-dev \
    libftgl-dev \
    libmysqlclient-dev \
    libfftw3-dev \
    libcfitsio-dev \
    graphviz-dev \
    libavahi-compat-libdnssd-dev \
    libldap2-dev \
    libxml2-dev \
    libkrb5-dev \
    libhdf5-dev \
    libgsl0-dev; \
    apt clean; \
    rm -rf /var/lib/apt/lists/*;

ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

###
###  Install Python packages
###

USER ${NB_USER}
COPY requirements.txt /tmp/
RUN pip3 install --user -I pip; \
    pip3 install --user -r /tmp/requirements.txt; \
    rm /tmp/requirements.txt; \
    jupyter server extension enable --user --py jupyterlab_git; \
    jupyter lab build; \
    python3 -m bash_kernel.install;

###
### Install ROOT
###
USER root
ARG root_prefix="/opt/root"
RUN cd /tmp && mkdir .root && cd .root; \
    git clone --progress https://github.com/root-project/root.git -b ${cern_root_version} --depth 1; \
    cd /tmp/.root; \
    mkdir root_build ${root_prefix} && cd root_build; \
    cmake \ 
        -Dimt=OFF \
        -Dbuiltin_tbb=OFF \
        -Dmathmore=OFF \ 
        -DCMAKE_INSTALL_PREFIX=${root_prefix} \ 
        ../root; \
    cmake --build . -- install; \
    echo "source ${root_prefix}/bin/thisroot.sh" >> ~/.bashrc; \
    rm -rd /tmp/.root;

ENV ROOTSYS=/opt/root \
    PATH=$ROOTSYS/bin:$PATH \
    PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH \
    CLING_STANDARD_PCH=none
RUN cp -r /opt/root/etc/notebook/kernels/root /usr/local/share/jupyter/kernels; \
    jupyter notebook --generate-config; \
    echo /opt/root/lib >> /etc/ld.so.conf; \
    ldconfig;

# Make sure the contents of our repo are in ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME};

USER ${NB_USER}
WORKDIR ${HOME}
#COPY ./binder/CPP_sample.ipynb ${HOME}
#COPY ./binder/PyROOT_sample.ipynb ${HOME}
COPY ./README.md ${HOME}
COPY ./LICENSE ${HOME}
ENV ROOTSYS=/opt/root \
    PATH=$ROOTSYS/bin:$PATH \
    PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH \
    CLING_STANDARD_PCH=none