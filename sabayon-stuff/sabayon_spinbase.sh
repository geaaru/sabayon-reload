#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

SABAYON_KERNEL_PKG="${SABAYON_KERNEL_PKG:-sys-kernel/linux-sabayon}"

FILES_TO_REMOVE=(
   "/.viminfo"
   "/.history"
   "/.zcompdump"
   "/var/log/emerge.log"
   "/var/log/emerge-fetch.log"
   "/etc/entropy/packages/license.accept"
   # LDAP keys
   "/etc/openldap/ssl/ldap.pem"
   "/etc/openldap/ssl/ldap.key"
   "/etc/openldap/ssl/ldap.csr"
   "/etc/openldap/ssl/ldap.crt"
)

PACKAGES_TO_ADD=(
    "app-eselect/eselect-bzimage"
    "app-editors/nano"
    "app-admin/sudo"
    "sys-process/procps"
    "app-text/pastebunz"
    "app-admin/perl-cleaner"
    "sys-apps/grep"
    "sys-apps/busybox"
    "app-misc/sabayon-live"
    "sys-boot/grub:2"
    "dev-lang/perl"
    "dev-lang/python"
    "sys-devel/binutils"
    "app-misc/sabayon-version"
    "x11-themes/sabayon-artwork-grub"
    "app-crypt/gnupg"
    "x11-themes/sabayon-artwork-isolinux"
    "app-crypt/shim-signed"
    "dev-perl/Module-Build"
    "net-misc/networkmanager"
    "sys-auth/nss-mdns"
)


sabayon_spinbase_init () {

  # Make sure we have /boot/grub before installing
  # sabayon-artwork-grub (so that it's able to copy
  # the splash over to the correct location)
  [ ! -e /boot/grub ] && \
    mkdir -p /boot/grub || return 1

  sabayon_config_portage_empty 1 0 1 || return 1

  sabayon_init_env

  return 0
}

sabayon_spinbase_phase1 () {

  equo i "${PACKAGES_TO_ADD[@]}" || return 1

  # Configure glibc locale, ship image with all locales enabled
  # or anaconda will crash if the user selects an unsupported one

  sabayon_set_all_locales || return 1

  sabayon_upgrade_kernel "${SABAYON_KERNEL_PKG}" || return 1

  systemctl enable systemd-timesyncd || return 1

  # Setting bzimage
  eselect bzimage set 1 || return 1

  # Merging defaults configurations
  echo -5 | equo conf update || return 1

  # Check if create initramfs
  sabayon_create_dracut_initramfs || return 1

  # Cleanup perl cruft
  perl-cleaner --ph-clean || return 1

  # Cleaning equo package cache
  equo cleanup || return 1

  # Writing package list file
  sabayon_save_pkgs_install_list || return 1

  # Needed by systemd, because it doesn't properly set a good
  # encoding in ttys. Test it with (on tty1, VT1):
  # echo -e "\xE2\x98\xA0"
  # TODO: check if the issue persists with systemd 202.
  # echo FONT=LatArCyrHeb-16 > /etc/vconsole.conf

  # Remove SSH keys
  rm -rf /etc/ssh/*_key* || return 1

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  # Assimilate changes. (Ignore result value).
  equo security oscheck --assimilate

  return 0
}

case $1 in
  init)
    sabayon_spinbase_init
    ;;
  phase1)
    sabayon_spinbase_phase1
    ;;
  *)
  echo "Use init|phase1"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
