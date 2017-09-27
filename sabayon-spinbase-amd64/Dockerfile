ARG USER=geaaru
FROM ${USER}/sabayon-base-amd64

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_spinbase.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

ARG SABAYON_SKIP_SYNC=0
ENV SABAYON_SKIP_SYNC=${SABAYON_SKIP_SYNC}

RUN /sabayon-stuff/sabayon_spinbase.sh init

ARG CACHEBUST=1
RUN /sabayon-stuff/sabayon_spinbase.sh phase1

#RUN rm -rf /sabayon-stuff /usr/portage/

# Define default command.
CMD ["bash"]
