ARG USER=geaaru
# Set arch
ARG TARGET_ARCH=amd64
FROM ${USER}/sabayon-base-${TARGET_ARCH}

MAINTAINER geaaru <geaaru@gmail.com>

# Add sabayon-stuff files
ADD ./sabayon-stuff/ /sabayon-stuff
RUN chmod a+x /sabayon-stuff/sabayon_check_overlay.sh

# Add latest portage
ADD ./portage-latest.tar.xz /usr

ARG CACHEBUST=1
RUN /sabayon-stuff/sabayon_check_overlay.sh build

ENTRYPOINT [ "/sabayon-stuff/sabayon_check_overlay.sh" ]
CMD [ "/bin/bash" ]
