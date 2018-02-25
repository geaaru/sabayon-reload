#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

PACKAGES_TO_REMOVE=(
    "app-admin/sudo"
    "x11-libs/gtk+:3"
    "x11-libs/gtk+:2"
    "dev-db/mariadb"
    "sys-fs/ntfs3g"
    "app-accessibility/at-spi2-core"
    "app-accessibility/at-spi2-atk"
    "sys-devel/base-gcc:4.7"
    "sys-devel/gcc:4.7"
    "net-print/cups"
    "dev-util/gtk-update-icon-cache"
    "dev-qt/qtscript"
    "dev-qt/qtchooser"
    "dev-qt/qtcore"
    "app-shells/zsh"
    "app-shells/zsh-pol-config"
    "dev-db/mysql-init-scripts"
    "dev-lang/ruby"
    #"app-editors/vim"
    "dev-util/gtk-doc-am"
    "media-gfx/graphite2"
    "x11-apps/xset"
    "x11-themes/hicolor-icon-theme"
    "media-libs/tiff"
    "app-eselect/eselect-lcdfilter"
    "app-eselect/eselect-mesa"
    "app-eselect/eselect-opengl"
    "app-eselect/eselect-qtgraphicssystem"
    "x11-libs/pixman"
    "x11-libs/libvdpau"
    "x11-libs/libxshmfence"
    "x11-libs/libXxf86vm"
    "x11-libs/libXinerama"
    "x11-libs/libXdamage"
    "x11-libs/libXcursor"
    "x11-libs/libXfixes"
    "x11-libs/libXv"
    "x11-libs/libXcomposite"
    "x11-libs/libXrandr"
    "media-libs/jbig2dec"
    "dev-libs/libcroco"
    "app-text/qpdf"
    "media-fonts/urw-fonts"
    "app-text/libpaper"
    "dev-python/snakeoil"
    "dev-libs/atk"
    "dev-perl/DBI"
    "app-text/sgml-common"
    "sys-power/upower"
)

FILES_TO_REMOVE=(
   "/.viminfo"
   "/.history"
   "/.zcompdump"
   "/var/log/emerge.log"
   "/var/log/emerge-fetch.log"

    # Remove LDAP keys
    "/etc/openldap/ssl/ldap.pem"
    "/etc/openldap/ssl/ldap.key"
    "/etc/openldap/ssl/ldap.csr"
    "/etc/openldap/ssl/ldap.crt"

    # remove SSH keys
    "/etc/ssh/*_key*"
)

PACKAGES_TO_ADD=(
    "app-eselect/eselect-bzimage"
    "app-text/pastebunz"
    "app-misc/sabayon-devkit"
    "app-admin/perl-cleaner"
    "sys-apps/grep"
    "sys-kernel/sabayon-sources"
    "app-misc/sabayon-version"
    "app-portage/layman"
    "app-portage/eix"
    "net-misc/rsync"
    "app-crypt/gnupg"
    "sys-devel/gcc"
    "sys-devel/base-gcc"
    "dev-vcs/git"
    "app-portage/gentoolkit"
    "net-misc/openssh"
    "sys-devel/automake"
    "app-admin/enman"
    "sys-devel/distcc"

)


sabayon_builder_init () {

  if [[ -z "${SABAYON_SKIP_SYNC}" || "${SABAYON_SKIP_SYNC}" == "0" ]] ; then
    equo up && equo u || return 1
  fi

  sabayon_init_portage || return 1

  sabayon_config_portage_empty 1 0 1 || return 1

  # Copy depcheck to /usr/local/bin
  cp /sabayon-stuff/ext/depcheck /usr/local/bin || return 1

  return 0

}

sabayon_builder_sync_portage () {

  pushd /etc/portage

  git fetch --all
  git checkout master
  git reset --hard origin/master

  rm -rfv make.conf
  ln -sf make.conf.${SABAYON_ARCH} make.conf

  popd

  return 0
}

sabayon_builder_phase1 () {

  equo rm --deep --configfiles --force-system "${PACKAGES_TO_REMOVE[@]}" || return 1

  equo i "${PACKAGES_TO_ADD[@]}" || return 1

  layman-updater -R || return 1

  sabayon_upgrade_kernel || return 1

  # Merging defaults configurations
  echo -5 | equo conf update || return 1

  sabayon_builder_sync_portage || return 1

  sabayon_save_pkgs_install_list || return 1

  # Cleaning equo package cache
  equo cleanup || return 1

  # Cleanup Perl cruft
  perl-cleaner --ph-clean || return 1

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  return 0
}

case $1 in
  init)
    sabayon_builder_init
    ;;
  phase1)
    sabayon_builder_phase1
    ;;
  *)
  echo "Use init|phase1"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
