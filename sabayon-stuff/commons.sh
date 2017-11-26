#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

MAKE_PORTAGE_FILE=${MAKE_PORTAGE_FILE:-/etc/portage/make.conf}
REPOS_CONF_DIR=${REPOS_CONF_DIR:-/etc/portage/repos.conf/}
GENTOO_PROFILE_VERSION="${GENTOO_PROFILE_VERSION:-13.0}"
GENTOO_PROFILE_NAME="${GENTOO_PROFILE_NAME:-/systemd}"
PORTDIR=${PORTDIR:-/usr/portage}
PORTAGE_LATEST_PATH=${PORTAGE_LATEST_PATH:-/portage-latest.tar.xz}
SABAYON_ARCH="${SABAYON_ARCH:-amd64}"
SABAYON_PORTAGE_CONF_REPOS=${SABAYON_PORTAGE_CONF_REPOS:-https://github.com/Sabayon/build.git}
SABAYON_PORTAGE_CONF_INSTALLDIR="${SABAYON_PORTAGE_CONF_INSTALLDIR:-/opt}"
SABAYON_PORTAGE_CONF_INSTALLNAME="${SABAYON_PORTAGE_CONF_INSTALLNAME:-sabayon-build}"
SABAYON_PROFILE_TARGETS="${GENTOO_PROFILE_NAME:-/systemd}"
#SABAYON_PROFILE_TARGETS="/systemd /sabayon/amd64"

sabayon_set_best_mirrors () {

  which mirrorselect 2>&1 > /dev/null
  if [ $? -eq 0 ] ; then
    mirrorselect -s3 -b10 -o >> ${MAKE_PORTAGE_FILE} || return 1
  fi

  return 0
}

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

  if [[ ! -d /etc/portage/package.mask ]] ; then
    mkdir -p /etc/portage/package.mask
  fi

  if [[ ! -d /etc/portage/package.unmask ]] ; then
    mkdir -p /etc/portage/package.unmask
  fi

  if [[ ! -d /etc/portage/package.keywords ]] ; then
    mkdir -p /etc/portage/package.keywords
  fi

  return 0
}

sabayon_set_locale_conf () {

  local lang="${1:-en_US.utf8}"

  for f in /etc/env.d/02locale /etc/locale.conf; do
    echo "LANG=${lang}" > "${f}"
    echo "LANGUAGE=${lang}" >> "${f}"
    echo "LC_ALL=${lang}" >> "${f}"
  done

  return 0
}

sabayon_set_locate () {

  echo 'en_US.utf8 UTF-8' > /etc/locale.gen || return 1

  /usr/sbin/locale-gen

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

  local targets=${1:-python2_7}

  echo "PYTHON_SINGLE_TARGET=\"${targets}\"" >> ${MAKE_PORTAGE_FILE}

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

  local profile=${1:-default/linux/${SABAYON_ARCH}/${GENTOO_PROFILE_VERSION}${GENTOO_PROFILE_NAME}}

  eselect profile set ${profile}

  return $?
}

sabayon_set_pyver () {

  local v=${1:-python2.7}

  eselect python set ${v}

  return $?
}

