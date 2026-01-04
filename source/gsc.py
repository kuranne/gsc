#!/usr/bin/env python3
import sys
import os
from pathlib import Path

# Add clean path import
current_dir = Path(__file__).resolve().parent
sys.path.append(str(current_dir))

from gsc_lib.core import error_exit, normal_exit
from gsc_lib.git_ops import git_operation
from gsc_lib import git_cmds

def main():
    if len(sys.argv) < 2:
        git_operation([])
        normal_exit()

    cmd = sys.argv[1]
    
    if hasattr(git_cmds, f"cmd_{cmd}"):
        func = getattr(git_cmds, f"cmd_{cmd}")
        func(sys.argv[2:])
    elif cmd == "help":
        print("Usage: gsc [subcommand] [options]")
        print("Subcommands: re, sync, stash, branch, tag")
        print("Options: -C, -A, -S, -I, ... (see gsc --help from argparse)")
    else:
        git_operation(sys.argv[1:])

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        normal_exit()
