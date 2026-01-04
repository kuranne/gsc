import sys
import os
import subprocess

#--- Color ---#
RED = '\033[0;31m'
PINK = '\033[95m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
CYAN = '\033[0;36m'
BLUE = '\033[34m'
NC = '\033[0m'

#--- perror ---#
ERROR = f"{RED}ERROR:{NC}"
WARNING = f"{YELLOW}WARNING:{NC}"
SUCCESS = f"{GREEN}SUCCESS:{NC}"
CHOICE = f"{BLUE}CHOICE:{NC}"
USAGE = f"{BLUE}USAGE:{NC}"
HINT = f"{BLUE}HINT:{NC}"
ANNOUNCE = f"{CYAN}ANNOUNCE:{NC}"
DETECTED = f"{CYAN}DETECTED:{NC}"

def error_exit(msg=None):
    if msg:
        print(f"{ERROR} {msg}")
    sys.exit(1)

def print_success(msg):
    print(f"{SUCCESS} {msg}")

def print_warning(msg):
    print(f"{WARNING} {msg}")

def print_announce(msg):
    print(f"{ANNOUNCE} {msg}")

def print_choice(msg):
    print(f"{CHOICE} {msg}")

def normal_exit():
    sys.exit(0)

#--- Validation ---#
from pathlib import Path

def git_validate_repo():
    if not Path(".git").is_dir():
        # Check parents?
        # git rev-parse --is-inside-work-tree is safer but strict checking of .git dir works for simple cases.
        # But for submodule or worktree it might be different. 
        # For now, stick to is_dir(".git") or check current directory relative to git root.
        # Let's use a smarter check: git status
        try:
             subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
             error_exit("Not a git repository (or any of the parent directories)")

def git_validate_username(username):
    if not username:
        error_exit("Username cannot be empty")
    return True

def git_validate_url(url):
    if not url:
        error_exit("URL cannot be empty")
    return True

def git_validate_commit_message(msg):
    if not msg:
        error_exit("Commit message cannot be empty")
    return True

def git_validate_not_found_git():
    try:
        subprocess.run(["git", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except FileNotFoundError:
        error_exit("git command not found")