sabayon_add_profile4target () {

  # Target is a list of targets to insert as dependency on parent file
  local targets="$1"
  local arch=${2:-${SABAYON_ARCH}}
  local profile_name=${3:-${GENTOO_PROFILE_NAME}}
  local eapi=${4:-5}

  local profile_prefix="${PORTDIR}/profiles/default/linux/${arch}/${GENTOO_PROFILE_VERSION}"
  local profile_dir="${profile_prefix}${profile_name}"
  local profile_desc="default/linux/${arch}/${GENTOO_PROFILE_VERSION}${profile_name}"

  echo "Profile Path: ${profile_dir}"

  local pwd_dir=$(pwd)

  if [ ! -d "${profile_dir}" ] ; then
    mkdir -p ${profile_dir} || return 1
    cd ${profile_dir}

    echo ${eapi} > eapi
    local parent_path=$(realpath --relative-to=${profile_dir} ${profile_prefix})

    echo "${parent_path}" > parent

    local target_path=""
    local target_realpath=""
    for target in ${targets} ; do

      # TODO: Temporary workaround to test feature and compilation with sabayon
      # targets.
      if [[ ${target} == *sabayon* ]] ; then
        sabayon_create_targets ${target} || return 1
      fi

      echo "For profile ${profile_name} for arch ${arch} connect target ${target}..."

      target_path="${PORTDIR}/profiles/targets/${target}"
      target_relpath=$(realpath --relative-to=${profile_dir} ${target_path})

      echo "${target_relpath}"   >> parent
    done

    cd ${pwd_dir}

    # Check if required add entry on profiles.desc
    add_profile_desc=$(cat ${PORTDIR}/profiles/profiles.desc  | grep "${profile_desc}"  | wc -l)

    if [ ${add_profile_desc} -eq 0 ] ; then

      local i=0
      local word=""
      local found=false
      local inserted=false
      local profiles_desc=""
      local new_profile="${arch}           ${profile_desc}           dev"

      while read line ; do
        word=$(echo $line | cut -d' ' -f1)

        if [ ${inserted} == false ] ; then
          if [ "$word" = "${arch}" ] ; then
            [ ${found} == false ] && found=true
          else
            if [ ${found} == true ] ; then
              profiles_desc="${profiles_desc}\n${new_profile}"
              inserted=true
            fi
          fi
        fi

        profiles_desc="${profiles_desc}\n${line}"

      done < <(cat ${PORTDIR}/profiles/profiles.desc)

      # Add profiles to list
      echo -en "${profiles_desc}\n" > ${PORTDIR}/profiles/profiles.desc

    fi

  else
    echo "Profile ${profile_desc} is already present."
  fi

  return 0
}

sabayon_init_portage () {

  local skip_sync=${GENTOO_SKIP_SYNC:-0}

  if [ ${skip_sync} -eq 0 ] ; then
    emerge --sync || return 1
  fi

  # Wait to a fix about this on gentoo upstream
  echo "Remove openrc from base packages"
  sed -e 's/*sys-apps\/openrc//g' -i  /usr/portage/profiles/base/packages || return 1

  sabayon_add_profile4target "${SABAYON_PROFILE_TARGETS}" || return 1

  sabayon_set_profile || return 1

  sabayon_set_pyver || return 1

  return 0
}

sabayon_install_build () {

  local builddir=${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}

  [ -z "${PORTDIR}" ] && return 1
  [ -z "${SABAYON_ARCH}" ] && return 1
  [ -z "${SABAYON_PORTAGE_CONF_INSTALLDIR}" ] && return 1
  [ -z "${SABAYON_PORTAGE_CONF_INSTALLNAME}" ] && return 1

  if [  -d "${builddir}" ] ; then

    pushd ${builddir}

    git pull -ff

  else
    pushd "${SABAYON_PORTAGE_CONF_INSTALLDIR}"

    git clone ${SABAYON_PORTAGE_CONF_REPOS} ${SABAYON_PORTAGE_CONF_INSTALLNAME}

    # Configure repos
    git config --global user.name "root" || return 1
    git config --global user.email "root@localhost" || return 1

    # Temporary for use ${SABAYON_ARCH} variable
    ln -s ${builddir}/conf/intel ${builddir}/conf/amd64 || return 1
  fi

  popd

  return 0
}

