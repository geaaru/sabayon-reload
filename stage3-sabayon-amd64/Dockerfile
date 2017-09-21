ARG USER=geaaru
FROM ${USER}/stage3-gentoo-systemd-amd64

MAINTAINER geaaru <geaaru@gmail.com>

# Variables already set from gentoo steg3
#ENV LC_ALL=en_US.UTF-8
#ENV TERM=linux

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_stage3.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Set GENTOO_SKIP_SYNC VARIABLE
ARG GENTOO_SKIP_SYNC=0
ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}

ARG CACHEBUST=1
# Prepare env for equo emerge and equo rescue
RUN /sabayon-stuff/sabayon_stage3.sh init

# Install equo and execute equo rescue
RUN /sabayon-stuff/sabayon_stage3.sh phase1

# Prepare portage environment for compilation
RUN /sabayon-stuff/sabayon_stage3.sh phase2

RUN rm -rf /sabayon-stuff /usr/portage/

# Define default command.
CMD ["bash"]

