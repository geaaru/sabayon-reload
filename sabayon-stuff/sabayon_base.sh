#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

PACKAGES_TO_REMOVE=(
  "sys-devel/llvm"
  "dev-libs/ppl"
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
  "dev-perl/TermReadKey"
  "dev-perl/Test-Deep"
  "virtual/perl-IO-Zlib"
  "virtual/perl-Package-Constants"
  "virtual/perl-Term-ANSIColor"
  "virtual/perl-Time-HiRes"
  "app-text/asciidoc"
  "app-text/sgml-common"
  "virtual/python-argparse"
  "sys-power/upower"
  "dev-python/py"
  "dev-vcs/git"
  "dev-tcltk/expect"
  "app-admin/python-updater"
  "app-portage/eix"
  "app-portage/gentoolkit"
  "app-portage/gentoopm"
  "app-text/docbook-xsl-stylesheets"
  "app-text/docbook-xml-dtd"
)

FILES_TO_REMOVE=(
  "/.viminfo"
  "/.history"
  "/.zcompdump"
  "/var/log/emerge.log"
  "/var/log/emerge-fetch.log"
  "/etc/entropy/packages/license.accept"

  # Cleaning portage metadata cache
  "/var/log/emerge/*"
  "/var/log/entropy/*"
  "/root/* /root/.*"
  "/etc/zsh"

  # cleaning licenses accepted
  "/usr/portage/licenses"
  "/usr/portage/metadata"

  # Cleanup old portage profile files/dirs
  "/etc/make.profile"

  "/sabayon-stuff"
)

PACKAGE_TO_ASSIMILATE=(
  # /usr/lib64/gio/modules/giomodule.cache
  # /usr/share/glib-2.0/schemas/gschemas.compiled
  "dev-libs/glib"
  # @@ dev-lang/python-exec-2.4.5: found altered files
  # /etc/python-exec/python-exec.conf
  "dev-lang/python-exec"
)

sabayon_base_init () {

  sabayon_config_portage_licenses || return 1

  sabayon_config_default_repos || return 1

  equo up || return 1

  equo repo mirrorsort sabayonlinux.org || return 1

  return 0
}

sabayon_base_init_rebuild () {

  sabayon_config_portage_licenses || return 1

  equo up || return 1

  return 0
}

sabayon_base_phase1 () {

  echo "Upgrade packages..."

  equo upgrade || return 1

  echo "Update configuration files"

  echo -5 | equo conf update || return 1

  echo "Remove compilations tools"
  equo rm --nodeps --force-system automake bison yacc gcc localepurge || return 1

  # Writing package list file
  sabayon_save_pkgs_install_list || return 1

  equo cleanup || return 1

  return 0
}

sabayon_base_phase2 () {

  # Cleanup
  equo rm --deep --configfiles \
    --force-system "${PACKAGES_TO_REMOVE[@]}" || return 1

  # ensuring all is right
  echo "Execute deptest ..."
  equo deptest || return 1
  echo "Execute libtest ... "
  equo libtest || return 1

  echo "Installing app-misc/ca-certifcates, app-crypt/gnupg..."
  equo i app-misc/ca-certificates app-crypt/gnupg || return 1

  # install vim
  echo "Installing app-editors/vim ..."
  equo i app-editors/vim || return 1

  # Assimilate changes
  # NOTE: Assimilate doesn't return 0 on assimilated new hashes
  #       but 10. Disable check on return value.
  equo security oscheck --assimilate "${PACKAGE_TO_ASSIMILATE[@]}"

  echo "Starting security OS Check..."
  equo security oscheck || return 1

  # automake is installed by equo deptest.
  equo rm --nodeps --force-system automake || return 1

  sabayon_save_pkgs_install_list || return 1

  equo cleanup || return 1

  return 0
}

sabayon_base_clean () {

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  return 0
}


case $1 in
  init)
    if [ ${SABAYON_REBUILD} -eq 1 ] ; then
      sabayon_base_init_rebuild
    else
      sabayon_base_init
    fi
    ;;
  phase1)
    sabayon_base_phase1
    ;;
  phase2)
    sabayon_base_phase2
    ;;
  clean)
    sabayon_base_clean
    ;;
  *)
  echo "Use init|phase1|phase2|clean"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
