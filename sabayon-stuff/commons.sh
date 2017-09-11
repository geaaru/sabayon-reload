#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

MAKE_PORTAGE_FILE=/etc/portage/make.conf
REPOS_CONF_DIR=/etc/portage/repos.conf/
GENTOO_PROFILE_VERSION="13.0"
PORTDIR=/usr/portage
PORTAGE_LATEST_PATH=/portage-latest.tar.xz

sabayon_set_locate () {

  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen || return 1

  locale-gen

  return 0
}

sabayon_set_makeopts () {

  local jobs=${1:-7}

  echo "MAKEOPTS=-j${jobs}" >> ${MAKE_PORTAGE_FILE}

  return $?
}

sabayon_set_python_targets () {

  local targets=${1:-python2_7}

  echo "PYTHON_TARGETS=\"${targets}\"" >> ${MAKE_PORTAGE_FILE}

  return $?
}

sabayon_set_python_single_target () {

  local target=${1:-python2_7}

  echo "PYTHON_SINGLE_TARGETS=\"${targets}\"" >> ${MAKE_PORTAGE_FILE}

  return $?
}

sabayon_create_reposfile () {

  local url=${1:-rsync://rsync.europe.gentoo.org/gentoo-portage}
  local f=${2:-gentoo.conf}

  mkdir -p ${REPOS_CONF_DIR} || return 1

  echo "
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /usr/portage
sync-type = rsync
sync-uri = ${url}
" > ${REPOS_CONF_DIR}${f}

  return $?
}

sabayon_set_profile () {

  local profile=${1:-default/linux/amd64/${GENTOO_PROFILE_VERSION}/systemd}

  eselect profile set ${profile}

  return $?
}

sabayon_set_pyver () {

  local v=${1:-python2.7}

  eselect python set ${v}

  return $?
}

sabayon_init_portage () {

  local skip_sync=${GENTOO_SKIP_SYNC:-0}

  if [ ${skip_sync} -eq 0 ] ; then
    emerge --sync || return 1
  fi

  sabayon_set_profile || return 1

  sabayon_set_pyver || return 1

  return 0
}
