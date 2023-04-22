Bash Alias Synchronizer
===

# How to install
1. Fork this repository if you want to have your aliases, not mine.
2. Clone repository:
   - via SSH:
     ```bash
     git clone git@github.com:<YOUR-USERNAME>/bash-alias-sync.git
     ```
   - via HTTPS:
     ```bash
     git clone https://github.com/<YOUR-USERNAME>/bash-alias-sync.git
     ```
3. Install synchronization of aliases once:
   ```bash
   cd ./bash-alias-sync
   chmod +x ./install.sh # Required for MacOS.
   ./install.sh
   ```
# Folder structure
```bash
.
├── .bash_aliases # Don't touch this if you are not sure.
├── README.md
├── common # Aliases for all following platforms.
│   ├── .bash_aliases # Aliases without arguments.
│   ├── .git_aliases # Aliases for Git.
│   ├── .bash_constants # Exported constants.
│   ├── .bash_handlers # Input handlers.
│   ├── .git_aliases # Aliases for Git.
│   └── .bash_functions # Aliases with arguments.
├── linux # Aliases for Linux-only.
│   ├── .bash_aliases
│   ├── .git_aliases
│   ├── .bash_constants
│   ├── .bash_handlers
│   └── .bash_functions
├── macos # Aliases for MacOS-only.
│   ├── .bash_aliases
│   ├── .git_aliases
│   ├── .bash_constants
│   ├── .bash_handlers
│   └── .bash_functions
├── mingw # Aliases for MINGW (e.g. bundled with Git Bash for Windows).
│   ├── .bash_aliases
│   ├── .git_aliases
│   ├── .bash_constants
│   ├── .bash_handlers
│   └── .bash_functions
├── unix # Aliases for all UNIX-like systems.
│   ├── .bash_aliases
│   ├── .git_aliases
│   ├── .bash_constants
│   ├── .bash_handlers
│   └── .bash_functions
└── wsl # Aliases for Windows Subsystem Linux.
    ├── .bash_aliases
    ├── .git_aliases
    ├── .bash_constants
    ├── .bash_handlers
    └── .bash_functions
```

# How to modify aliases
1. Open corresponding `.bash_aliases` or `.bash_functions` or `.git_aliases` with your favorite text editor.
2. Modify.
3. Save file.
4. Update aliases in current session:
   ```bash
   alias-update
   ```

# How to sync aliases
1. Shortcut for pushing aliases to your repository:
   ```bash
   alias-push
   ```
2. Shortcut for pulling aliases from your repository:
   ```bash
   alias-pull
   ```
