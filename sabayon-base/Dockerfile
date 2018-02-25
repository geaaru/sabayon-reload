ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/stage3-sabayon-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

ARG SABAYON_ARCH=amd64
ENV SABAYON_ARCH ${SABAYON_ARCH}

# Set profile
ARG GENTOO_PROFILE_NAME=/systemd
ENV GENTOO_PROFILE_NAME ${GENTOO_PROFILE_NAME}

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
# Add latest portage
ADD ./portage-latest.tar.xz /usr

ARG CACHEBUST=1
RUN chmod a+x /sabayon-stuff/sabayon_base.sh && \
      /sabayon-stuff/sabayon_base.sh init && \
      /sabayon-stuff/sabayon_base.sh phase1 && \
      /sabayon-stuff/sabayon_base.sh phase2 && \
      rm -rf /sabayon-stuff /usr/portage/

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["/bin/bash"]
