#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

sabayon_overlay_process_ebuild () {

  local overlay=${1}
  local category=${2}
  local package=${3}
  local ebuild=${4}
  local result=""

  local pv=${ebuild/.ebuild/}
  local version=${pv/${package}-/}

  if [ ${version} == "9999" ] ; then
    echo -ne "SKIP PACKAGE: ${category}/${pv}\n"
  else
    echo -ne "CHECK PACKAGE: ${category}/${pv} ... "

    DISTDIR=${SABAYON_TMP_DISTDIR}
    ACCEPT_KEYWORDS="~* *"

    export DISTDIR ACCEPT_KEYWORDS

    local out=$(emerge --fetchonly --nodeps =${category}/${pv}::${overlay} 2>&1)

    if [ ${SABAYON_DEBUG} -eq 1 ] ; then
      echo -e "\n${out}"
    fi

    result=$?
    if [[ "${out}" == *"VERIFY FAILED"* ]] ; then
      result=1
    fi
    if [[ "${out}" == *"!!! Couldn't download"* ]] ; then
      result=1
    fi

    if [ $result -eq 0 ] ; then

      echo "OK"
      sabayon_overlay_write_report "${overlay}" "PACKAGE ${category}/${pv}: OK"
    else
      echo "KO"
      sabayon_overlay_write_report "${overlay}" "PACKAGE ${category}/${pv}: KO\n${out}\n\n"
    fi
  fi

  return 0
}

sabayon_overlay_write_report () {

  local overlay=${1}
  local msg=${2}
  local date=$(date +%Y%m%d-%H:%M:%S)

  echo -e "${date} - ${msg}\n" >> ${SABAYON_CHECK_RESULTDIR}/${overlay}_report.log || return 1

  return 0
}


sabayon_overlay_check_uris () {

  local overlay=${1}
  local overlaydir=${2:-/var/lib/layman}
  local category=""

  local dir=${overlaydir}/${overlay}/

  local categories=$(find ${dir} -mindepth 1 -maxdepth 1   -not -path "*/.git*" -and -name "*-*")

  echo -e "For overlay ${overlay} found categories:\n${categories}\n"

  for catpath in ${categories} ; do
    category=$(basename ${catpath})
    echo "START Processing ebuild of category ${category}..."

    sabayon_overlay_write_report "${overlay}" "START CATEGORY: ${category}"

    local packages=$(find ${dir}${category} -mindepth 1 -maxdepth 1)

    # echo "PACKAGES to process: ${packages}"

    for pkgpath in ${packages} ; do

      local package=$(basename ${pkgpath})
      local ebuilds=$(find ${dir}${category}/${package}  -name "*.ebuild")

      sabayon_overlay_write_report "${overlay}" "START PACKAGE: ${category}/${package}"
      # echo "EBUILD of package ${package} to process: ${ebuilds}"

      for epath in ${ebuilds} ; do
        local ebuild=$(basename ${epath})
        sabayon_overlay_process_ebuild "${overlay}" "${category}" "${package}" "${ebuild}"
      done

      sabayon_overlay_write_report "${overlay}" "END PACKAGE: ${category}/${package}"
    done

    sabayon_overlay_write_report "${overlay}" "END CATEGORY: ${category}"

    echo "END Processing of ebuild of category ${category}."
  done

  echo "Claen temporary DISTDIR ${SABAYON_TMP_DISTDIR}"
  rm ${SABAYON_TMP_DISTDIR}/*

  return 0
}


# vim: ts=2 sw=2 expandtab
