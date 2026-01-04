import sys
import subprocess
import argparse
import shlex
from pathlib import Path
from .core import error_exit, print_success, print_warning, print_announce, print_choice, git_validate_repo, ERROR, WARNING, CHOICE, SUCCESS, NC

def _run_git(args, error_msg="Git command failed"):
    try:
        # Check for shlex usage if we print
        # print("Exec:", " ".join(shlex.quote(a) for a in ["git"] + args))
        subprocess.run(["git"] + args, check=True)
        return True
    except subprocess.CalledProcessError:
        error_exit(error_msg)

def cmd_re(args):
    git_validate_repo()
    
    if len(args) == 0:
        print_announce("gsc re need only 1 opt.")
        return

    parser = argparse.ArgumentParser(prog="gsc re", description="Git RE operations")
    parser.add_argument("-n", metavar="msg", help="rename the last commit")
    parser.add_argument("-H", action="store_true", help="reset hard")
    parser.add_argument("-S", action="store_true", help="reset soft")
    
    parsed, unknown = parser.parse_known_args(args)
    
    if parsed.n:
        _run_git(["commit", "--amend", "-m", parsed.n], "Failed to rename commit")
    elif parsed.H:
        _run_git(["reset", "--hard"], "Failed to reset hard")
    elif parsed.S:
        _run_git(["reset", "--soft", "HEAD~1"], "Failed to reset soft")

def cmd_sync(args):
    git_validate_repo()
    _run_git(["fetch", "--all", "--prune"], "Failed to fetch")
    
    print(f"{CHOICE} Do you want to pull now?[y/N]: ", end='')
    try:
        ans = input()
    except EOFError:
        ans = 'n'
        
    if ans.lower() == 'y':
        _run_git(["pull"], "Failed to pull")
        print_success("Synced with remote")

def cmd_stash(args):
    parser = argparse.ArgumentParser(prog="gsc stash")
    parser.add_argument("-s", metavar="msg", help="stash save")
    parser.add_argument("-p", action="store_true", help="stash pop")
    
    parsed, unknown = parser.parse_known_args(args)
    
    if parsed.s:
        _run_git(["stash", "save", parsed.s], "Failed to stash save")
    elif parsed.p:
        _run_git(["stash", "pop"], "Failed to stash pop")
    else:
        print(f"{CHOICE} select option to stash")
        print("1) Push")
        print("2) Pop")
        try:
             sel = input("Select: ")
        except:
             return
             
        if sel == '1' or sel.lower() == 'push':
            msg = input(f"{ANNOUNCE} Type message(s): ")
            _run_git(["stash", "save", msg], "Failed to stash save")
        elif sel == '2' or sel.lower() == 'pop':
            _run_git(["stash", "pop"], "Failed to stash pop")

def cmd_branch(args):
    git_validate_repo()
    
    parser = argparse.ArgumentParser(prog="gsc branch")
    parser.add_argument("-c", metavar="name", help="create branch")
    parser.add_argument("-d", metavar="name", help="delete branch")
    parser.add_argument("-D", action="store_true", help="delete merged branches")
    parser.add_argument("-l", action="store_true", help="list branches")
    parser.add_argument("-m", metavar="branch", help="merge branch")
    
    parsed, unknown = parser.parse_known_args(args)

    if parsed.c:
        _run_git(["checkout", "-b", parsed.c], "Failed to create branch")
    elif parsed.d:
        _run_git(["branch", "-d", parsed.d], "Failed to delete branch")
    elif parsed.D:
        p1 = subprocess.Popen(["git", "branch", "--merged"], stdout=subprocess.PIPE)
        p2 = subprocess.Popen(["grep", "-v", "\\*"], stdin=p1.stdout, stdout=subprocess.PIPE)
        out, _ = p2.communicate()
        if out:
             branches = out.decode().strip().split('\n')
             for b in branches:
                 b = b.strip()
                 if b:
                     subprocess.run(["git", "branch", "-d", b])
    elif parsed.l:
        _run_git(["branch", "-a"], "Failed to list branches")
    elif parsed.m:
         _run_git(["merge", parsed.m], "Failed to merge")
    else:
         _run_git(["branch", "-a"], "Failed to list branches")

def cmd_tag(args):
    parser = argparse.ArgumentParser(prog="gsc tag")
    parser.add_argument("-c", metavar="name", help="create tag")
    parser.add_argument("-d", metavar="name", help="delete tag")
    parser.add_argument("-l", action="store_true", help="list tags")
    
    parsed, unknown = parser.parse_known_args(args)
    
    if parsed.c:
        _run_git(["tag", parsed.c], "Failed to create tag")
    elif parsed.d:
        _run_git(["tag", "-d", parsed.d], "Failed to delete tag")
    else:
        _run_git(["tag", "-l"], "Failed to list tags")
