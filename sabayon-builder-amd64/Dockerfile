ARG USER=geaaru
FROM ${USER}/sabayon-spinbase-amd64

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_builder.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Set GENTOO_SKIP_SYNC VARIABLE
ARG GENTOO_SKIP_SYNC=0
ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}

ARG CACHEBUST=1

# Prepare env for equo emerge and equo rescue
ARG SABAYON_SKIP_SYNC=0
ENV SABAYON_SKIP_SYNC=${SABAYON_SKIP_SYNC}

RUN /sabayon-stuff/sabayon_builder.sh init

RUN /sabayon-stuff/sabayon_builder.sh phase1

# Define standard volumes
VOLUME ["/usr/portage", "/usr/portage/distfiles", "/usr/portage/packages", "/var/lib/entropy/client/packages"]

RUN rm -rf /sabayon-stuff

# Define default command.
ENTRYPOINT ["/usr/sbin/builder"]

