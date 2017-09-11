#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

PACKAGES2CLEAN=(
  editor
  ssh
  man
  man-pages
  openrc
  e2fsprogs
  service-manager
)

sabayon_stage3_init () {

  sabayon_set_locate || return 1

  sabayon_set_makeopts || return 1

  sabayon_set_python_targets || return 1

  sabayon_set_python_single_target || return 1

  mkdir -p ${PORTDIR} || return 1

  sabayon_create_reposfile || return 1

  return 0
}

sabayon_stage3_rebuildall () {

  local emerge_opts="-j --newuse --deep --with-bdeps=y"

  sabayon_init_portage || return 1

  # Error: The above package list contains packages which cannot be
  #  * installed at the same time on the same system.
  #  (sys-fs/eudev-3.1.5:0/0::gentoo, installed) pulled in by
  #    >=sys-fs/eudev-2.1.1 required by (virtual/udev-217:0/0::gentoo, installed)
  #
  #  (sys-apps/systemd-233-r4:0/2::gentoo, ebuild scheduled for merge) pulled in by
  #    >=sys-apps/systemd-207 required by (sys-apps/gentoo-systemd-integration-7:0/0::gentoo, ebuild scheduled for merge)
  #    >=sys-apps/systemd-209 required by (sys-process/procps-3.3.12:0/5::gentoo, ebuild scheduled for merge
  #    sys-apps/systemd required by (virtual/tmpfiles-0:0/0::gentoo, installed)
  #    >=sys-apps/systemd-212-r5:0/2[abi_x86_32(-)?,abi_x86_64(-)?,abi_x86_x32(-)?,abi_mips_n32(-)?,abi_mips_n64(-)?,abi_mips_o32(-)?,abi_ppc_32(-)?,abi_ppc_64(-)?,abi_s390_32(-)?,abi_s390_64(-)?] (>=sys-apps/systemd-212-r5:0/2[abi_x86_64(-)]) required by (virtual/libudev-232:0/1::gentoo, ebuild scheduled for merge)
  #    sys-apps/systemd:0= required by (sys-apps/dbus-1.10.18:0/0::gentoo, ebuild scheduled for merge)
  #    sys-apps/systemd required by (sys-apps/util-linux-2.28.2:0/0::gentoo, ebuild scheduled for merge)
  #
  echo "Unmerge eudev not compliant with systemd (default package on latest Gentoo image)"
  emerge -C eudev virtual/udev || return 1

  echo "Emerge @systemd && @world"

  emerge ${emerge_opts} @system @world || return 1

  echo "Cleaning packages:\n${PACKAGES2CLEAN}"
  emerge -C ${PACKAGES2CLEAN} || return 1

  echo "Installing layman package.."
  emerge -j layman || return 1

  echo "Depclean..."
  emerge --depclean

  echo "Removing packages directory..."
  rm -rf ${PORTDIR}/packages
  rm -rf ${PORTDIR}/distfiles/*

  return 0

}

case $1 in
  init)
    sabayon_stage3_init
    ;;
  rebuild)
    sabayon_stage3_rebuildall
    ;;
  *)
  echo "Use init|rebuild"
  exit 1
esac

exit $?
