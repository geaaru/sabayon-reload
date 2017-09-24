ARG USER=geaaru
FROM ${USER}/stage3-sabayon-amd64

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_base.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

RUN /sabayon-stuff/sabayon_base.sh init

ARG CACHEBUST=1
RUN /sabayon-stuff/sabayon_base.sh phase1

RUN /sabayon-stuff/sabayon_base.sh phase2

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
