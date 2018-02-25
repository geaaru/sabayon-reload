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

  if [ "${SABAYON_ARCH}" == "arm" ] ; then
    sabayon_set_makeopts 2 || return 1
  else
    sabayon_set_makeopts || return 1
  fi

  # For compile dev-util/meson required by systemd
  # is needed python3_5
  sabayon_set_python_targets "python2_7 python3_5" || return 1

  sabayon_set_python_single_target || return 1

  mkdir -p ${PORTDIR} || return 1

  sabayon_create_reposfile || return 1

  sabayon_set_best_mirrors || return 1

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
  # sysv-utils needed for set /sbin/init as systemd daemon
  USE="sysv-utils" emerge ${emerge_opts} @system @world || return 1

  echo "Cleaning packages:\n${PACKAGES2CLEAN}"
  emerge -C ${PACKAGES2CLEAN} || return 1

  echo "Installing layman package.."
  # The following USE changes are necessary to proceed:
  # (see "package.use" in the portage(5) man page for more details)
  # required by dev-python/cryptography-2.0.2::gentoo
  # required by dev-python/urllib3-1.22::gentoo
  # required by dev-python/requests-2.18.2-r1::gentoo
  # required by dev-python/ssl-fetch-0.4::gentoo
  # required by app-portage/layman-2.4.2::gentoo
  # required by layman (argument)
  # >=dev-libs/openssl-1.0.2l -bindist
  # For this is needed force rebuild of openssh!
  # TODO: if set useflag in package.use directory
  USE="-bindist" emerge -j --quiet-build layman openssh --autounmask-keep-masks || return 1

  echo "Depclean..."
  emerge --depclean

  # Set locale for testing phase
  sabayon_set_locale_conf || return 1

  echo "Removing packages directory..."
  rm -rf ${PORTDIR}/packages
  rm -rf ${PORTDIR}/distfiles/*

  return 0

}

# Temporary separation for arm because
# currently stage3 is old and on arm
# is not present systemd profile
sabayon_stage3_arm_rebuildall () {

  local i=0
  local emerge_opts="-j1 --quiet-build --newuse --deep --with-bdeps=y"
  local ufile="/etc/portage/package.use/00-gentoo-arm-stage3.package.use"
  local packages_use=(
    "sys-apps/util-linux -systemd -build -udev"
  )

  sabayon_init_portage || return 1

  echo "Unmerge eudev not compliant with systemd (default package on latest Gentoo image)"
  emerge -C eudev virtual/udev sys-apps/openrc \
    virtual/perl-ExtUtils-ParseXS dev-perl/XML-Parser \
    virtual/perl-CPAN-Meta \
    perl-core/File-Temp virtual/perl-CPAN-Meta-YAML \
    virtual/perl-ExtUtils-Install \
    virtual/perl-File-Temp virtual/perl-Test-Harness \
    virtual/perl-Getopt-Long virtual/perl-Text-ParseWords \
    virtual/perl-ExtUtils-Manifest virtual/perl-ExtUtils-CBuilder \
    sys-apps/texinfo virtual/perl-Module-Metadata \
    virtual/perl-Parse-CPAN-Meta virtual/perl-Perl-OSType \
    dev-perl/TermReadKey virtual/perl-JSON-PP \
    virtual/perl-File-Spec virtual/perl-Perl-OSType \
    app-eselect/eselect-python virtual/perl-CPAN-Meta || return 1

  mkdir -p /etc/portage/package.use/
  for ((i = 0 ; i < ${#packages_use[@]} ; i++)) ; do
    echo ${packages_use[${i}]} >> ${ufile}
  done

  echo "Emerge @systemd && @world"
  # sysv-utils needed for set /sbin/init as systemd daemon
  # TODO: add sysv-utils to package.use
  USE="sysv-utils" emerge ${emerge_opts} @system @world || return 1

  # This fix bug with /etc/init.d/functions.sh
  emerge sys-devel/gcc-config sys-apps/gentoo-functions ${emerge_opts} -u || return 1

  echo "Installing layman package.."
  # The following USE changes are necessary to proceed:
  # (see "package.use" in the portage(5) man page for more details)
  # required by dev-python/cryptography-2.0.2::gentoo
  # required by dev-python/urllib3-1.22::gentoo
  # required by dev-python/requests-2.18.2-r1::gentoo
  # required by dev-python/ssl-fetch-0.4::gentoo
  # required by app-portage/layman-2.4.2::gentoo
  # required by layman (argument)
  # >=dev-libs/openssl-1.0.2l -bindist
  # For this is needed force rebuild of openssh!
  # TODO: if set useflag in package.use directory
  USE="-bindist" emerge --quiet-build layman vim openssh --autounmask-keep-masks || return 1

  echo "Cleaning packages:\n${PACKAGES2CLEAN[@]}"
  emerge -C ${PACKAGES2CLEAN[@]} || return 1

  echo "Depclean..."
  emerge --depclean

  # Set locale for testing phase
  sabayon_set_locale_conf || return 1

  echo -5 | etc-update

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
    if [ $SABAYON_ARCH == "amd64" ] ; then
      sabayon_stage3_rebuildall
    else
      sabayon_stage3_arm_rebuildall
    fi
    ;;
  *)
  echo "Use init|rebuild"
  exit 1
esac

exit $?
