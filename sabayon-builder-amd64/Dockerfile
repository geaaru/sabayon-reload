ARG USER=geaaru
FROM ${USER}/sabayon-spinbase-amd64

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_builder.sh

ARG SABAYON_SKIP_SYNC=0
ENV SABAYON_SKIP_SYNC=${SABAYON_SKIP_SYNC}

RUN /sabayon-stuff/sabayon_builder.sh init

#RUN rm -rf /sabayon-stuff /usr/portage/

# Define default command.
CMD ["bash"]
