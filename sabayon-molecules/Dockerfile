ARG USER=geaaru

# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/sabayon-base-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Set locales to en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ARG SABAYON_MOLECULES_DIR=/sabayon
ENV SABAYON_MOLECULES_DIR=${SABAYON_MOLECULES_DIR}
ARG SABAYON_MOLECULES_GITURL=https://github.com/Sabayon/molecules.git
ENV SABAYON_MOLECULES_GITURL=${SABAYON_MOLECULES_GITURL}
ARG SABAYON_MOLECULES_GIT_OPTS=
ENV SABAYON_MOLECULES_GIT_OPTS=${SABAYON_MOLECULES_GIT_OPTS}

ARG CACHEBUST=1
RUN chmod a+x /sabayon-stuff/sabayon_molecules.sh && \
      /sabayon-stuff/sabayon_molecules.sh init && \
      /sabayon-stuff/sabayon_molecules.sh phase1 && \
      /sabayon-stuff/sabayon_molecules.sh clean

# Set environment variables.
ENV HOME ${SABAYON_MOLECULES_DIR}

# Define working directory.
WORKDIR ${SABAYON_MOLECULES_DIR}

# Docker service requirement
VOLUME ["/sys/fs/cgroup"]

# Define default command.
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/sabayon-stuff/sabayon_molecules.sh", "run"]


