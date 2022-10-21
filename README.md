Bash Alias Synchronizer
===

# How to install
1. Change directory to `$HOME`:
   ```bash
   cd ~
   ```
2. Fork this repository if you want to have your aliases, not mine.
3. Clone repository:
   - via SSH:
     ```bash
     git clone git@github.com:<YOUR-USERNAME>/bash-alias-sync.git
     ```
   - via HTTPS:
     ```bash
     git clone https://github.com/<YOUR-USERNAME>/bash-alias-sync.git
     ```
4. Update aliases in current session:
   - Linux/WSL/MacOS:
     ```bash
     . ~/.bashrc
     ```
   - MINGW64:
     ```bash
     . ~/.bash_profile
     ```
# Folder structure
```bash
.
├── .bash_aliases # Don't touch this.
├── README.md
├── common # Aliases for all following platforms.
│   ├── .bash_aliases # Aliases without arguments.
│   ├── .git_aliases # Aliases for Git.
│   └── .bash_functions # Aliases with arguments.
├── linux # Aliases for Linux-only.
│   ├── .bash_aliases
│   ├── .git_aliases
│   └── .bash_functions
├── macos # Aliases for MacOS-only.
│   ├── .bash_aliases
│   ├── .git_aliases
│   └── .bash_functions
├── mingw # Aliases for MINGW (e.g. Git Bash for Windows).
│   ├── .bash_aliases
│   ├── .git_aliases
│   └── .bash_functions
├── unix # Aliases for all UNIX-like systems.
│   ├── .bash_aliases
│   ├── .git_aliases
│   └── .bash_functions
└── wsl # Aliases for Windows Subsystem Linux.
    ├── .bash_aliases
    ├── .git_aliases
    └── .bash_functions
```

# How to modify aliases
1. Open corresponding `.bash_aliases` or `.bash_functions` with your favorite text editor.
2. Modify.
3. Save file.
4. Update aliases in current session.
   ```bash
   alias-update # Shortcut for updating aliases in current session.
   ```

# How to sync aliases
1. Shortcut for push aliases to your repository:
   ```bash
   alias-push
   ```
2. Shortcut for pull aliases from your repository:
   ```bash
   alias-pull
   alias-update # Update pulled aliases.
   ```
