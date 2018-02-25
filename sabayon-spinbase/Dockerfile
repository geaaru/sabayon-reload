ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/sabayon-base-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff

# Add latest portage
ADD ./portage-latest.tar.xz /usr

ARG SABAYON_SKIP_SYNC=0
ENV SABAYON_SKIP_SYNC=${SABAYON_SKIP_SYNC}

ARG CACHEBUST=1
RUN chmod a+x /sabayon-stuff/sabayon_spinbase.sh && \
      /sabayon-stuff/sabayon_spinbase.sh init && \
      /sabayon-stuff/sabayon_spinbase.sh phase1 && \
      rm -rf /sabayon-stuff /usr/portage/

# Define default command.
CMD ["bash"]
