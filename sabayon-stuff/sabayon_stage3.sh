#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

SABAYON_STAGE3_PACKAGE_KEYWORDS=(
  "app-admin/equo ~amd64"
  "sys-apps/entropy ~amd64"
)
SABAYON_STAGE3_PACKAGE_USE=(
  "dev-lang/python sqlite"
  "sys-apps/file python"
)
SABAYON_STAGE3_KEYWORDS_FILE="00-sabayon.package.keywords"
SABAYON_STAGE3_USE_FILE="00-sabayon.package.use"
SABAYON_EQUO_DIR="/var/lib/entropy/client/database/"
SABAYON_ARCH="amd64"
SABAYON_PORTAGE_CONF_REPOS=https://github.com/Sabayon/build.git
SABAYON_PORTAGE_CONF_INSTALLDIR="/opt"
SABAYON_PORTAGE_CONF_INSTALLNAME="sabayon-build"

sabayon_stage3_keywords () {

  local i=0
  local kfile="/etc/portage/package.keywords/${SABAYON_STAGE3_KEYWORDS_FILE}"

  rm ${kfile} 2>&1 >/dev/null

  for ((i = 0 ; i < ${#SABAYON_STAGE3_PACKAGE_KEYWORDS[@]} ; i++)) ; do
    echo ${SABAYON_STAGE3_PACKAGE_KEYWORDS[${i}]} >> ${kfile}
  done

  return 0
}

sabayon_stage3_uses () {

  local i=0
  local ufile="/etc/portage/package.use/${SABAYON_STAGE3_USE_FILE}"

  rm ${kfile} 2>&1 >/dev/null

  for ((i = 0 ; i < ${#SABAYON_STAGE3_PACKAGE_USE[@]} ; i++)) ; do
    echo ${SABAYON_STAGE3_PACKAGE_USE[${i}]} >> ${ufile}
  done

  return 0
}

sabayon_stage3_gcc_config () {

  gcc-config 1 || return 1

  echo "Set GCC Profile $(gcc-config -c)."

  . /etc/profile

  return 0
}

sabayon_stage3_init () {

  sabayon_set_resolvconf || return 1

  sabayon_init_portage || return 1

  sabayon_install_overlay "sabayon" 1 || return 1

  sabayon_set_locale_conf || return 1

  sabayon_check_etc_portage || return 1

  sabayon_stage3_keywords || return 1

  sabayon_stage3_uses || return 1

  sabayon_install_overlay "sabayon-distro" 1 || return 1

#  Is already present fix from gentoo stage3
#  sabayon_gcc_config_fixbug || return 1

  sabayon_stage3_gcc_config || return 1

  return 0
}

sabayon_stage3_init_equo () {

  local equodir=${SABAYON_EQUO_DIR}/${SABAYON_ARCH}

  mkdir -p ${equodir} || return 1
  cd ${equodir}

  cat /sabayon-stuff/ext/equo.sql | sqlite3 equo.db || return 1

  return 0
}

sabayon_stage3_phase1 () {

  local pkg2install=(
    equo
    expect
  )

  USE="ncurses" emerge -j -vt ${pkg2install[@]} --autounmask-write || return

  sabayon_set_default_shell "/bin/bash" || return 1

  # Create equo database and directory
  sabayon_stage3_init_equo || return 1

  # Calling equo rescue generate, unfortunately we have to use expect
  /usr/bin/expect /sabayon-stuff/ext/equo-rescue-generate.exp || return 1

  return 0
}

sabayon_stage3_phase2 () {

  local reposdir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"
  sabayon_configure_portage || return 1

  # Configure repos
  cd ${reposdir}/conf/intel/portage

  git checkout -b myconf || return 1

  ln -sf make.conf.${SABAYON_ARCH} make.conf || return 1
  ln -sf package.env.${SABAYON_ARCH} package.env || return 1

  git add make.conf package.env || return 1

  git commit -m "Saving configuration" || return 1

  return 0
}

case $1 in
  init)
    sabayon_stage3_init
    ;;
  phase1)
    sabayon_stage3_phase1
    ;;
  phase2)
    sabayon_stage3_phase2
    ;;
  *)
  echo "Use init|phase1|phase2"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
