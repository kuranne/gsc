#!/usr/bin/env python3
import sys
import argparse
from pathlib import Path

# Add clean path import
current_dir = Path(__file__).resolve().parent
sys.path.append(str(current_dir))

from gsc_lib.core import error_exit, normal_exit, print_warning, USAGE, WARNING
from gsc_lib.config import load_config
from gsc_lib.ssh_ops import remove_ssh_key, create_ssh_key, add_to_ssh_agent

def main():
    parser = argparse.ArgumentParser(prog="sshsc")
    parser.add_argument("-r", action="store_true", help="remove ssh key")
    parser.add_argument("-C", action="store_true", help="create ssh key")
    parser.add_argument("accounts", nargs="*", help="account names")
    
    args = parser.parse_args()
    
    config = load_config()
    git_accounts = config["gitAccounts"]
    
    selected_accounts = []
    for arg in args.accounts:
        if arg in git_accounts:
            selected_accounts.append(arg)
        else:
             print(f"{WARNING} {arg} is not a valid account!", file=sys.stderr)
             
    if args.r:
        remove_ssh_key(git_accounts, selected_accounts if selected_accounts else None)
        
    if args.C:
        create_ssh_key(git_accounts, selected_accounts)
        
    add_to_ssh_agent(git_accounts, selected_accounts)
    normal_exit()

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        normal_exit()
