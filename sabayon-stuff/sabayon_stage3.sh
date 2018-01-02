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
SABAYON_STAGE3_KEYWORDS_FILE="${SABAYON_STAGE3_KEYWORDS_FILE:-01-sabayon.package.keywords}"
SABAYON_STAGE3_USE_FILE="${SABAYON_STAGE3_USE_FILE:-01-sabayon.package.use}"
SABAYON_EQUO_DIR="/var/lib/entropy/client/database/"

SABAYON_EXTRA_MASK=(
  # To fix on package.keywords
  "# 2017-11-26 Geaaru: block installation of masked version"
  ">=dev-lang/perl-5.26.9999"
  ""

  # It seems that this is not masked
  "# 2017-11-26 Geaaru: Use sabayon version"
  "app-crypt/pinentry::gentoo"
  ""

  "# 2017-11-26 Geaaru: Use sabayon version"
  "sys-devel/gcc::gentoo"
  ""

  "# 2017-12-16 Geaaru: Mask cryptsetup for linking problems"
  ">=sys-fs/cryptsetup-2.0.0"
  ""

  # Temporary block upgrade of readline
  # sys-libs/readline:0
  #
  #(sys-libs/readline-7.0_p3:0/7::gentoo, ebuild scheduled for merge) conflicts with
  #  sys-libs/readline:0/0= required by (sys-apps/gawk-4.1.4:0/0::gentoo, installed)
  #                   ^^^^^
  #  >=sys-libs/readline-6.3:0/0= required by (app-shells/bash-4.3_p48-r1:0/0::gentoo, installed)
  "# 2017-11-26 Geaaru: temporary block"
  ">=sys-libs/readline-7.0_p3"
  ""
  ## [Filesystem baselayout and init scripts]
  # !!! copy /var/tmp/entropy/sys-apps/baselayout-2.3/cbah9K/image/etc/hosts -> /etc/hosts failed.
  "# 2017-12-30 Geaaru: Mask baselayout for override of /etc/hosts file"
  "sys-apps/baselayout::gentoo"
  ""
)

SABAYON_EXTRA_USE=(

  # Avoid cycle dependency
  "dev-libs/openssl -kerberos"
  "app-crypt/mit-krb5 -openldap"
  "sys-devel/clang -doc"
  "sys-devel/llvm -doc"

  # /var/tmp/portage/sys-devel/gcc-5.4.0-r3/work/gcc-5.4.0/libgo/runtime/proc.c:155:4: error: #error unknown case for SETCONTEXT_CLOBBERS_TLS
  #  error unknown case for SETCONTEXT_CLOBBERS_TLS
  #  ^
  # /var/tmp/portage/sys-devel/gcc-5.4.0-r3/work/gcc-5.4.0/libgo/runtime/proc.c: In function ‘runtime_gogo’:
  # /var/tmp/portage/sys-devel/gcc-5.4.0-r3/work/gcc-5.4.0/libgo/runtime/proc.c:249:2: warning: implicit declaration of function ‘fixcontext’ [-Wimplicit-function-declaration]
  # fixcontext(&newg->context);
  # ^
  # /var/tmp/portage/sys-devel/gcc-5.4.0-r3/work/gcc-5.4.0/libgo/runtime/proc.c: In function ‘runtime_schedinit’:
  # /var/tmp/portage/sys-devel/gcc-5.4.0-r3/work/gcc-5.4.0/libgo/runtime/proc.c:455:2: warning: implicit declaration of function ‘initcontext’ [-Wimplicit-function-declaration]
  # initcontext();
  #
  # Go module it seems broken. I disable it for now.
  "sys-devel/gcc -go"

  # This is for cups useflag set as general...mmm... not so good
  "x11-libs/gtk+ -cups"
  "x11-libs/libxcb xkb"

  # This permit compilation of gnome-keyring inside LXC/LXD containers
  # TODO: Setting of capabilities are been fixed on kernel >4.14
  "gnome-base/gnome-keyring -caps"
  "sys-libs/pam -filecaps"

)

