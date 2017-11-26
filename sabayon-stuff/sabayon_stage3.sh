#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

. $(dirname $(readlink -f $BASH_SOURCE))/commons.sh

SABAYON_STAGE3_PACKAGE_KEYWORDS=(
  "app-admin/equo ~${SABAYON_ARCH}"
  "sys-apps/entropy ~${SABAYON_ARCH}"
)
SABAYON_STAGE3_PACKAGE_USE=(
  "dev-lang/python sqlite -tk"
  "sys-apps/file python"
)
SABAYON_STAGE3_KEYWORDS_FILE="${SABAYON_STAGE3_KEYWORDS_FILE:-00-sabayon.package.keywords}"
SABAYON_STAGE3_USE_FILE="${SABAYON_STAGE3_USE_FILE:-00-sabayon.package.use}"
SABAYON_EQUO_DIR="/var/lib/entropy/client/database/"

sabayon_stage3_keywords () {

  local i=0
  local kfile="/etc/portage/package.keywords/${SABAYON_STAGE3_KEYWORDS_FILE}"

  rm ${kfile} >/dev/null 2>&1

  for ((i = 0 ; i < ${#SABAYON_STAGE3_PACKAGE_KEYWORDS[@]} ; i++)) ; do
    echo ${SABAYON_STAGE3_PACKAGE_KEYWORDS[${i}]} >> ${kfile}
  done

  return 0
}

sabayon_stage3_uses () {

  local i=0
  local ufile="/etc/portage/package.use/${SABAYON_STAGE3_USE_FILE}"

  rm ${ufile} 2>&1 >/dev/null

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

sabayon_stage3_phase1_review () {

  local ufile="/etc/portage/package.use/${SABAYON_STAGE3_USE_FILE}"

  # TODO: do clarification to gentoo team
  # Use PYTHON_* from make.defaults
  sed -i -e 's:^PYTHON_TARGETS=.*:PYTHON_TARGETS="python2_7 python3_5":g' \
        /etc/portage/make.conf
  # seems that PYTHON_* are not read from make.defaults of the profile
  #-e 's:^PYTHON_SINGLE_TARGET=:#PYTHON_SINGLE_TARGET=:g' \

  #   (sys-libs/ncurses-6.0-r1:0/6::gentoo, ebuild scheduled for merge) pulled in by
  #  >=sys-libs/ncurses-5.9-r3:0=[static-libs?,abi_x86_32(-)?,abi_x86_64(-)?,abi_x86_x32(-)?,abi_mips_n32(-)?,abi_mips_n64(-)?,abi_mips_o32(-)?,abi_ppc_32(-)?,abi_ppc_64(-)?,abi_s390_32(-)?,abi_s390_64(-)?] required by (sys-libs/readline-7.0_p3:0/7::gentoo, ebuild scheduled for merge)
  #                               ^^^^^^^^^^^^

  # Avoid cycle dependency
  echo "dev-libs/openssl -kerberos" >> ${ufile}
  echo "app-crypt/mit-krb5 -openldap" >> ${ufile}
  echo "sys-devel/clang -doc" >> ${ufile}
  echo "sys-devel/llvm -doc" >> ${ufile}

  # This is for cups useflag set as general...mmm... not so good
  echo "x11-libs/gtk+ -cups" >> ${ufile}
  echo "x11-libs/libxcb xkb" >> ${ufile}

  # This permit compilation of gnome-keyring inside LXC/LXD containers
  # TODO: Setting of capabilities are been fixed on kernel >4.14
  echo "gnome-base/gnome-keyring -caps" >> ${ufile}

  emerge -C $(qlist -IC dev-perl/) $(qlist -IC virtual/perl) \
    $(qlist -IC perl-core/) \
    sys-apps/texinfo \
    app-eselect/eselect-python  || return 1

  # To fix on package.keywords
  echo "
# 2017-11-26 Geaaru: block installation of masked version
>=dev-lang/perl-5.26.9999" >> /etc/portage/package.mask/00-sabayon.package.mask

  # It seems that this is not masked
  echo "
# 2017-11-26 Geaaru: Use sabayon version
app-crypt/pinentry::gentoo" >> /etc/portage/package.mask/00-sabayon.package.mask

  echo "
# 2017-11-26 Geaaru: Use sabayon version
sys-devel/gcc::gentoo" >> /etc/portage/package.mask/00-sabayon.package.mask

  # Temporary block upgrade of readline
  # sys-libs/readline:0
  #
  #(sys-libs/readline-7.0_p3:0/7::gentoo, ebuild scheduled for merge) conflicts with
  #  sys-libs/readline:0/0= required by (sys-apps/gawk-4.1.4:0/0::gentoo, installed)
  #                   ^^^^^
  #  >=sys-libs/readline-6.3:0/0= required by (app-shells/bash-4.3_p48-r1:0/0::gentoo, installed)
  # 
  echo "
# 2017-11-26 Geaaru: temporary block
>=sys-libs/readline-7.0_p3" >> /etc/portage/package.mask/00-tmp.package.mask

  emerge $(qgrep -JN sys-libs/readline | cut -f1 -d":" | uniq | sed -e 's:^:=:g' ) -pv

  USE="-doc" emerge --newuse --deep --with-bdeps=y -j @system @world || return 1

  # Retrieve current gcc
  local current_gcc=$(gcc-config -c)
  local current_gcc_version=$(echo $(gcc-config -c) | sed -e "s:$(uname -m)-pc-linux-gnu-::g")

  # TODO: fix downgrade of gcc
  emerge sys-devel/base-gcc::sabayon-distro || return 1

  local sabayon_gcc=$(gcc-config -c)

  gcc-config $(current_gcc)

  . /etc/profile

  emerge sys-devel/gcc::sabayon-distro  --quiet-build || return 1

  gcc-config $(sabayon_gcc)

  . /etc/profile

  emerge --unmerge =sys-devel/gcc-${current_gcc_version}::gentoo

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

  local dir=""
  local reposdir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"

  sabayon_configure_portage || return 1

  # Configure repos
  if [ "${SABAYON_ARCH}" == "arm" ] ; then
    dir=${reposdir}/conf/armhfp/portage
  else
    dir=${reposdir}/conf/intel/portage
  fi

  cd $dir

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
