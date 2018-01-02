ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/stage3-sabayon-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

RUN chmod a+x /sabayon-stuff/sabayon_base.sh

RUN /sabayon-stuff/sabayon_base.sh init

ARG CACHEBUST=1
RUN /sabayon-stuff/sabayon_base.sh phase1

RUN /sabayon-stuff/sabayon_base.sh phase2

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

RUN /sabayon-stuff/sabayon_base.sh clean
RUN rm -rf /sabayon-stuff /usr/portage/

# Define default command.
CMD ["/bin/bash"]
