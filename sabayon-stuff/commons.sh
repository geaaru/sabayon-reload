#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

MAKE_PORTAGE_FILE=${MAKE_PORTAGE_FILE:-/etc/portage/make.conf}
REPOS_CONF_DIR=${REPOS_CONF_DIR:-/etc/portage/repos.conf/}
GENTOO_PROFILE_VERSION="${GENTOO_PROFILE_VERSION:-13.0}"
PORTDIR=${PORTDIR:-/usr/portage}
PORTAGE_LATEST_PATH=${PORTAGE_LATEST_PATH:-/portage-latest.tar.xz}

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

sabayon_set_all_locales () {

  # Configure glibc locale, ship image with all locales enabled
  # or anaconda will crash if the user selects an unsupported one
  echo '
# /etc/locale.gen: list all of the locales you want to have on your system
#
# The format of each line:
# <locale> <charmap>
#
# Where <locale> is a locale located in /usr/share/i18n/locales/ and
# where <charmap> is a charmap located in /usr/share/i18n/charmaps/.
#
# All blank lines and lines starting with # are ignored.
#
# For the default list of supported combinations, see the file:
# /usr/share/i18n/SUPPORTED
#
# Whenever glibc is emerged, the locales listed here will be automatically
# rebuilt for you.  After updating this file, you can simply run `locale-gen`
# yourself instead of re-emerging glibc.
' > /etc/locale.gen
  cat /usr/share/i18n/SUPPORTED >> /etc/locale.gen || return 1

  /usr/sbin/locale-gen || return 1

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

sabayon_upgrade_kernel () {

  local paren_slink=""
  local paren_children=""
  local kernel_target_pkg="${1:-sys-kernel/linux-sabayon}"
  local available_kernel=$(equo match "${kernel_target_pkg}" -q --showslot)

  echo -en "\n@@ Upgrading kernel to ${available_kernel}\n\n"

  kernel-switcher switch "${available_kernel}" || return 1

  # now delete stale files in /lib/modules
  for slink in $(find /lib/modules/ -type l); do
    if [ ! -e "${slink}" ]; then
      echo "Removing broken symlink: ${slink}"
      rm "${slink}" # ignore failure, best effort
      # check if parent dir is empty, in case, remove
      paren_slink=$(dirname "${slink}")
      paren_children=$(find "${paren_slink}")
      if [ -z "${paren_children}" ]; then
        echo "${paren_slink} is empty, removing"
        rmdir "${paren_slink}" # ignore failure, best effort
      fi
    fi
  done

  return 0
}

sabayon_create_dracut_initramfs () {

  local kernel_target_pkg="${1:-sys-kernel/linux-sabayon}"

  # Dracut initramfs generation for livecd
  # If you are reading this ..beware! this step should be re-done by Installer
  # post-install, without the options needed to boot from live!
  # (see kernel eclass for reference)

  #Update it! we may have upgraded
  local current_kernel=$(equo match --installed "${kernel_target_pkg}" -q --showslot)

  if equo s --verbose --installed $current_kernel | grep -q " dracut"; then

    #ACCEPT_LICENSE=* equo upgrade # upgrading all. this ensures that minor kernel upgrades don't breaks dracut initramfs generation
    # Getting Package name and slot from current kernel (e.g. current_kernel=sys-kernel/linux-sabayon:4.7 -> K_SABKERNEL_NAME = linux-sabayon-4.7 )
    local PN=${current_kernel##*/}
    local K_SABKERNEL_NAME="${K_SABKERNEL_NAME:-${PN/${PN/-/}-}}"
    local K_SABKERNEL_NAME="${K_SABKERNEL_NAME/:/-}"

    # Grab kernel version from RELEASE_LEVEL
    local kver=$(cat /etc/kernels/$K_SABKERNEL_NAME*/RELEASE_LEVEL)
    local karch=$(uname -m)
    echo "Generating dracut for kernel $kver arch $karch"
    dracut -N -a dmsquash-live -a pollcdrom \
      -o systemd -o systemd-initrd \
      -o systemd-networkd \
      -o dracut-systemd --force --kver=${kver} \
      /boot/initramfs-genkernel-${karch}-${kver} || return 1

  else

    echo "Skip generation of initramfs with dracut."

  fi

  return 0
}

# vim: ts=2 sw=2 expandtab
