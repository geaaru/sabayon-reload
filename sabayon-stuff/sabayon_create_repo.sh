#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

SABAYON_REPOS_NAME="${SABAYON_REPOS_NAME:-sabayon-reload}"
SABAYON_REPOS_DESC="${SABAYON_REPOS_DESC:-Sabayon Reload Repository}"
SABAYON_REPOS_PATH="${SABAYON_REPOS_PATH:-/repos/}"
SABAYON_REPOS_PROTO="${SABAYON_REPOS_PROTO:-file}"
SABAYON_STAGE3_KEYWORDS_FILE="${SABAYON_STAGE3_KEYWORDS_FILE:-01-sabayon.package.keywords}"
SABAYON_STAGE3_PACKAGE_KEYWORDS=(
  "app-admin/matter ~${SABAYON_ARCH}"
  "app-misc/sabayon-version ~${SABAYON_ARCH}"
)

SABAYON_EXTRA_ENV=(
  # Fix compilation of inside docker
  "dev-lang/go no-sandbox.conf"

  "dev-go/go-md2man no-sandbox.conf"
)

FILES_TO_REMOVE=(
  "/var/tmp/ccache/*"
  "/var/log/emerge.log"
  "/var/log/entropy/*"
  "/usr/portage/distfiles/"
  "/usr/portage/packages/"
  "/etc/portage/patches/"
)

SABAYON_REQUIRED_PKGS="${SABAYON_REQUIRED_PKGS}"

sabayon_repo_info () {

  echo "
SABAYON_REPOS_NAME = ${SABAYON_REPOS_NAME}
SABAYON_REPOS_DESC = ${SABAYON_REPOS_DESC}
SABAYON_REPOS_PATH = ${SABAYON_REPOS_PATH}
SABAYON_REPOS_PROTO = ${SABAYON_REPOS_PROTO}
SABAYON_REQUIRED_PKGS = ${SABAYON_REQUIRED_PKGS}

"
  return 0
}


sabayon_repo_keywords () {

  local i=0
  local kfile="/etc/portage/package.keywords/${SABAYON_STAGE3_KEYWORDS_FILE}"

  for ((i = 0 ; i < ${#SABAYON_STAGE3_PACKAGE_KEYWORDS[@]} ; i++)) ; do
    echo ${SABAYON_STAGE3_PACKAGE_KEYWORDS[${i}]} >> ${kfile}
  done

  return 0
}

sabayon_create_repo_init () {

  sabayon_repo_keywords || return 1

  sabayon_init_portage || return 1

  return 0
}

sabayon_create_repo_phase1 () {

  local emerge_opts="-j --with-bdeps=y"
  local pkgs="entropy-server vim sabayon-version"

  # TEMPORARY: Apply patch to eit commit (PR #40)
  mkdir -p /etc/portage/patches/sys-apps/entropy-server
  cp /sabayon-stuff/patches/eit_fix_ask_commit.patch \
    /etc/portage/patches/sys-apps/entropy-server

  # TEMPORARY: Apply patch to sabayon-version to force gcc 6.4.0
  sed -e 's:GCC_VER="5.4.0":GCC_VER="6.4.0":g' -i \
    /var/lib/layman/sabayon-distro/app-misc/sabayon-version/sabayon-version-18.02.ebuild
  ebuild /var/lib/layman/sabayon-distro/app-misc/sabayon-version/sabayon-version-18.02.ebuild digest

  for ((i = 0 ; i < ${#SABAYON_EXTRA_ENV[@]} ; i++)) ; do
    echo -e ${SABAYON_EXTRA_ENV[${i}]} >> \
      /etc/portage/package.env/01-sabayon.package.env
  done

  sabayon_create_repo_compile "${pkgs}" || return 1

  return 0
}

sabayon_create_repo_compile () {

  local pkgs=${1}
  local emerge_opts="-j --with-bdeps=y"

  if [ -n "${pkgs}" ] ; then

    echo "Emerging ${pkgs} packages..."

    emerge ${pkgs} ${emerge_opts} || return 1

    echo -9 | equo conf update || return 1

  fi

  return 0
}

sabayon_create_repo_files () {

  sabayon_repo_info

  if [ -e /pre-script ] ; then
    /pre-script || return 1
  fi

  sabayon_create_repo_compile "${SABAYON_REQUIRED_PKGS}" || return 1

  if [ ! -d ${SABAYON_REPOS_PATH} ] ; then
    mkdir -p ${SABAYON_REPOS_PATH} || return 1
  fi

  echo "Creating server repository file..."
  sabayon_create_server_repofile || return 1
  echo "Server repository file created correctly."

  echo "Creating repos file for ${SABAYON_REPOS_NAME}..."
  sabayon_create_repofile || return 1
  echo "Created repos file for ${SABAYON_REPOS_NAME}."

  # Disable interactive actions on eit
  export ETP_NONINTERACTIVE=1

  echo "Trying to commit all packages to local repository..."
  eit commit --quick || return 1
  echo "eit commit: COMPLETED"

  echo "Trying to push packages..."
  eit push --quick || return 1
  echo "eit push: COMPLETED"

  equo update || return 1

  equo upgrade || return 1

  return 0
}

sabayon_create_repo_clean () {

  sabayon_save_pkgs_install_list || return 1

  equo cleanup || return 1

  # Cleanup
  rm -rf "${FILES_TO_REMOVE[@]}" || return 1

  return 0
}


case $1 in
  init)
    sabayon_create_repo_init
    ;;
  phase1)
    sabayon_create_repo_phase1
    ;;
  clean)
    sabayon_create_repo_clean
    ;;
  files)
    sabayon_create_repo_files
    ;;
  *)
    echo "Use init|phase1|clean|files"
    exit 1
esac

# vim: ts=2 sw=2 expandtab
