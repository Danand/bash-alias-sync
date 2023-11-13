# Bash Alias Synchronizer

## How to install

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
   chmod +x ./install.sh
   ./install.sh
   ```

## Folder structure

```bash
.
├── .bash_aliases # Entry point.
├── common # Common aliases.
│   ├── .bash_aliases # Aliases without arguments.
│   ├── .bash_deps # Installation of dependecies.
│   ├── .bash_overrides # Optional overrides for some commands.
│   ├── .git_aliases # Aliases for Git.
│   ├── .bash_constants # Exported constants.
│   ├── .bash_handlers # Input handlers.
│   ├── .git_aliases # Aliases for Git.
│   └── .bash_functions # Aliases with arguments.
├── linux # Aliases for Linux-only.
├── macos # Aliases for MacOS-only.
├── mingw # Aliases for MINGW (e.g. bundled with Git Bash for Windows).
├── unix # Aliases for all UNIX-like systems.
└── wsl # Aliases for Windows Subsystem Linux.
```

## How to modify aliases

1. Open project with your text editor of choice.
2. Modify.
3. Save file.
4. Update aliases in current session:

   ```bash
   alias-update
   ```

## How to sync aliases

1. Shortcut for pushing aliases to your repository:

   ```bash
   alias-push
   ```

2. Shortcut for pulling aliases from your repository:

   ```bash
   alias-pull
   ```
