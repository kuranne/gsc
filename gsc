#!/bin/zsh

nowDir="$(cd -- "$(dirname -- "${(%):-%x}")" && pwd)"
hereDir="$(pwd)"

#=== Import ===#
for COREUTIL in "$nowDir/kurannelib/"core.*.sh; do
    source "$COREUTIL" || { echo "\033[0;31mERROR:\033[0m Can't load $COREUTIL"; exit 1 ; }
done
for PATHforgsc in "$nowDir/kurannelib/gsc/"gsc.*.sh; do
    source "$PATHforgsc" || { echo "\033[0;31mERROR:\033[0m Can't load $PATHforgsc"; exit 1 ; }
done

#--- gsc.config ---#
[[ -f "${nowDir}/kurannelib/gsc.config" ]] || { echo "\033[0;31mERROR:\033[0m not found gsc.config in $nowDir/kurannelib"; exit 1 ; }
if [ -f "${hereDir}/.gsc.config" ]; then
    source "${hereDir}/.gsc.config"
elif [ -f "${nowDir}/kurannelib/gsc.config" ]; then
    cp "${nowDir}/kurannelib/gsc.config" "${hereDir}/.gsc.config" || errorExit
    source "${hereDir}/.gsc.config"
else
    echo "\033[0;31mError:\033[0m Can't load gsc.config" || errorExit
fi

#=== Start ===#
gitValidateNotFoundGit || errorExit
main "$@"