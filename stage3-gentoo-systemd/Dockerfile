FROM scratch

MAINTAINER geaaru <geaaru@gmail.com>

ARG TARBALL=local
ENV TARBALL ${TARBALL}
ADD ${TARBALL} /

# Add sabayon-stuff files
# Note: Currently is not possible
#       add directory that is present outside
#       of current directory context.
#       So copy directory from external of Dockerfile
#       inside build directory.
#       TODO: Try with build from parent.
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/stage3.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

# Set locales to en_US.UTF-8
ENV LC_ALL=en_US.utf8

ENV TERM=linux

RUN /sabayon-stuff/stage3.sh init
# Add trigger for children images
ONBUILD ADD ./sabayon-stuff/ /sabayon-stuff
ONBUILD ADD ./portage-latest.tar.xz /usr

# Set GENTOO_SKIP_SYNC VARIABLE
# See bug: https://github.com/moby/moby/issues/34494
# For now use default value from commons.sh
#ARG GENTOO_SKIP_SYNC=0
#ONBUILD ENV GENTOO_SKIP_SYNC ${GENTOO_SKIP_SYNC}

# Set profile
#ARG GENTOO_PROFILE_NAME=/systemd
#ONBUILD ENV GENTOO_PROFILE_NAME ${GENTOO_PROFILE_NAME}

# Set arch
ARG SABAYON_ARCH=amd64
ENV SABAYON_ARCH ${SABAYON_ARCH}

ARG CACHEBUST=1
RUN /sabayon-stuff/stage3.sh rebuild

RUN rm -rf /sabayon-stuff /usr/portage/

CMD ["/bin/bash"]
