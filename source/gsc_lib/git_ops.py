import sys
import subprocess
import argparse
import shlex
from pathlib import Path
from .core import error_exit, print_success, print_warning, print_choice, print_announce, DETECTED, NC, ERROR, WARNING, SUCCESS, CHOICE, git_validate_repo, git_validate_url, git_validate_commit_message
from .ssh_ops import remove_ssh_key, create_ssh_key, add_to_ssh_agent
from .config import load_config

def get_git_config(key):
    try:
        res = subprocess.run(["git", "config", key], capture_output=True, text=True)
        return res.stdout.strip()
    except:
        return ""

def switch_account(account_name, git_accounts, ssh_activate=False):
    if not account_name:
        error_exit("Username cannot be empty")
        
    if account_name in git_accounts:
        if Path(".git").is_dir():
            subprocess.run(["git", "config", "user.name", account_name])
            subprocess.run(["git", "config", "user.email", git_accounts[account_name]])
            
        if ssh_activate:
            remove_ssh_key(git_accounts)
            add_to_ssh_agent(git_accounts, [account_name])
            print_success(f"Switched to ssh account: {account_name}")
        else:
            print(f"{CHOICE} If you want to use key, must -S for SSH activate")
            print_success(f"Switched to non-ssh account: {account_name}")
            
        return account_name
    else:
        error_exit(f"Unknown account: {account_name}\nAvailable: {list(git_accounts.keys())}")

def show_account(current_account, ssh_activate, git_accounts):
    user_name = get_git_config("user.name")
    user_email = get_git_config("user.email")
    
    if user_name and user_email:
        print(f"Now using account: {user_name} <{user_email}>")
    else:
        print_warning("user.name and user.email didn't configured yet")
        
    if ssh_activate:
        print("SSH Agent keys loaded:")
        subprocess.run(["ssh-add", "-l"])

def git_clone(url, yes_skip):
    git_validate_url(url)
    repo_name = Path(url).stem # safely get name
    if (Path.cwd() / repo_name).exists():
        error_exit(f"Directory {repo_name} already exists")
    
    subprocess.run(["git", "clone", url], check=True)
    try:
        os.chdir(repo_name)
    except FileNotFoundError:
        error_exit("Failed to enter cloned directory")
        
    print_success(f"Cloned directory: {repo_name}")
    
    if not yes_skip:
        print(f"{CHOICE} pull?[y/N]: ", end='')
        try:
             ans = input()
        except:
             ans = 'n'
        if ans.lower() == 'y':
            subprocess.run(["git", "pull"])

def git_init(current_account, git_accounts):
    if Path(".git").is_dir():
        print(f"{DETECTED} Already initialized")
        return
        
    subprocess.run(["git", "init"], stdout=subprocess.DEVNULL, check=True)
    print(f"{SUCCESS} Init Successful")
    
    if current_account and current_account in git_accounts:
        subprocess.run(["git", "config", "user.name", current_account])
        subprocess.run(["git", "config", "user.email", git_accounts[current_account]])

def git_push(pull_first, yes_skip):
    git_validate_repo()
    
    remotes = subprocess.run(["git", "remote"], capture_output=True, text=True).stdout.strip().split()
    if not remotes:
         error_exit("No remote found")
         
    if len(remotes) > 1:
        print(f"{CHOICE} Multiple remotes found, using first one for now {remotes[0]}")
        remote = remotes[0]
    else:
        remote = remotes[0]
        
    current_branch = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True).stdout.strip()
    
    if not pull_first and not yes_skip:
        print(f"{WARNING} Want to pull before push?[y/N]: ", end='')
        try:
             ans = input()
        except:
             ans = 'n'
        if ans.lower() == 'y':
            subprocess.run(["git", "pull", remote, current_branch])
            
    if pull_first:
         subprocess.run(["git", "pull", remote, current_branch])
         
    subprocess.run(["git", "push", remote, current_branch], check=True)
    print_success(f"Pushed to {remote}/{current_branch}")

def git_operation(args):
    parser = argparse.ArgumentParser(prog="gsc", usage="gsc [options]")
    parser.add_argument("-C", metavar="url", help="clone repository")
    parser.add_argument("-A", metavar="username", help="switch account")
    parser.add_argument("-S", action="store_true", help="use ssh")
    parser.add_argument("-I", action="store_true", help="git init")
    parser.add_argument("-i", action="store_true", help="copy gitignore")
    parser.add_argument("-a", action="store_true", help="git add")
    parser.add_argument("-c", metavar="message", help="git commit")
    parser.add_argument("-p", action="store_true", help="git push")
    parser.add_argument("-P", action="store_true", help="git pull")
    parser.add_argument("-s", action="store_true", help="git status")
    parser.add_argument("-l", action="store_true", help="git log")
    parser.add_argument("-d", action="store_true", help="git diff")
    parser.add_argument("-b", action="store_true", help="git blame")
    parser.add_argument("-u", action="store_true", help="check current username")
    parser.add_argument("-y", action="store_true", help="skip confirmation")
    
    parsed = parser.parse_args(args)
    
    config = load_config()
    git_accounts = config["gitAccounts"]
    current_account = None

    if parsed.A:
        current_account = switch_account(parsed.A, git_accounts, parsed.S)
    
    if parsed.u:
        show_account(current_account, parsed.S, git_accounts)
        
    if parsed.C:
        git_clone(parsed.C, parsed.y)
        
    if parsed.I:
        git_init(current_account, git_accounts)

    if parsed.i:
         with open(".gitignore", "a") as f:
             f.write("\n.DS_Store\nThumbs.db\n.vscode/\n.git/\n")
         print_success(".gitignore created/updated")

    if parsed.a:
        git_validate_repo()
        subprocess.run(["git", "add", "."], check=True)
        print_success("Files added to staging")
        
    if parsed.c:
        git_validate_repo()
        status = subprocess.run(["git", "diff", "--cached", "--name-only"], capture_output=True, text=True).stdout
        if not status:
             subprocess.run(["git", "add", "."])
        subprocess.run(["git", "commit", "-m", parsed.c], check=True)
        print_success(f"Committed: {parsed.c}")
        
    if parsed.P:
        git_validate_repo()
        subprocess.run(["git", "pull"]) 
        
    if parsed.p:
        git_push(parsed.P, parsed.y)
        
    if parsed.s:
        git_validate_repo()
        subprocess.run(["git", "status"])
        
    if parsed.l:
        git_validate_repo()
        subprocess.run(["git", "log", "--oneline", "--graph", "--decorate", "-n", "10"])
        
    if parsed.d:
        git_validate_repo()
        subprocess.run(["git", "diff"])
        
    if parsed.b:
        git_validate_repo()
        print_warning("Blame file not specified in arguments")
