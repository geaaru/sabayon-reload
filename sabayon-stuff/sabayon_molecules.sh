#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

SABAYON_MOLECULES_GITURL=${SABAYON_MOLECULES_GITURL:-https://github.com/Sabayon/molecules.git}
SABAYON_MOLECULES_GIT_OPTS=${SABAYON_MOLECULES_GIT_OPTS:-}
SABAYON_MOLECULES_DIR=${SABAYON_MOLECULES_DIR:-/sabayon}
SABAYON_MOLECULES_CHROOTS=${SABAYON_MOLECULES_CHROOTS:-}
SABAYON_MOLECULES_SOURCES=${SABAYON_MOLECULES_SOURCES:-}
SABAYON_MOLECULES_ISO=${SABAYON_MOLECULES_ISO:-}
SABAYON_MOLECULES_ENVFILE=${SABAYON_MOLECULES_ENVFILE:-$(pwd)/confs/iso_build.env}
SABAYON_MOLECULES_SYSTEMD_MODE=${SABAYON_MOLECULES_SYSTEMD_MODE:-0}
SABAYON_MOLECULES_POSTSCRIPT=${SABAYON_MOLECULES_POSTSCRIPT:-}
SABAYON_MOLECULES_JOURNAL_NLOG=${SABAYON_MOLECULES_JOURNAL_NLOG:-100}
SABAYON_MOLECULES_SYSTEMD_SLEEP=${SABAYON_MOLECULES_SYSTEMD_SLEEP:-5}

sabayon_molecules_info () {

  local args=$@
  local info_args=""

  if [ "${args}"x != ""x ] ; then
    info_args="SABAYON_MOLECULES_RUN_ARGS = ${args}"
  fi

  echo "
SABAYON_MOLECULES_GITURL       = ${SABAYON_MOLECULES_GITURL}
SABAYON_MOLECULES_GIT_OPTS     = ${SABAYON_MOLECULES_GIT_OPTS}
SABAYON_MOLECULES_DIR          = ${SABAYON_MOLECULES_DIR}
SABAYON_MOLECULES_ENVFILE      = ${SABAYON_MOLECULES_ENVFILE}
SABAYON_MOLECULES_SYSTEMD_MODE = ${SABAYON_MOLECULES_SYSTEMD_MODE}
SABAYON_MOLECULES_ISO          = ${SABAYON_MOLECULES_ISO}
SABAYON_MOLECULES_CHROOTS      = ${SABAYON_MOLECULES_CHROOTS}
SABAYON_MOLECULES_SOURCES      = ${SABAYON_MOLECULES_SOURCES}
${info_args}
"
  return 0
}

PACKAGES_TO_ADD=(
  #"sys-fs/squashfs-tools"
  "mail-mta/postfix"
  #"app-cdr/cdrtools"
  "net-p2p/mktorrent-borg"
  "sys-fs/dosfstools"
  "dev-util/molecule"
  "dev-vcs/git"
  "app-misc/ca-certificates"
  "app-emulation/docker"
  "app-emulation/docker-companion"
  "sys-process/tini"
  # For isohybrid
  "sys-boot/syslinux"
)

FILES_TO_REMOVE=(
   "/etc/entropy/packages/license.accept"
   "/etc/make.profile"
)

sabayon_molecules_init () {

  sabayon_molecules_info

  sabayon_config_portage_empty 1 0 1 || return 1

  sabayon_init_env || return 1

  export ETP_NONINTERACTIVE=1

  return 0
}

sabayon_molecules_phase1 () {

  equo i "${PACKAGES_TO_ADD[@]}" || return 1

  echo -5 | equo conf update || return 1

  mkdir /etc/systemd/system/docker.service.d || return 1
  echo "
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock -D

" >> /etc/systemd/system/docker.service.d/00gentoo.conf || return 1

  # Disable systemd-journal-flush. Doesn't start correctly
  systemctl disable systemd-journal-flush.service
  ln -s /dev/null /etc/systemd/system/systemd-journal-flush.service
  # Disable systemd-update-utmp. Doesn't start correctly
  systemctl disable systemd-update-utmp.service
  ln -s /dev/null /etc/systemd/system/systemd-update-utmp.service

  systemctl enable docker || return 1

  return 0
}

sabayon_molecules_clean () {

  # Cleaning equo package cache
  equo cleanup || return 1

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  return 0
}

sabayon_molecules_echo () {
  local msg=$@

  echo "
-------------------------------------------------------------------------------
$@
-------------------------------------------------------------------------------
"
  return 0
}

sabayon_molecules_run () {

  shift
  local opts=$@
  local systemctl=/usr/bin/systemctl
  local journaltcl=/usr/bin/journalctl

  # Load environment variables
  if [ -e "${SABAYON_MOLECULES_ENVFILE}" ] ; then
    echo "Sourcing file ${SABAYON_MOLECULES_ENVFILE}..."
    source ${SABAYON_MOLECULES_ENVFILE}
  fi

  sabayon_molecules_info || return 1

  if [ ${SABAYON_MOLECULES_SYSTEMD_MODE} -eq 1 ] ; then
    sabayon_molecules_echo "Starting SYSTEMD"
    exec /sbin/init --system --show-status=true &

    sabayon_molecules_echo "Waiting for systemd starting...sleep ${SABAYON_MOLECULES_SYSTEMD_SLEEP}"
    sleep ${SABAYON_MOLECULES_SYSTEMD_SLEEP}

    sabayon_molecules_echo "FAILED SYSTEMD SERVICES"
    $systemctl --failed || return 1

    sabayon_molecules_echo "Systemd Services Status"
    $systemctl status || return 1

    sabayon_molecules_echo "JOURNALCTL BOOTSTRAP LOG"
    $journaltcl -b --no-pager -n ${SABAYON_MOLECULES_JOURNALCTL_NLOG}
  fi

  sabayon_molecules_echo \
    "Clone repository ${SABAYON_MOLECULES_GITURL} to ${SABAYON_MOLECULES_DIR}"
  git clone ${SABAYON_MOLECULES_GITURL} ${SABAYON_MOLECULES_GIT_OPTS} \
    ${SABAYON_MOLECULES_DIR} || return 1

  # TODO: Fix this on molecules tree
  mkdir ${SABAYON_MOLECULES_DIR}/iso

  echo "Repository ${SABAYON_MOLECULES_GITURL} installed correctly."

  if [ -n "${SABAYON_MOLECULES_CHROOTS}" ] ; then
    echo "Mount ${SABAYON_MOLECULES_CHROOTS} to ${SABAYON_MOLECULES_DIR}/chroots..."
    mount -o bind ${SABAYON_MOLECULES_CHROOTS} ${SABAYON_MOLECULES_DIR}/chroots || return 1
  fi

  if [ -n "${SABAYON_MOLECULES_SOURCES}" ] ; then
    echo "Mount ${SABAYON_MOLECULES_SOURCES} to ${SABAYON_MOLECULES_DIR}/sources..."
    mount -o bind ${SABAYON_MOLECULES_SOURCES} ${SABAYON_MOLECULES_DIR}/sources || return 1
  fi

  if [ -n "${SABAYON_MOLECULES_ISO}" ] ; then
    echo "Mount ${SABAYON_MOLECULES_ISO} to ${SABAYON_MOLECULES_DIR}/iso..."
    mount -o bind ${SABAYON_MOLECULES_ISO} ${SABAYON_MOLECULES_DIR}/iso || return 1
  fi

# NOTE: loop is needed for mount image
#docker run --init --device /dev/fuse --cap-add=MKNOD   --tmpfs /run --tmpfs /tmp -v /sdpool/molecules-chroots:/chroots -v /sdpool/molecules-sources:/sources -v /sdpool/iso:/iso  -v $(pwd)/sabayon_molecules.sh:/sabayon-stuff/sabayon_molecules.sh -v /sys/fs/cgroup:/sys/fs/cgroup:ro   --rm   --name test2 --cap-add=SYS_PTRACE --cap-add=SYS_ADMIN --cap-add=NET_ADMIN  --device=/dev/loop-control:/dev/loop-control --device=/dev/loop0:/dev/loop0 -e COLUMNS=200 -e LINES=400 -e SABAYON_MOLECULES_CHROOTS=/chroots -e SABAYON_MOLECULES_SOURCES=/sources -e SABAYON_MOLECULES_ISO=/iso  geaaru/sabayon-molecules-amd64

  local date_end=""
  local date_start=$(date +%s)
  sabayon_molecules_echo "START iso_build.sh script."
  ${SABAYON_MOLECULES_DIR}/scripts/iso_build.sh $@ || return 1
  date_end=$(date +%s)
  sabayon_molecules_echo \
    "END iso_build.sh script. Build process time: $((${date_end} - ${date_start})) secs."

  if [ -e "${SABAYON_MOLECULES_POSTSCRIPT}" ] ; then
    echo "Sourcing POST script file ${SABAYON_MOLECULES_POSTSCRIPT}..."
    source ${SABAYON_MOLECULES_POSTSCRIPT}
  fi

  return 0
}

case $1 in
  init)
    sabayon_molecules_init
    ;;
  phase1)
    sabayon_molecules_phase1
    ;;
  run)
    sabayon_molecules_run $@
    ;;
  clean)
    sabayon_molecules_clean
    ;;
  *)
    echo "Use init|phase1|clean"
    exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
