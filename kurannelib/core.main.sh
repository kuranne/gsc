RED='\033[0;31m'
PINK='\033[95m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[34m'
NC='\033[0m'

ERROR="${RED}ERROR:${NC}"
WARNING="${YELLOW}WARNING:${NC}"
SUCCESS="${GREEN}SUCCESS:${NC}"
CHOICE="${BLUE}CHOICE:${NC}"
USAGE="${BLUE}USAGE:${NC}"
HINT="${BLUE}HINT:${NC}"
ANNOUNCE="${CYAN}ANNOUNCE:${NC}"
DETECTED="${CYAN}DETECTED:${NC}"

# load gsc.config
[[ -f "${nowDir}/kurannelib/gsc.config" ]] || { echo "\033[0;31mERROR:\033[0m not found gsc.config in $nowDir/kurannelib"; exit 1 ; }

if [ -f "${hereDir}/.gsc.config" ]; then
    source "${hereDir}/.gsc.config"
elif [ -f "${nowDir}/kurannelib/gsc.config" ]; then
    cp "${nowDir}/kurannelib/gsc.config" "${hereDir}/.gsc.config" || errorExit
    source "${hereDir}/.gsc.config"
else
    echo "${ERROR} Can't load gsc.config" || errorExit
fi