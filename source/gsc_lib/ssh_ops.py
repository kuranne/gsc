import subprocess
import sys
import shlex
from pathlib import Path
from .core import error_exit, print_success, print_warning, print_choice, NC, WARNING, CHOICE

def remove_ssh_key(git_accounts, selected_accounts=None):
    home = Path.home()
    
    try:
        result = subprocess.run(["ssh-add", "-l"], capture_output=True, text=True)
        current_keys = result.stdout
    except Exception:
        current_keys = ""

    if not selected_accounts:
        for acct, email in git_accounts.items():
            if email in current_keys:
                key_path = home / ".ssh" / f"id_rsa_{acct}"
                subprocess.run(["ssh-add", "-d", str(key_path)], stderr=subprocess.DEVNULL)
    else:
        for acct in selected_accounts:
            if acct not in git_accounts:
                 print_warning(f"{acct} is not a valid account!")
                 continue
            email = git_accounts[acct]
            if email in current_keys:
                key_path = home / ".ssh" / f"id_rsa_{acct}"
                subprocess.run(["ssh-add", "-d", str(key_path)], stderr=subprocess.DEVNULL)
                print_success(f"Removed SSH key for {acct}")

def create_ssh_key(git_accounts, selected_accounts):
    home = Path.home()
    ssh_dir = home / ".ssh"
    
    for acct in selected_accounts:
        if acct not in git_accounts:
             continue
        email = git_accounts[acct]
        key_file = ssh_dir / f"id_rsa_{acct}"
        
        # Using list args avoids shell injection, so shlex.quote is not needed for execution
        # But if we were to print the command for debug:
        cmd = [
            "ssh-keygen", "-t", "rsa", "-b", "4096", 
            "-C", email, "-f", str(key_file)
        ]
        
        # Example shlex usage if we were constructing a shell string
        # safe_cmd = " ".join(shlex.quote(arg) for arg in cmd)
        # print(f"Running: {safe_cmd}")
        
        subprocess.run(cmd)
        
        pub_file = key_file.with_suffix(".pub")
        if pub_file.exists():
            print(pub_file.read_text())

def add_to_ssh_agent(git_accounts, selected_accounts):
    home = Path.home()
    ssh_dir = home / ".ssh"
    
    for acct in selected_accounts:
        if acct not in git_accounts:
            continue
            
        key_file = ssh_dir / f"id_rsa_{acct}"
        
        if key_file.exists():
            subprocess.run(["ssh-add", str(key_file)], stderr=subprocess.DEVNULL)
        else:
            print_warning(f"Can't find {key_file.name} on your ~/.ssh do u want to create new one?")
            print(f"{CHOICE} [Y/y] for Yes, else for No: ", end='')
            try:
                ans = input()
            except EOFError:
                ans = "n"
            
            if ans.lower() == 'y':
                create_ssh_key(git_accounts, [acct])
                if key_file.exists():
                    subprocess.run(["ssh-add", str(key_file)], stderr=subprocess.DEVNULL)
            else:
                print("Didn't do anything.")
                sys.exit(0)
