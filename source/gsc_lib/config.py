import os
import sys
from pathlib import Path
from .core import error_exit, WARNING, NC

# Try to import toml
try:
    import toml
except ImportError:
    # Fallback or error? User requested "use toml", so we should error if missing.
    # But to be nice, we can try tomllib if python 3.11+
    try:
        import tomllib as toml
    except ImportError:
        print(f"{WARNING} 'toml' library not found. Please pip install toml{NC}")
        sys.exit(1)

def load_config():
    """
    Locates and parses the gsc.toml file.
    Returns a dictionary of accounts and other config settings.
    """
    home = Path.home()
    pwd = Path.cwd()
    
    config_path = pwd / "gsc.toml"
    
    if not config_path.exists():
        # Look for template in library
        current_file = Path(__file__).resolve()
        project_root = current_file.parent.parent.parent
        template_path = project_root / "gsc.toml" # Try root first?
        
        # Or look in kurannelib location if we want to support legacy structure logic?
        # But we are rewriting. Let's look for a bundled default.
        # Assuming we might ship a default.
        if template_path.exists():
             config_path = template_path
        else:
            home_config = home / "gsc.toml"
            if home_config.exists():
                config_path = home_config
    
    accounts = {}
    
    if config_path.exists():
        try:
            data = toml.load(config_path)
            # Structure: [gitAccounts] user = email ...
            if "gitAccounts" in data:
                accounts = data["gitAccounts"]
        except Exception as e:
            print(f"{WARNING} Failed to parse {config_path}: {e}{NC}")
            
    backup_dir = home / ".local" / "share" / "gsc" / "backup"

    return {
        "gitAccounts": accounts, 
        "configPath": str(config_path),
        "backupDir": str(backup_dir)
    }
