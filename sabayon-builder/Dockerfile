ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/sabayon-spinbase-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Set GENTOO_SKIP_SYNC VARIABLE
ARG GENTOO_SKIP_SYNC=0
ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}

# Prepare env for equo emerge and equo rescue
ARG SABAYON_SKIP_SYNC=0
ENV SABAYON_SKIP_SYNC=${SABAYON_SKIP_SYNC}

ARG CACHEBUST=1
RUN chmod a+x /sabayon-stuff/sabayon_builder.sh && \
      /sabayon-stuff/sabayon_builder.sh init && \
      /sabayon-stuff/sabayon_builder.sh phase1 && \
      rm -rf /sabayon-stuff

# Define standard volumes
VOLUME ["/usr/portage", \
        "/usr/portage/distfiles", \
        "/usr/portage/packages", \
        "/var/lib/entropy/client/packages"]

# Define default command.
ENTRYPOINT ["/usr/sbin/builder"]

