ARG USER=geaaru

# For now I use parent value
# See bug: https://github.com/moby/moby/issues/34494
#ARG GENTOO_PROFILE_NAME=/systemd
#ARG GENTOO_SKIP_SYNC=0
#ARG SABAYON_PROFILE_TARGETS=/systemd
#ARG SABAYON_REBUILD=0

# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/stage3-sabayon-reload-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

#VOLUME ["./repos:/repos"]

# Variables already set from gentoo steg3
#ENV LC_ALL=en_US.UTF-8
#ENV TERM=linux
#ENV SABAYON_ARCH=amd64
#ENV GENTOO_PROFILE_NAME
#ENV SABAYON_PROFILE_TARGETS
#ENV SABAYON_REBUILD
#ENV GENTOO_SKIP_SYNC

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_create_repo.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Add trigger for children images
ONBUILD ADD ./sabayon-stuff/ /sabayon-stuff
ONBUILD ADD ./portage-latest.tar.xz /usr

ARG SABAYON_REPOS_NAME=sabayon-reload
#ONBUILD ENV SABAYON_REPOS_NAME ${SABAYON_REPOS_NAME}
ENV SABAYON_REPOS_NAME ${SABAYON_REPOS_NAME}

ARG SABAYON_REPOS_DESC="Sabayon Reload Repository"
ENV SABAYON_REPOS_DESC ${SABAYON_REPOS_DESC}

ARG SABAYON_REPOS_PATH=/repos/
#ONBUILD ENV SABAYON_REPOS_PATH ${SABAYON_REPOS_PATH}
ENV SABAYON_REPOS_PATH ${SABAYON_REPOS_PATH}

ARG SABAYON_REPOS_PROTO=file
#ONBUILD ENV SABAYON_REPOS_PROTO ${SABAYON_REPOS_PROTO}
ENV SABAYON_REPOS_PROTO ${SABAYON_REPOS_PROTO}

ARG CACHEBUST=1
# * Prepare env for equo emerge and equo rescue
# * Install equo and execute equo rescue
# * Clean compilation stuff
RUN /sabayon-stuff/sabayon_create_repo.sh init && \
      /sabayon-stuff/sabayon_create_repo.sh phase1 && \
      /sabayon-stuff/sabayon_create_repo.sh clean

# Define default command.
ENTRYPOINT ["/sabayon-stuff/sabayon_create_repo.sh", "files"]