SABAYON_EXTRA_ENV=(

  # Fix compilation of gobject-instrospection inside docker
  # /proc/10702/cmdline: /bin/bash /usr/bin/ldd /var/tmp/portage/dev-libs/gobject-introspection-1.52.1/work/gobject-introspection-1.52.1/tmp-introspectwQePOR/GLib-2.0 
  #
  # * /var/tmp/portage/sys-apps/sandbox-2.10-r4/work/sandbox-2.10/libsandbox/trace.c:_do_ptrace():74: failure (Operation not permitted):
  # * ISE:_do_ptrace: ptrace(PTRACE_TRACEME, ..., 0x0000000000000000, 0x0000000000000000): Operation not permitted
  # /usr/lib64/libsandbox.so(+0xae02)[0x7f84cf83ae02]
  # /usr/lib64/libsandbox.so(+0xaee8)[0x7f84cf83aee8]
  # /usr/lib64/libsandbox.so(+0x6189)[0x7f84cf836189]
  # /usr/lib64/libsandbox.so(+0x63a8)[0x7f84cf8363a8]
  # /usr/lib64/libsandbox.so(+0x6c8f)[0x7f84cf836c8f]
  # /usr/lib64/libsandbox.so(execve+0x3b)[0x7f84cf838f1b]
  # /bin/bash[0x41b6fc]
  # /bin/bash[0x41d1a6]
  # /bin/bash[0x41de34]
  # /bin/bash[0x45fb1b]
  # /proc/10704/cmdline: /bin/bash /usr/bin/ldd /var/tmp/portage/dev-libs/gobject-introspection-1.52.1/work/gobject-introspection-1.52.1/tmp-introspectwQePOR/GLib-2.0 
  #
  "dev-libs/gobject-introspection no-sandbox.conf"

  # Some problems with sandbox it seems present on sys-devel/gcc
  "sys-devel/gcc no-sandbox.conf"

  "sys-libs/glibc no-sandbox.conf"
)

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
  local size=""

  mkdir -p ${equodir} || return 1
  cd ${equodir}

  cat /sabayon-stuff/ext/equo.sql | sqlite3 equo.db || return 1

  size=$(ls -l ${equodir}/equo.db  | cut -d' ' -f5)
  if [ x"$size" == x"0" ] ; then
    echo "Something go wrong on create equo.db."
    return 1
  fi

  echo "Create equo.db database from schema correctly."

  return 0
}

sabayon_stage3_phase1_review () {

  local i=0
  local ufile="/etc/portage/package.use/${SABAYON_STAGE3_USE_FILE}"
  local emerge_opts="-j --with-bdeps=y"

  # TODO: do clarification to gentoo team
  # Use PYTHON_* from make.defaults
  sed -i -e 's:^PYTHON_TARGETS=.*:PYTHON_TARGETS="python2_7 python3_5":g' \
        /etc/portage/make.conf
  # seems that PYTHON_* are not read from make.defaults of the profile
  #-e 's:^PYTHON_SINGLE_TARGET=:#PYTHON_SINGLE_TARGET=:g' \

  for ((i = 0 ; i < ${#SABAYON_EXTRA_USE[@]} ; i++)) ; do
    echo -e ${SABAYON_EXTRA_USE[${i}]} >> ${ufile}
  done

  [ ! -e /etc/portage/env/no-sandbox.conf ] && \
    echo 'FEATURES="-sandbox -usersandbox"' > /etc/portage/env/no-sandbox.conf

  for ((i = 0 ; i < ${#SABAYON_EXTRA_ENV[@]} ; i++)) ; do
    echo -e ${SABAYON_EXTRA_ENV[${i}]} >> \
      /etc/portage/package.env/01-sabayon.package.env
  done

  emerge -C $(qlist -IC dev-perl/) $(qlist -IC virtual/perl) \
    $(qlist -IC perl-core/) \
    app-crypt/pinentry \
    sys-apps/texinfo \
    sys-apps/baselayout \
    dev-python/requests \
    app-eselect/eselect-python  || return 1

  for ((i = 0 ; i < ${#SABAYON_EXTRA_MASK[@]} ; i++)) ; do
    echo ${SABAYON_EXTRA_MASK[${i}]} >> \
      /etc/portage/package.mask/00-tmp.package.mask
  done

  emerge ${emerge_opts} dev-perl/XML-Parser \
    $(qgrep -JN sys-libs/readline | cut -f1 -d":" | uniq | sed -e 's:^:=:g' ) || return 1

  # This fix bug with /etc/init.d/functions.sh
  emerge sys-devel/gcc-config sys-apps/gentoo-functions -j -u || return 1

  # Retrieve current gcc
  local current_gcc=$(gcc-config -c)
  local current_gcc_version=$(echo $(gcc-config -c) | sed -e "s:$(uname -m)-pc-linux-gnu-::g")

  # TODO: fix downgrade of gcc
  emerge sys-devel/base-gcc::sabayon-distro --quiet-build || return 1

  local sabayon_gcc=$(gcc-config -c)

  gcc-config ${current_gcc} || return 1

  . /etc/profile

  emerge sys-devel/gcc::sabayon-distro  --quiet-build || return 1

  gcc-config ${sabayon_gcc} || return 1

  . /etc/profile

  emerge --unmerge =sys-devel/gcc-${current_gcc_version}::gentoo || return 1

  USE="-doc" emerge --newuse --deep --with-bdeps=y -j @system @world || return 1

  sabayon_stage3_phase1 || return 1

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

sabayon_stage3_clean () {

  rm -rf /var/tmp/ccache/*

  rm /var/log/emerge.log

  rm -rf /sabayon-stuff

  rm -rf /usr/portage/

  return 0
}

case $1 in
  init)
    sabayon_stage3_init
    ;;
  phase1)
    if [ ${SABAYON_REBUILD} -eq 0 ] ; then
      sabayon_stage3_phase1
    else
      sabayon_stage3_phase1_review
    fi
    ;;
  phase2)
    if [ ${SABAYON_REBUILD} -eq 0 ] ; then
      sabayon_stage3_phase2
    fi
    ;;
  clean)
    sabayon_stage3_clean
    ;;
  *)
  echo "Use init|phase1|phase2"
  exit 1
esac

exit $?

# vim: ts=2 sw=2 expandtab
