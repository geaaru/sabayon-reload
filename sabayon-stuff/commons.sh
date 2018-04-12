#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

MAKE_PORTAGE_FILE=${MAKE_PORTAGE_FILE:-/etc/portage/make.conf}
REPOS_CONF_DIR=${REPOS_CONF_DIR:-/etc/portage/repos.conf/}
GENTOO_PROFILE_VERSION="${GENTOO_PROFILE_VERSION:-17.0}"
GENTOO_PROFILE_NAME="${GENTOO_PROFILE_NAME:-/systemd}"
#GENTOO_PROFILE_NAME="/sabayon"
PORTDIR=${PORTDIR:-/usr/portage}
PORTAGE_LATEST_PATH=${PORTAGE_LATEST_PATH:-/portage-latest.tar.xz}
SABAYON_ARCH="${SABAYON_ARCH:-amd64}"
SABAYON_PORTAGE_CONF_REPOS=${SABAYON_PORTAGE_CONF_REPOS:-https://github.com/Sabayon/build.git}
SABAYON_PORTAGE_CONF_INSTALLDIR="${SABAYON_PORTAGE_CONF_INSTALLDIR:-/opt}"
SABAYON_PORTAGE_CONF_INSTALLNAME="${SABAYON_PORTAGE_CONF_INSTALLNAME:-sabayon-build}"
SABAYON_PROFILE_TARGETS="${SABAYON_PROFILE_TARGETS:-/systemd}"
SABAYON_REBUILD=${SABAYON_REBUILD:-0}
#SABAYON_PROFILE_TARGETS="/systemd /sabayon/amd64"

sabayon_build_info () {

  local profile=${1:-default/linux/${SABAYON_ARCH}/${GENTOO_PROFILE_VERSION}${GENTOO_PROFILE_NAME}}

  echo "
GENTOO_PROFILE_VERSION            = ${GENTOO_PROFILE_VERSION}
GENTOO_PROFILE_NAME               = ${GENTOO_PROFILE_NAME}
GENTOO_PROFILE                    = ${profile}
GENTOO_SKIP_SYNC                  = ${GENTOO_SKIP_SYNC}
SABAYON_PROFILE_TARGETS           = ${SABAYON_PROFILE_TARGETS}
SABAYON_ARCH                      = ${SABAYON_ARCH}
SABAYON_REBUILD                   = ${SABAYON_REBUILD}
SABAYON_PORTAGE_CONF_REPOS        = ${SABAYON_PORTAGE_CONF_REPOS}
SABAYON_PORTAGE_CONF_INSTALLDIR   = ${SABAYON_PORTAGE_CONF_INSTALLDIR}
SABAYON_PORTAGE_CONF_INSTALLNAME  = ${SABAYON_PORTAGE_CONF_INSTALLNAME}
"
  return 0
}

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

  sabayon_load_locate || return 1

  return 0
}

sabayon_load_locate () {

  eselect locale set en_US.utf8 || return 1

  . /etc/profile

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

  local targets=${1:-python3_5}

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
  echo "Targets: ${targets}"

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
        sabayon_create_targets "${target}"
        if [ $? -eq 1 ] ; then
          echo "ERROR from sabayon_create_targets"
          return 1
        fi
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

      echo "Creating profile ${profile_desc} on file ${PORTDIR}/profiles/profiles.desc ..."

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

    else

      echo "Profile ${profiles_desc} already present on ${PORTDIR}/profiles/profiles.desc file."

    fi

  else
    echo "Profile ${profile_desc} is already present."
  fi

  return 0
}

