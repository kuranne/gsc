#--- Color ---#
RED='\033[0;31m'
PINK='\033[95m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[34m'
NC='\033[0m'

#--- perror ---#
ERROR="${RED}ERROR:${NC}"
WARNING="${YELLOW}WARNING:${NC}"
SUCCESS="${GREEN}SUCCESS:${NC}"
CHOICE="${BLUE}CHOICE:${NC}"
USAGE="${BLUE}USAGE:${NC}"
HINT="${BLUE}HINT:${NC}"
ANNOUNCE="${CYAN}ANNOUNCE:${NC}"
DETECTED="${CYAN}DETECTED:${NC}"

#--- gsc.config ---#
[[ -f "${nowDir}/kurannelib/gsc.config" ]] || { echo "\033[0;31mERROR:\033[0m not found gsc.config in $nowDir/kurannelib"; exit 1 ; }

if [ -f "${hereDir}/.gsc.config" ]; then
    source "${hereDir}/.gsc.config"
elif [ -f "${nowDir}/kurannelib/gsc.config" ]; then
    cp "${nowDir}/kurannelib/gsc.config" "${hereDir}/.gsc.config" || errorExit
    source "${hereDir}/.gsc.config"
else
    echo "${ERROR} Can't load gsc.config" || errorExit
fi

#--- Help ---#
HELPCOMMAND="$USAGE gsc is from git script
Options:
  -A <account>  Switch to account
  -S           use SSH to authorize
  -C <url>      Clone repository  
  -I            Initialize repository
  -i            Create .gitignore
  -a            Add all files
  -c <message>  Commit with message
  -P            Pull
  -p            Push to origin
  -M            Delete merged branches except master/main/dev
  -B            List branches
  -b <name>     Create branch
  -d <name>     Delete branch
  -t <name>     Create tag
  -T <name>     Delete tag
  -R            List remotes
  -D            Show diff
  -l            Show log
  -s            Show status
  -u            Show now using account
  -h            Help

Additional commands:
  stash <msg>    Save stash
  stashpop       Pop stash
  blame <file>   Git blame
  sync           Fetch+pull+prune
  remove         remove .git and .gitignore
  reset         Hard reset

Examples:
  gsc -SA user -C https://github.com/user/repo.git
  gsc -A user -ac 'Initial commit' -p
  gsc -Iac 'First commit' -p 
  gsc -SuA user -C git@github.com:user/repo.git -ac 'Initial commit' -psl"
