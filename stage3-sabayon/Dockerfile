ARG USER=geaaru

# Set arch
ARG TARGET_ARCH=amd64

# Set GENTOO_SKIP_SYNC VARIABLE
ARG GENTOO_SKIP_SYNC=0

FROM ${USER}/stage3-gentoo-systemd-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# See bug: https://github.com/moby/moby/issues/34494
# 
#ONBUILD ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}
ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}

# Variables already set from gentoo stage3
#ENV LC_ALL=en_US.UTF-8
#ENV TERM=linux
#ENV SABAYON_ARCH=amd64

ARG SABAYON_PROFILE_TARGETS=/systemd
ENV SABAYON_PROFILE_TARGETS ${SABAYON_PROFILE_TARGETS}

ARG SABAYON_REBUILD=0
ENV SABAYON_REBUILD ${SABAYON_REBUILD}


# Set profile
ARG GENTOO_PROFILE_NAME=/systemd
#ONBUILD ENV GENTOO_PROFILE_NAME ${GENTOO_PROFILE_NAME}
ENV GENTOO_PROFILE_NAME ${GENTOO_PROFILE_NAME}

ARG CACHEBUST=1

# Add latest portage (from trigger)
#ADD ./portage-latest.tar.xz /usr

# * Prepare env for equo emerge and equo rescue (init)
# * Install equo and execute equo rescue (phase1)
# * Prepare portage environment for compilation (phase2)
# * Clean compilation stuff
RUN chmod a+x /sabayon-stuff/sabayon_stage3.sh && \
      /sabayon-stuff/sabayon_stage3.sh init && \
      /sabayon-stuff/sabayon_stage3.sh phase1 && \
      /sabayon-stuff/sabayon_stage3.sh phase2 && \
      /sabayon-stuff/sabayon_stage3.sh clean

# Define default command.
CMD ["/bin/bash"]

