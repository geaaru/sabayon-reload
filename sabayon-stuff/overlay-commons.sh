#!/bin/bash
# Author: Geaaru, geaaru@gmail.com

sabayon_overlay_check_uris () {

  local overlay=${1}
  local resultsdir=${2:-/tmp/overlay_checks}
  local overlaydir=${3:-/var/lib/layman}

  local dir=${overlaydir}/${overlay}/

  local categories=$(find ${dir} -mindepth 1 -maxdepth 1   -not -path "*/.git*" -and -name "*-*")

  echo -e "For overlay ${overlay} found categories:\n${categories}\n"

  for category in ${categories} ; do
    echo "START Processing ebuild of category ${category}..."

    local ebuilds=$(find ${dir}/${category} -mindepth 3 -maxdepth 3   -not -path "*/.git*" -and -name "*.ebuild")

    echo "END Processing of ebuild of category ${category}."
  done


  echo "EBUILD to process: ${ebuilds}"



  return 0

}


# vim: ts=2 sw=2 expandtab