sabayon_init_portage () {

  local skip_sync=${GENTOO_SKIP_SYNC:-1}

  if [ ${skip_sync} -eq 0 ] ; then
    emerge --sync || return 1
  fi

  # Wait to a fix about this on gentoo upstream
  echo "Remove openrc from base packages"
  sed -e 's/*sys-apps\/openrc//g' -i  /usr/portage/profiles/base/packages || return 1

  sabayon_build_info

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

    git add .
    git commit . -m "Local changes"
    EDITOR=cat git pull -ff

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

  local i=0
  local target_name="${1:-sabayon/${SABAYON_ARCH}}"
  local eapi=${2:-5}

  [ ${target_name:0:1} == "/" ] && target_name=${target_name:1:${#target_name}}

  local targetdir="${PORTDIR}/profiles/targets/${target_name}"
  local buildir="${SABAYON_PORTAGE_CONF_INSTALLDIR}/${SABAYON_PORTAGE_CONF_INSTALLNAME}"
  local build_arch="${buildir}/conf/${SABAYON_ARCH}/portage"

  echo "Creating targetdir ${targetdir}..."

  sabayon_install_build || return 1

  if [ "${SABAYON_ARCH}" == "amd64" ] ; then

    echo "======> Prepare target ${target_name} for ARCH ${SABAYON_ARCH}"

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
      # package.keywords is not usable under target, use package.accept_keywords
      ln -s ${build_arch}/package.keywords/00-sabayon.package.keywords package.accept_keywords

      # TODO: To fix on upstream
      # --- Invalid atom in /usr/portage/profiles/targets/sabayon/amd64/package.keywords: perl-core/*
      # --- Invalid atom in /usr/portage/profiles/targets/sabayon/amd64/package.keywords: virtual/perl-*
      sed -i -e 's:^perl-core/\* .*::g' \
        -e 's:dev-lang/perl .*:dev-lang/perl -~amd64 -~x86:g' \
        -e 's:^virtual/perl-\* .*::g' ${build_arch}/package.keywords/00-sabayon.package.keywords

      local stable_perl_virtuals=(
        "virtual/perl-Archive-Tar"
        "virtual/perl-Attribute-Handlers"
        "virtual/perl-autodie"
        "virtual/perl-bignum"
        "virtual/perl-Carp"
        "virtual/perl-Compress-Raw-Bzip2"
        "virtual/perl-Compress-Raw-Zlib"
        "virtual/perl-CPAN-Meta"
        "virtual/perl-CPAN-Meta-Requirements"
        "virtual/perl-CPAN-Meta-YAML"
        "virtual/perl-Data-Dumper"
        "virtual/perl-DB_File"
        "virtual/perl-Digest"
        "virtual/perl-Digest-MD5"
        "virtual/perl-Digest-SHA"
        "virtual/perl-Encode"
        "virtual/perl-Exporter"
        "virtual/perl-ExtUtils-CBuilder"
        "virtual/perl-ExtUtils-Constant"
        "virtual/perl-ExtUtils-Install"
        "virtual/perl-ExtUtils-MakeMaker"
        "virtual/perl-ExtUtils-Manifest"
        "virtual/perl-ExtUtils-ParseXS"
        "virtual/perl-File-Path"
        "virtual/perl-File-Spec"
        "virtual/perl-File-Temp"
        "virtual/perl-Filter-Simple"
        "virtual/perl-Getopt-Long"
        "virtual/perl-if"
        "virtual/perl-IO"
        "virtual/perl-IO-Compress"
        "virtual/perl-IO-Socket-IP"
        "virtual/perl-IO-Zlib"
        "virtual/perl-IPC-Cmd"
        "virtual/perl-JSON-PP"
        "virtual/perl-libnet"
        "virtual/perl-Locale-Maketext"
        "virtual/perl-Locale-Maketext-Simple"
        "virtual/perl-Math-BigInt"
        "virtual/perl-Math-BigInt-FastCalc"
        "virtual/perl-Math-BigRat"
        "virtual/perl-Math-Complex"
        "virtual/perl-Memoize"
        "virtual/perl-MIME-Base64"
        "virtual/perl-Module-CoreList"
        "virtual/perl-Module-Load"
        "virtual/perl-Module-Load-Conditional"
        "virtual/perl-Module-Metadata"
        "virtual/perl-Params-Check"
        "virtual/perl-parent"
        "virtual/perl-Parse-CPAN-Meta"
        "virtual/perl-Perl-OSType"
        "virtual/perl-Pod-Escapes"
        "virtual/perl-podlators"
        "virtual/perl-Pod-Parser"
        "virtual/perl-Pod-Simple"
        "virtual/perl-Scalar-List-Utils"
        "virtual/perl-Socket"
        "virtual/perl-Storable"
        "virtual/perl-Sys-Syslog"
        "virtual/perl-Term-ANSIColor"
        "virtual/perl-Term-ReadLine"
        "virtual/perl-Test-Harness"
        "virtual/perl-Test-Simple"
        "virtual/perl-Text-Balanced"
        "virtual/perl-Text-ParseWords"
        "virtual/perl-Text-Tabs+Wrap"
        "virtual/perl-Tie-RefHash"
        "virtual/perl-Time-HiRes"
        "virtual/perl-Time-Local"
        "virtual/perl-Time-Piece"
        "virtual/perl-version"
        "virtual/perl-XSLoader"

        "dev-perl/Algorithm-C3"
        "dev-perl/Algorithm-Diff"
        "dev-perl/aliased"
        "dev-perl/AnyEvent"
        "dev-perl/App-Cmd"
        "dev-perl/AppConfig"
        "dev-perl/App-Nopaste"
        "dev-perl/App-pwhich"
        "dev-perl/Archive-Tar-Wrapper"
        "dev-perl/Archive-Zip"
        "dev-perl/Astro-FITS-Header"
        "dev-perl/Authen-SASL"
        "dev-perl/AutoXS-Header"
        "dev-perl/bareword-filehandles"
        "dev-perl/B-Hooks-EndOfScope"
        "dev-perl/B-Hooks-OP-Check"
        "dev-perl/B-Keywords"
        "dev-perl/Browser-Open"
        "dev-perl/B-Utils"
        "dev-perl/Cairo"
        "dev-perl/Canary-Stability"
        "dev-perl/Capture-Tiny"
        "dev-perl/Carp-Clan"
        "dev-perl/CGI"
        "dev-perl/Class-Accessor"
        "dev-perl/Class-Accessor-Chained"
        "dev-perl/Class-Accessor-Grouped"
        "dev-perl/Class-Base"
        "dev-perl/Class-C3"
        "dev-perl/Class-C3-Componentised"
        "dev-perl/Class-C3-XS"
        "dev-perl/Class-Data-Inheritable"
        "dev-perl/Class-DBI"
        "dev-perl/Class-DBI-Plugin"
        "dev-perl/Class-DBI-Plugin-DeepAbstractSearch"
        "dev-perl/Class-ErrorHandler"
        "dev-perl/Class-Factory-Util"
        "dev-perl/Class-Inspector"
        "dev-perl/Class-Load"
        "dev-perl/Class-Load-XS"
        "dev-perl/Class-MakeMethods"
        "dev-perl/Class-MethodMaker"
        "dev-perl/Class-Method-Modifiers"
        "dev-perl/Class-Singleton"
        "dev-perl/Class-Std"
        "dev-perl/Class-Std-Fast"
        "dev-perl/Class-Trigger"
        "dev-perl/Class-WhiteHole"
        "dev-perl/Class-XSAccessor"
        "dev-perl/Clipboard"
        "dev-perl/Clone"
        "dev-perl/common-sense"
        "dev-perl/Config-Any"
        "dev-perl/Config-General"
        "dev-perl/Config-INI"
        "dev-perl/Config-MVP"
        "dev-perl/Config-MVP-Reader-INI"
        "dev-perl/Config-Simple"
        "dev-perl/Config-Tiny"
        "dev-perl/Const-Fast"
        "dev-perl/Context-Preserve"
        "dev-perl/Convert-ASN1"
        "dev-perl/CPAN-Uploader"
        "dev-perl/Crypt-DES"
        "dev-perl/Crypt-OpenSSL-Bignum"
        "dev-perl/Crypt-OpenSSL-DSA"
        "dev-perl/Crypt-OpenSSL-Random"
        "dev-perl/Crypt-OpenSSL-RSA"
        "dev-perl/Crypt-PasswdMD5"
        "dev-perl/Crypt-RC4"
        "dev-perl/Crypt-Rijndael"
        "dev-perl/Crypt-SMIME"
        "dev-perl/Crypt-SSLeay"
        "dev-perl/Data-Compare"
        "dev-perl/Data-Dump"
        "dev-perl/Data-Dumper-Concise"
        "dev-perl/Data-Dump-Streamer"
        "dev-perl/Data-OptList"
        "dev-perl/Data-Page"
        "dev-perl/Data-Section"
        "dev-perl/Data-UUID"
        "dev-perl/Date-Manip"
        "dev-perl/Date-Simple"
        "dev-perl/DateTime"
        "dev-perl/DateTime-Format-Builder"
        "dev-perl/DateTime-Format-Mail"
        "dev-perl/DateTime-Format-SQLite"
        "dev-perl/DateTime-Format-Strptime"
        "dev-perl/DateTime-Format-W3CDTF"
        "dev-perl/DateTime-Locale"
        "dev-perl/DateTime-TimeZone"
        "dev-perl/DBD-mysql"
        "dev-perl/DBD-SQLite"
        "dev-perl/DBI"
        "dev-perl/DBIx-Class"
        "dev-perl/DBIx-ContextualFetch"
        "dev-perl/Devel-Caller"
        "dev-perl/Devel-CheckLib"
        "dev-perl/Devel-GlobalDestruction"
        "dev-perl/Devel-LexAlias"
        "dev-perl/Devel-OverloadInfo"
        "dev-perl/Devel-REPL"
        "dev-perl/Devel-StackTrace"
        "dev-perl/Device-SerialPort"
        "dev-perl/Digest-BubbleBabble"
        "dev-perl/Digest-GOST"
        "dev-perl/Digest-HMAC"
        "dev-perl/Digest-Perl-MD5"
        "dev-perl/Digest-SHA1"
        "dev-perl/Dist-CheckConflicts"
        "dev-perl/Dist-Zilla"
        "dev-perl/Email-Date-Format"
        "dev-perl/Encode-Detect"
        "dev-perl/Encode-Locale"
        "dev-perl/Error"
        "dev-perl/Eval-Closure"
        "dev-perl/Event"
        "dev-perl/Event-ExecFlow"
        "dev-perl/Event-RPC"
        "dev-perl/Exporter-Tiny"
        "dev-perl/ExtUtils-CChecker"
        "dev-perl/ExtUtils-Config"
        "dev-perl/ExtUtils-Depends"
        "dev-perl/ExtUtils-F77"
        "dev-perl/ExtUtils-Helpers"
        "dev-perl/ExtUtils-InstallPaths"
        "dev-perl/ExtUtils-PkgConfig"
        "dev-perl/File-BaseDir"
        "dev-perl/File-Copy-Recursive"
        "dev-perl/File-DesktopEntry"
        "dev-perl/File-Find-Rule"
        "dev-perl/File-HomeDir"
        "dev-perl/File-Listing"
        "dev-perl/File-Map"
        "dev-perl/File-MimeInfo"
        "dev-perl/File-Next"
        "dev-perl/File-pushd"
        "dev-perl/File-ShareDir"
        "dev-perl/File-ShareDir-Install"
        "dev-perl/File-Slurp-Tiny"
        "dev-perl/File-Which"
        "dev-perl/Filter"
        "dev-perl/Finance-Quote"
        "dev-perl/Font-TTF"
        "dev-perl/frontier-rpc"
        "dev-perl/GD"
        "dev-perl/GDGraph"
        "dev-perl/GD-Graph3d"
        "dev-perl/GD-SVG"
        "dev-perl/GDTextUtil"
        "dev-perl/Geo-IP"
        "dev-perl/Getopt-Long-Descriptive"
        "dev-perl/Getopt-Mixed"
        "dev-perl/glib-perl"
        "dev-perl/GSSAPI"
        "dev-perl/Gtk2"
        "dev-perl/gtk2-ex-formfactory"
        "dev-perl/Hash-Merge"
        "dev-perl/HTML-Element-Extended"
        "dev-perl/HTML-Form"
        "dev-perl/HTML-Parser"
        "dev-perl/HTML-TableExtract"
        "dev-perl/HTML-Tagset"
        "dev-perl/HTML-Tree"
        "dev-perl/HTTP-Cookies"
        "dev-perl/HTTP-Daemon"
        "dev-perl/HTTP-Date"
        "dev-perl/HTTP-Message"
        "dev-perl/HTTP-Negotiate"
        "dev-perl/Ima-DBI"
        "dev-perl/Import-Into"
        "dev-perl/indirect"
        "dev-perl/Inline"
        "dev-perl/Inline-C"
        "dev-perl/IO-HTML"
        "dev-perl/IO-Interface"
        "dev-perl/IO-SessionData"
        "dev-perl/IO-Socket-INET6"
        "dev-perl/IO-Socket-Multicast"
        "dev-perl/IO-Socket-SSL"
        "dev-perl/IO-String"
        "dev-perl/IO-stringy"
        "dev-perl/IO-TieCombine"
        "dev-perl/IO-Tty"
        "dev-perl/IPC-Run"
        "dev-perl/IPC-System-Simple"
        "dev-perl/Jcode"
        "dev-perl/JSON"
        "dev-perl/JSON-Any"
        "dev-perl/JSON-MaybeXS"
        "dev-perl/JSON-XS"
        "dev-perl/Lexical-Persistence"
        "dev-perl/Lexical-SealRequireHints"
        "dev-perl/libintl-perl"
        "dev-perl/libwww-perl"
        "dev-perl/libxml-perl"
        "dev-perl/List-MoreUtils"
        "dev-perl/List-MoreUtils-XS"
        "dev-perl/Locale-gettext"
        "dev-perl/Locale-Maketext-Lexicon"
        "dev-perl/Log-Agent"
        "dev-perl/Log-Dispatch"
        "dev-perl/Log-Dispatch-Array"
        "dev-perl/Log-Dispatchouli"
        "dev-perl/Log-Log4perl"
        "dev-perl/Log-Message"
        "dev-perl/Log-Message-Simple"
        "dev-perl/LWP-MediaTypes"
        "dev-perl/LWP-Protocol-https"
        "dev-perl/Mail-DKIM"
        "dev-perl/Mail-POP3Client"
        "dev-perl/Mail-SPF"
        "dev-perl/MailTools"
        "dev-perl/Math-Base36"
        "dev-perl/Math-Round"
        "dev-perl/MIME-Lite"
        "dev-perl/MIME-tools"
        "dev-perl/MIME-Types"
        "dev-perl/Mixin-Linewise"
        "dev-perl/Module-Build"
        "dev-perl/Module-Build-Tiny"
        "dev-perl/Module-Compile"
        "dev-perl/Module-Find"
        "dev-perl/Module-Implementation"
        "dev-perl/Module-Path"
        "dev-perl/Module-Pluggable"
        "dev-perl/Module-Refresh"
        "dev-perl/Module-Runtime"
        "dev-perl/Module-Runtime-Conflicts"
        "dev-perl/Moo"
        "dev-perl/Moose"
        "dev-perl/MooseX-Getopt"
        "dev-perl/MooseX-LazyRequire"
        "dev-perl/MooseX-Object-Pluggable"
        "dev-perl/MooseX-OneArgNew"
        "dev-perl/MooseX-Role-Parameterized"
        "dev-perl/MooseX-SetOnce"
        "dev-perl/MooseX-Types"
        "dev-perl/MooseX-Types-Perl"
        "dev-perl/Mozilla-CA"
        "dev-perl/MRO-Compat"
        "dev-perl/multidimensional"
        "dev-perl/namespace-autoclean"
        "dev-perl/namespace-clean"
        "dev-perl/NetAddr-IP"
        "dev-perl/Net-CIDR-Lite"
        "dev-perl/Net-Daemon"
        "dev-perl/Net-DBus"
        "dev-perl/Net-DNS"
        "dev-perl/Net-DNS-Resolver-Programmable"
        "dev-perl/Net-DNS-SEC"
        "dev-perl/Net-HTTP"
        "dev-perl/Net-IP"
        "dev-perl/Net-LibIDN"
        "dev-perl/Net-Patricia"
        "dev-perl/Net-SMTP-SSL"
        "dev-perl/Net-SNMP"
        "dev-perl/Net-SSLeay"
        "dev-perl/Number-Compare"
        "dev-perl/OLE-StorageLite"
        "dev-perl/OpenGL"
        "dev-perl/Package-Constants"
        "dev-perl/Package-DeprecationManager"
        "dev-perl/Package-Stash"
        "dev-perl/Package-Stash-XS"
        "dev-perl/Package-Variant"
        "dev-perl/PadWalker"
        "dev-perl/Pango"
        "dev-perl/Params-Util"
        "dev-perl/Params-Validate"
        "dev-perl/Parse-RecDescent"
        "dev-perl/Path-Class"
        "dev-perl/Path-Tiny"
        "dev-perl/PDF-API2"
        "dev-perl/PDL"
        "dev-perl/Pegex"
        "dev-perl/PerlIO-gzip"
        "dev-perl/PerlIO-Layers"
        "dev-perl/PerlIO-utf8_strict"
        "dev-perl/perl-ldap"
        "dev-perl/Perl-PrereqScanner"
        "dev-perl/Perl-Tidy"
        "dev-perl/PGPLOT"
        "dev-perl/PHP-Serialization"
        "dev-perl/PlRPC"
        "dev-perl/Pod-Eventual"
        "dev-perl/Pod-LaTeX"
        "dev-perl/PPI"
        "dev-perl/Proc-ProcessTable"
        "dev-perl/Ref-Util"
        "dev-perl/Regexp-Common"
        "dev-perl/Role-HasMessage"
        "dev-perl/Role-Identifiable"
        "dev-perl/Role-Tiny"
        "dev-perl/Scalar-Properties"
        "dev-perl/Scope-Guard"
        "dev-perl/SGMLSpm"
        "dev-perl/Shell-EnvImporter"
        "dev-perl/SOAP-Lite"
        "dev-perl/SOAP-WSDL"
        "dev-perl/Socket6"
        "dev-perl/Software-License"
        "dev-perl/Specio"
        "dev-perl/Spreadsheet-ParseExcel"
        "dev-perl/SQL-Abstract"
        "dev-perl/SQL-Abstract-Limit"
        "dev-perl/SQL-Translator"
        "dev-perl/strictures"
        "dev-perl/String-Errf"
        "dev-perl/String-Flogger"
        "dev-perl/String-Formatter"
        "dev-perl/String-RewritePrefix"
        "dev-perl/String-ShellQuote"
        "dev-perl/Sub-Exporter"
        "dev-perl/Sub-Exporter-ForMethods"
        "dev-perl/Sub-Exporter-GlobExporter"
        "dev-perl/Sub-Exporter-Progressive"
        "dev-perl/Sub-Identify"
        "dev-perl/Sub-Install"
        "dev-perl/Sub-Name"
        "dev-perl/Sub-Quote"
        "dev-perl/Sub-Uplevel"
        "dev-perl/SVG"
        "dev-perl/Switch"
        "dev-perl/Sys-CPU"
        "dev-perl/Sys-MemInfo"
        "dev-perl/Sys-Mmap"
        "dev-perl/Sys-SigAction"
        "dev-perl/Sys-Virt"
        "dev-perl/Task-Weaken"
        "dev-perl/Template-Toolkit"
        "dev-perl/Template-XML"
        "dev-perl/Term-Encoding"
        "dev-perl/TermReadKey"
        "dev-perl/Term-ReadLine-Gnu"
        "dev-perl/Term-ReadLine-Perl"
        "dev-perl/Term-UI"
        "dev-perl/Test-Deep"
        "dev-perl/Test-Exception"
        "dev-perl/Test-Fatal"
        "dev-perl/Test-Warn"
        "dev-perl/Text-Autoformat"
        "dev-perl/Text-CharWidth"
        "dev-perl/Text-CSV_XS"
        "dev-perl/Text-Glob"
        "dev-perl/Text-Iconv"
        "dev-perl/Text-Reform"
        "dev-perl/Text-Template"
        "dev-perl/Text-Unidecode"
        "dev-perl/Text-WrapI18N"
        "dev-perl/Throwable"
        "dev-perl/Tie-IxHash"
        "dev-perl/TimeDate"
        "dev-perl/Time-Piece-MySQL"
        "dev-perl/Tk"
        "dev-perl/Tree-DAG_Node"
        "dev-perl/Try-Tiny"
        "dev-perl/Types-Serialiser"
        "dev-perl/Unicode-EastAsianWidth"
        "dev-perl/Unicode-Map"
        "dev-perl/Unicode-UTF8"
        "dev-perl/UNIVERSAL-moniker"
        "dev-perl/URI"
        "dev-perl/URI-Encode"
        "dev-perl/URI-Fetch"
        "dev-perl/URI-Find"
        "dev-perl/User-Identity"
        "dev-perl/Variable-Magic"
        "dev-perl/WWW-Mechanize"
        "dev-perl/WWW-Pastebin-PastebinCom-Create"
        "dev-perl/WWW-RobotRules"
        "dev-perl/X11-Protocol"
        "dev-perl/XML-DOM"
        "dev-perl/XML-Fast"
        "dev-perl/XML-Filter-BufferText"
        "dev-perl/XML-Handler-YAWriter"
        "dev-perl/XML-LibXML"
        "dev-perl/XML-NamespaceSupport"
        "dev-perl/XML-Parser"
        "dev-perl/XML-RegExp"
        "dev-perl/XML-RSS"
        "dev-perl/XML-SAX"
        "dev-perl/XML-SAX-Base"
        "dev-perl/XML-SAX-Expat"
        "dev-perl/XML-SAX-Writer"
        "dev-perl/XML-Simple"
        "dev-perl/XML-Twig"
        "dev-perl/XML-Writer"
        "dev-perl/XML-XPath"
        "dev-perl/YAML"
        "dev-perl/YAML-Syck"
        "dev-perl/YAML-Tiny"

      )

      for ((i = 0 ; i < ${#stable_perl_virtuals[@]} ; i++)) ; do
        echo -en "# Force stable\n${stable_perl_virtuals[${i}]} -~amd64\n\n" >> \
          ${build_arch}/package.keywords/00-sabayon.package.keywords
      done

      # TODO: it seems thata PMS documentation doesn't describe use of package.env
      #       file. I move for now this under /etc/portage/
      if [ ! -d /etc/portage/package.env ] ; then
        mkdir -p /etc/portage/package.env || return 1
      fi

      if [ ! -e /etc/portage/package.env/00-sabayon.package.env ] ; then
        ln -s ${build_arch}/package.env.${SABAYON_ARCH} \
          /etc/portage/package.env/00-sabayon.package.env || return 1
      fi

      ln -s ${build_arch}/profile/virtuals .

      # Currently PMS specification (targets/profiles) doesn't support syntax with ::repos
      # I will create a link on /etc/portage
      if [ ! -f /etc/portage/package.mask/00-sabayon.package.mask ] ; then
        ln -s ${build_arch}/package.mask/00-sabayon.package.mask \
        /etc/portage/package.mask/00-sabayon.package.mask
      fi

      if [ ! -d /etc/portage/package.use.mask ] ; then
        mkdir -p /etc/portage/package.use.mask || return 1
      fi
      if [ ! -e /etc/portage/package.use.mask/00-sabayon.mask ] ; then
        ln -s ${build_arch}/profile/package.use.mask/00-sabayon.mask \
          /etc/portage/package.use.mask/00-sabayon.mask || return 1
      fi

      if [ ! -d /etc/portage/package.unmask ] ; then
        mkdir -p /etc/portage/package.unmask || return 1
      fi
      if [ ! -e /etc/portage/package.unmask/00-sabayon.package.unmask ] ; then
        ln -s ${build_arch}/package.unmask/00-sabayon.package.unmask \
          /etc/portage/package.unmask/00-sabayon.package.unmask
      fi
      if [ ! -e /etc/portage/package.license ] ; then
        ln -s ${build_arch}/package.license /etc/portage/package.license
      fi

      # TODO: Check if env must be moved to /etc/portage
      if [ ! -e /etc/portage/env ] ; then
        ln -s ${build_arch}/env /etc/portage/env || return 1
      fi

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

  echo "Complete creation of targetdir ${targetdir}."

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


sabayon_config_portage_empty () {

  local only_creation_file=${1:-0}
  local exclude_profiles=${2:-0}
  local create_licence_accept="${3:-0}"
  local additional_opts=${4}
  local profiles_dirs=""

  # Maintains only licenses directory
  #   ! -name '*profiles' \
    # Metadata is needed to avoid this warning:
  #!!! Repository 'x-portage' is missing masters attribute in '/usr/portage/metadata/layout.conf'
  #!!! Set 'masters = gentoo' in this file for future compatibility

  if [ ${only_creation_file} -eq 0 ] ; then

    if [ ${exclude_profiles} -eq 1 ] ; then
      profiles_dirs="! -name '*profiles' -name '*targets'"
    fi

    local rmdirs=$(find ${PORTDIR} -maxdepth 1 -type d \
      ! -name '*metadata' ${profiles_dirs} ${additional_opts} \
      ! -path ${PORTDIR} ! -name '*licenses')

    for i in ${rmdirs} ; do
      echo "Removing dir ${i} ..."
      rm -rf ${i}
    done

  fi

  if [ ${create_licence_accept} -eq 1 ] ; then
    # Accept all licenses
    ls ${PORTDIR}/licenses -1 | xargs -0 > /etc/entropy/packages/license.accept || return 1
  fi

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

sabayon_create_server_repofile () {

  local community_mode=${1:-disable}
  local rss_base_url="${2:-http://packages.sabayon.org/?quicksearch=}"
  local site_url="${3:-http://www.sabayon.org}"

  local repos="${SABAYON_REPOS_NAME}"
  repos="${repos}|${SABAYON_REPOS_DESC}"
  repos="${repos}|${SABAYON_REPOS_PROTO}://${SABAYON_REPOS_PATH}/${SABAYON_REPOS_NAME}"

  echo "community-mode = ${community_mode}
default-repository = ${SABAYON_REPOS_NAME}
weak-package-files = disable
database-format = bz2
rss-feed = enable
changelog = enable
rss-name = packages.rss
rss-base-url = ${rss_base_url}
rss-website-url = ${site_url}
max-rss-entries = 10000
rss-light-name = updates.rss
managing-editor =
broken-reverse-deps = enable
repository = ${repos}
" > /etc/entropy/server.conf || return 1

  return 0
}

sabayon_create_repofile () {

  local enable=${1:-enable}
  local name=${2:-${SABAYON_REPOS_NAME}}
  local desc=${3:-${SABAYON_REPOS_DESC}}
  local proto=${4:-${SABAYON_REPOS_PROTO}}
  local path=${5:-${SABAYON_REPOS_PATH}}
  local validate_cert=${6:-${SABAYON_REPOS_VALIDATECERT}}
  local basic_auth_user=${7:-${SABAYON_REPOS_USER}}
  local basic_auth_pwd=${8:-${SABAYON_REPOS_PWD}}
  local https_validate_cert=""
  local basic_auth=""

  if [ -n "${validate_cert}" ] ; then
    https_validate_cert="https_validate_cert = ${validate_cert}"
  fi

  if [[ -n "${basic_auth_user}" && -n "${basic_auth_pwd}" ]] ; then
    basic_auth="username = ${basic_auth_user}
password = ${basic_auth_pwd}"
  fi

  echo "[${name}]
desc = ${desc}
repo = ${proto}://${path}${name}/
pkg = ${proto}://${path}${name}/
enable = ${enable}
${https_validate_cert}
${basic_auth}
" > /etc/entropy/repositories.conf.d/entropy_${name} || return 1

  return 0
}

# vim: ts=2 sw=2 expandtab