sabayon_create_targets () {

  local target_name="${1:-sabayon/${SABAYON_ARCH}}"
  local eapi=${2:-5}

  [ ${target_name:0:1} == "/" ] && target_name=${target_name:1:${#target_name}}

  local targetdir="${PORTDIR}/profiles/targets/${target_name}"
  local buildir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"
  local build_arch="${buildir}/conf/${SABAYON_ARCH}/portage"

  sabayon_install_build || return 1

  if [ "${SABAYON_ARCH}" == "amd64" ] ; then

    if [ ! -d ${targetdir} ] ; then

      mkdir -p ${targetdir} || return 1

      pushd ${targetdir}

      echo ${eapi} > eapi

      ln -s ${build_arch}/make.conf.${SABAYON_ARCH} make.defaults

      # TODO: Wait for merge of my pr
      sed -i -e 's:source /var/lib.*::g' \
        -e 's:^USE_PYTHON=.*:USE_PYTHON="2.7 3.5":g' \
        ${build_arch}/make.conf.${SABAYON_ARCH}

      ln -s ${build_arch}/profile/package.use.force/00-sabayon.package.use.force package.use.force
      ln -s ${build_arch}/package.use/00-sabayon.package.use package.use
      ln -s ${build_arch}/package.keywords/00-sabayon.package.keywords package.keywords

      # TODO: To fix on upstream
      # --- Invalid atom in /usr/portage/profiles/targets/sabayon/amd64/package.keywords: perl-core/*
      # --- Invalid atom in /usr/portage/profiles/targets/sabayon/amd64/package.keywords: virtual/perl-*
      sed -i -e 's:^perl-core/\* .*::g' \
        -e 's:dev-lang/perl .*:dev-lang/perl ~amd64 ~x86:g' \
        -e 's:^virtual/perl-\* .*::g' ${build_arch}/package.keywords/00-sabayon.package.keywords

      ln -s ${build_arch}/package.env.${SABAYON_ARCH} package.env
      ln -s ${build_arch}/profile/virtuals .

      # Currently PMS specification (targets/profiles) doesn't support syntax with ::repos
      # I will create a link on /etc/portage
      ln -s ${build_arch}/package.mask/00-sabayon.package.mask \
        /etc/portage/package.mask/00-sabayon.package.mask

      [ ! -d /etc/portage/package.use.mask ] && \
        mkdir -p /etc/portage/package.use.mask || return 1
      ln -s ${build_arch}/profile/package.use.mask/00-sabayon.mask \
        /etc/portage/package.use.mask/00-sabayon.mask

      [ ! -d /etc/portage/package.unmask ] && \
        mkdir -p /etc/portage/package.unmask || return 1
      ln -s ${build_arch}/package.unmask/00-sabayon.package.unmask \
        /etc/portage/package.unmask/00-sabayon.package.unmask
      ln -s ${build_arch}/package.license /etc/portage/package.license

      # TODO: Check if env must be moved to /etc/portage
      cp -r ${build_arch}/env .

      # Disable gentoo3 default CPU_FLAGS, USE, CFLAGS, CXXFLAGS
      # from /etc/portage/make.conf
      sed -i -e 's:^CFLAGS=:#CFLAGS=:g' \
        -e 's:^CXXFLAGS=:#CXXFLAGS=:g' \
        -e 's:^CPU_FLAGS_X86:#CPU_FLAGS_X86:g' \
        -e 's:^USE=:#USE=:g' \
        /etc/portage/make.conf

      popd

    else

      echo "Target ${target_name} already present. Nothing to create."

    fi

  else
    echo "ARCH ${SABAYON_ARCH} not yet supported."
    return 1
  fi

  return 0
}

sabayon_configure_portage () {

  local init_etc=${1:-0}
  local reposdir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"

  sabayon_install_build || return 1

  # TODO: check if correct maintains intel configuration

  if [ ${init_etc} -eq 1 ] ; then
    cd /etc
    mv portage portage-gentoo || return 1
    ln -s ${reposdir}/conf/intel/portage portage || return 1

  fi

  return 0
}

sabayon_config_portage_licenses () {

  local only_creation_file=${1:-0}

  # Maintains only licenses directory
  #   ! -name '*profiles' \
    # Metadata is needed to avoid this warning:
  #!!! Repository 'x-portage' is missing masters attribute in '/usr/portage/metadata/layout.conf'
  #!!! Set 'masters = gentoo' in this file for future compatibility

  if [ ${only_creation_file} -eq 0 ] ; then

    local rmdirs=$(find ${PORTDIR} -maxdepth 1 -type d \
      ! -name '*metadata' \
      ! -path ${PORTDIR} ! -name '*licenses')

    for i in ${rmdirs} ; do
      echo "Removing dir ${i} ..."
      rm -rf ${i}
    done

  fi

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

sabayon_configure_repoman () {

  mkdir -p ${PORTDIR}/distfiles/ || return 1

  wget http://www.gentoo.org/dtd/metadata.dtd \
    -O ${PORTDIR}/distfiles/metadata.dtd || return 1

  chown -R root:portage ${PORTDIR}/distfiles/ || return 1

  chmod g+w ${PORTDIR}/distfiles/ || return 1

  return 0
}

# vim: ts=2 sw=2 expandtab
