#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

MAKE_PORTAGE_FILE=/etc/portage/make.conf
REPOS_CONF_DIR=/etc/portage/repos.conf/
GENTOO_PROFILE_VERSION="13.0"
PORTDIR=/usr/portage
PORTAGE_LATEST_PATH=/portage-latest.tar.xz

sabayon_set_default_shell () {
  local shell=${1:-/bin/bash}

  chsh -s ${shell} || return 1

  return 0
}

sabayon_set_resolvconf () {
  local dns="${1:-8.8.8.8}"

  echo "nameserver ${dns}" > /etc/resolv.conf

  return 0
}

sabayon_gcc_config_fixbug () {
  # Sad to face this issue still after 1.5yr,
  # see https://bugs.gentoo.org/show_bug.cgi?id=504118
  ln -s /lib64/gentoo/functions.sh /etc/init.d/functions.sh || return 1

  return 0
}

sabayon_gcc_config_unfixbug () {
  rm -f /etc/init.d/functions.sh || return 1
  return 0
}

sabayon_check_etc_portage () {

  if [[ ! -d /etc/portage/package.keywords ]] ; then
    mkdir -p /etc/portage/package.keywords
  fi

  if [[ ! -d /etc/portage/package.use ]] ; then
    mkdir -p /etc/portage/package.use
  fi

  return 0
}

sabayon_set_locale_conf () {

  local lang="${1:-en_US.UTF-8}"

  for f in /etc/env.d/02locale /etc/locale.conf; do
      echo "LANG=${lang}" > "${f}"
      echo "LANGUAGE=${lang}" >> "${f}"
      echo "LC_ALL=${lang}" >> "${f}"
  done

  return 0
}

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

sabayon_install_overlay () {

  local name=$1
  local unofficial=${2:-0}

  # Fetch list
  layman -f || return 1

  echo "Installing overlay ${name}..."

  # Install overlay
  if [ $unofficial -eq 0 ] ; then
    layman -a ${name} || return 1
  else
    echo 'y' | layman -a ${name} ||  return 1
  fi

  return 0
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

sabayon_configure_portage () {

  local init_etc=${1:-0}
  local reposdir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"

  [ -z "${SABAYON_PORTAGE_CONF_REPOS}" ] && return 1
  [ -z "${SABAYON_ARCH}" ] && return 1
  [ -z "${SABAYON_PORTAGE_CONF_INSTALLDIR}" ] && return 1
  [ -z "${SABAYON_PORTAGE_CONF_INSTALLNAME}" ] && return 1

  cd "${SABAYON_PORTAGE_CONF_INSTALLDIR}" || return 1

  git clone ${SABAYON_PORTAGE_CONF_REPOS} ${SABAYON_PORTAGE_CONF_INSTALLNAME}

  # Configure repos
  git config --global user.name "root" || return 1
  git config --global user.email "root@localhost" || return 1

  # TODO: check if correct maintains intel configuration

  if [ ${init_etc} -eq 1 ] ; then
    cd /etc
    mv portage portage-gentoo || return 1
    ln -s ${reposdir}/conf/intel/portage portage || return 1

  fi

  return 0
}

sabayon_config_portage_licenses () {

   # Maintains only licenses directory
   #   ! -name '*profiles' \
   # Metadata is needed to avoid this warning:
   #!!! Repository 'x-portage' is missing masters attribute in '/usr/portage/metadata/layout.conf'
   #!!! Set 'masters = gentoo' in this file for future compatibility

   local rmdirs=$(find ${PORTDIR} -maxdepth 1 -type d \
      ! -name '*metadata' \
      ! -path ${PORTDIR} ! -name '*licenses')

   for i in ${rmdirs} ; do
      echo "Removing dir ${i} ..."
      rm -rf ${i}
   done

   # Accept all licenses
   ls ${PORTDIR}/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept || return 1

   return 0
}

sabayon_config_default_repos () {

   mv /etc/entropy/repositories.conf.d/entropy_sabayonlinux.org.example \
      /etc/entropy/repositories.conf.d/entropy_sabayonlinux.org || return 1

   return 0
}

sabayon_save_pkgs_install_list () {
   # Writing package list file
   equo q list installed -qv > /etc/sabayon-pkglist || return 1

   return 0
}

# vim: ts=3 sw=3 expandtab
