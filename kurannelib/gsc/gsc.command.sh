#--- Help ---#
HELPCOMMAND="$USAGE gsc is from git script
Options:
  -A <account>    Switch to account
  -S              use SSH to authorize
  -C <url>        Clone repository  
  -I              Initialize repository
  -i              Create .gitignore
  -a              Add all files
  -c <message>    Commit with message
  -P              Pull
  -p              Push to origin
  -M              Delete merged branches except master/main/dev
  -B              List branches
  -b <name>       Create branch
  -d <name>       Delete branch
  -t <name>       Create tag
  -T <name>       Delete tag
  -R              List remotes
  -D              Show diff
  -l              Show log
  -s              Show status
  -u              Show now using account
  -h              Help

Additional commands:
  stash <msg>     Save stash
  stashpop        Pop stash
  blame <file>    Git blame
  sync            Fetch+pull+prune
  remove          remove .git and .gitignore
  reset           Hard reset
  restore         restore from .gscbackup
  remove-restore  remove backup

Examples:
  gsc -SA user -C https://github.com/user/repo.git
  gsc -A user -ac 'Initial commit' -p
  gsc -Iac 'First commit' -p 
  gsc -SuA user -C git@github.com:user/repo.git -ac 'Initial commit' -psl"

gscHelp() {
    echo -e $HELPCOMMAND
}