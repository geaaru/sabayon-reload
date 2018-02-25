ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/stage3-sabayon-reload-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# Add repos
# TODO: check if there is an alternative for mount
#       external directory on build process.
ADD ./repos /repos

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff

ARG SABAYON_REPOS_NAME=sabayon-reload
ENV SABAYON_REPOS_NAME ${SABAYON_REPOS_NAME}

ARG SABAYON_REPOS_DESC="Sabayon Reload Repository"
ENV SABAYON_REPOS_DESC ${SABAYON_REPOS_DESC}

ARG SABAYON_REPOS_PATH=/repos/
ENV SABAYON_REPOS_PATH ${SABAYON_REPOS_PATH}

ARG SABAYON_REPOS_PROTO=file
ENV SABAYON_REPOS_PROTO ${SABAYON_REPOS_PROTO}

ARG CACHEBUST=1
RUN chmod a+x /sabayon-stuff/sabayon_base.sh && \
      /sabayon-stuff/sabayon_base.sh init && \
      /sabayon-stuff/sabayon_base.sh phase1 && \
      /sabayon-stuff/sabayon_base.sh phase2 && \
      /sabayon-stuff/sabayon_base.sh clean && \
      rm -rf /repos/

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["/bin/bash"]
