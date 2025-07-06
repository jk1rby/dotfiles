# JK's Cross-Platform Dotfiles + Complete System Setup

A comprehensive, **cross-platform dotfiles repository** with intelligent OS detection and **complete system automation** for Ubuntu 22.04 (RTX 4090 + Z790 optimized), macOS (Apple Silicon), and Windows 11 systems.

##  Features

- ** True Cross-Platform** - Works on Ubuntu 22.04, macOS (Apple Silicon), and Windows 11 with automatic OS detection
- **🛡️ Graceful Failure Handling** - Intelligent conflict resolution and backup system
- ** Complete Automation** - One-shot installation from fresh OS to fully configured system
- ** Hardware-Specific** - RTX 4090 + Z790 optimizations for Ubuntu systems
- ** Stow-Managed** - Clean symlink management with conflict resolution
- ** NvChad Integration** - Modern Neovim with LSP, syntax highlighting, and plugins
- ** Enhanced Shell** - Zsh + Oh-My-Zsh + Powerlevel10k + modern tools
- ** Development Ready** - Git, Python, ROS2, Docker, and more

##  One-Shot Installation

### Ubuntu 22.04 (RTX 4090 + Z790 Full Setup)
```bash
# Complete Ubuntu system setup with hardware optimizations
git clone https://github.com/jk1rby/dotfiles.git ~/dotfiles && cd ~/dotfiles && chmod +x scripts/install-cross-platform.sh && ./scripts/install-cross-platform.sh --ubuntu-full
```

### macOS (Apple Silicon Full Setup)
```bash
# Complete macOS setup with Obsidian + Git integration
git clone https://github.com/jk1rby/dotfiles.git ~/dotfiles && cd ~/dotfiles && chmod +x scripts/install-cross-platform.sh && ./scripts/install-cross-platform.sh --macos-full
```

### Windows 11 (Full Setup)
```bash
# Option 1: Automatic detection (recommended)
git clone https://github.com/jk1rby/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./scripts/install-cross-platform.sh --windows-full

# Option 2: Direct PowerShell execution
git clone https://github.com/jk1rby/dotfiles.git ~\dotfiles
cd ~\dotfiles
powershell -ExecutionPolicy Bypass -File scripts\install-cross-platform.ps1 -WindowsFull

# Option 3: Batch file execution
git clone https://github.com/jk1rby/dotfiles.git %USERPROFILE%\dotfiles
cd %USERPROFILE%\dotfiles
scripts\install-cross-platform.bat --windows-full
```

### Minimal Dotfiles Only (Any OS)
```bash
# Just dotfiles without system packages
git clone https://github.com/jk1rby/dotfiles.git ~/dotfiles && cd ~/dotfiles && chmod +x scripts/install-cross-platform.sh && ./scripts/install-cross-platform.sh --minimal
```

##  Installation Options

| Command                                      | Ubuntu 22.04          | macOS Apple Silicon   | Windows 11            | Description                               |
|:---------------------------------------------|:----------------------|:----------------------|:----------------------|:------------------------------------------|
| `./install-cross-platform.sh`               | ✅ Auto-detect        | ✅ Auto-detect        | ✅ Auto-detect        | Smart installation based on OS           |
| `./install-cross-platform.sh --ubuntu-full` | ✅ Full setup         | ❌                    | ❌                    | Complete Ubuntu setup + RTX 4090 fixes   |
| `./install-cross-platform.sh --macos-full`  | ❌                    | ✅ Full setup         | ❌                    | Complete macOS + Obsidian setup          |
| `./install-cross-platform.sh --windows-full`| ❌                    | ❌                    | ✅ Full setup         | Complete Windows 11 + Obsidian setup     |
| `./install-cross-platform.sh --minimal`     | ✅ Dotfiles only      | ✅ Dotfiles only      | ✅ Dotfiles only      | Just configurations, no system changes   |
| `./install-cross-platform.sh --force`       | ✅ Resolve conflicts  | ✅ Resolve conflicts  | ✅ Resolve conflicts  | Auto-resolve Stow conflicts              |

##  What Gets Installed

###  Ubuntu 22.04 Full Setup
**Core System:**
- Essential packages (git, vim, neovim, htop, tree, etc.)
- Google Chrome, VLC, GIMP, Thunderbird
- System utilities (synaptic, gparted, gnome-tweaks)
- Firewall configuration

** RTX 4090 + Z790 Hardware Fixes:**
- Custom suspend/resume scripts (if available)
- NVIDIA driver optimizations
- USB wake-up management  
- Z790 chipset power management
- PCIe configuration

** Development Environment:**
- NVIDIA drivers + CUDA (optional)
- ROS2 Humble (optional)
- Docker + Docker Compose (optional)
- Anaconda3 with extensive Python packages for data science and robotics
- Python development environment with scientific computing stack
- NVIDIA Omniverse + Isaac Sim support

###  macOS Full Setup (Apple Silicon Only)
**Core System:**
- Homebrew package manager (Apple Silicon optimized)
- Essential development tools
- Modern CLI utilities

** Obsidian + Git Integration:**
- Git configuration with macOS Keychain
- Obsidian vault setup at `~/Documents/notes`
- GitHub repository synchronization
- Branch management (main vs master)
- Credential storage optimization

###  Windows 11 Full Setup
**Script Execution Options:**
- **PowerShell** (Recommended) - Native Windows experience with advanced features
- **Batch Script** (Fallback) - Universal Windows compatibility
- **Git Bash** (Alternative) - Unix-like environment on Windows

**Core System:**
- Windows package managers (winget/chocolatey)
- Essential development tools
- Git for Windows integration
- PowerShell Core (if not present)

** Obsidian + Git Integration:**
- Git configuration with Windows Credential Manager
- Obsidian vault setup at `C:\Users\jk\Documents\notes`
- GitHub repository synchronization
- Branch management (main vs master)
- Windows Credential Manager integration

**Intelligent Script Delegation:**
- Automatically detects optimal Windows execution environment
- Delegates to PowerShell (.ps1) for best experience
- Falls back to Batch (.bat) for maximum compatibility
- Maintains unified command-line interface across all platforms

###  Universal Components (All Systems)
**Shell Environment:**
- Zsh with Oh-My-Zsh framework
- Powerlevel10k theme
- Auto-suggestions and syntax highlighting
- Modern command replacements (exa, bat, fd, ripgrep)

**Editor (NvChad):**
- LSP support for 8+ languages
- TreeSitter syntax highlighting
- File explorer with Git integration
- Fuzzy finding with Telescope
- Integrated terminal and Git tools

**Development Tools:**
- Git with 30+ useful aliases
- Tmux terminal multiplexer
- Python development environment
- Modern CLI tools (optional)

##  Repository Structure

```
dotfiles/
├── README.md                              # This comprehensive guide
├── scripts/
│   ├── install-cross-platform.sh         # 🆕 Smart cross-platform installer
│   └── install-stow-dotfiles.sh          # Legacy Ubuntu-only installer
├── zsh/.zshrc                             # Enhanced Zsh (cross-platform)
├── git/
│   ├── .gitconfig                         # Git config (cross-platform)
│   └── .gitignore_global                  # Global gitignore
├── tmux/.tmux.conf                        # Tmux configuration
└── nvim/.config/nvim/                     # Complete NvChad setup
    ├── init.lua                           # Main entry point
    ├── lua/chadrc.lua                     # UI customization
    ├── lua/configs/                       # LSP and tool configs
    └── lua/plugins/                       # Custom plugin setup
```

##  Intelligent Features

###  System Detection
The script automatically detects:
- **Operating System:** Ubuntu vs macOS vs Windows vs other Linux
- **OS Version:** Ubuntu 22.04, macOS version, Windows 11 build
- **Hardware:** RTX 4090 presence, Z790 chipset
- **Architecture:** x86_64 vs ARM64 (Apple Silicon)

###  Graceful Failure Handling
- **Backup System:** Automatic backup of existing configs
- **Conflict Resolution:** Intelligent Stow conflict detection and resolution
- **Dependency Checking:** Validates prerequisites before installation
- **Error Recovery:** Continues installation despite individual component failures
- **Force Mode:** `--force` flag to automatically resolve conflicts

###  Installation Modes

| Mode             | Description                                      | Use Case                         |
|:-----------------|:-------------------------------------------------|:---------------------------------|
| **Auto**         | Detects system and applies appropriate setup    | First-time users                 |
| **Ubuntu Full**  | Complete Ubuntu system with hardware fixes      | RTX 4090 + Z790 systems         |
| **macOS Full**   | Complete macOS with Obsidian integration        | Apple Silicon MacBook Pro        |
| **Windows Full** | Complete Windows 11 with Obsidian integration   | Windows 11 development systems  |
| **Minimal**      | Dotfiles only, no system changes                | Shared/restricted systems        |

### Prerequisites
```bash
# Ubuntu
sudo apt install -y git curl wget stow

# macOS  
xcode-select --install  # Installs git
# Homebrew and stow installed automatically

# Windows 11
# Install Git for Windows: https://git-scm.com/downloads
# winget or chocolatey package managers recommended
```

### Step-by-Step
```bash
# 1. Clone repository
git clone https://github.com/jk1rby/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Choose installation method
./scripts/install-cross-platform.sh --help

# 3. Run installation
./scripts/install-cross-platform.sh [options]

# 4. Apply dotfiles manually (if needed)
stow zsh git tmux nvim
```

### Hardware Support
- **Motherboard:** Z790 chipset (ASUS, MSI, Gigabyte, etc.)
- **CPU:** Intel 13th/14th gen (13900K, 14900K)
- **GPU:** NVIDIA RTX 4090
- **Memory:** DDR5 with deep sleep compatibility
- **Displays:** Dual 4K monitor support

### Critical Fixes Applied
1. **Suspend/Resume:** Custom scripts for proper power management
2. **USB Wake-up:** Disable conflicting USB devices
3. **NVIDIA Power:** GPU firmware and driver optimizations
4. **PCIe Management:** Disable problematic PCIe ASPM
5. **Deep Sleep:** Force hardware deep sleep mode

### Prerequisites for Hardware Fixes
The script looks for these files in your home directory:
- `~/rtx4090_suspend_fix.sh` - Main suspend fix script
- `~/disable_usb_wakeup_manual.sh` - USB wakeup management
- `~/rtx4090-suspend.service` - Systemd service file

### Obsidian + Git Integration
- **Vault Location:** `~/Documents/notes`
- **Repository:** `https://github.com/jk1rby/notes.git`
- **Authentication:** macOS Keychain integration
- **Branch Management:** Automatic main branch setup
- **Credential Storage:** Secure keychain storage

### macOS Optimizations
- **Homebrew:** Automatic installation and configuration (Apple Silicon only)
- **ARM64 Support:** Apple Silicon compatibility
- **Keychain Integration:** Seamless Git authentication
- **Path Management:** Proper Homebrew PATH setup

### Obsidian + Git Integration
- **Vault Location:** `C:\Users\jk\Documents\notes`
- **Repository:** `https://github.com/jk1rby/notes.git`
- **Authentication:** Windows Credential Manager integration
- **Branch Management:** Automatic main branch setup
- **Credential Storage:** Secure Windows credential storage

### Windows 11 Optimizations
- **Package Managers:** winget and chocolatey support
- **Git for Windows:** Full Git Bash and PowerShell integration
- **Credential Manager:** Seamless GitHub authentication
- **Path Management:** Proper Windows PATH configuration

##  Updating

```bash
cd ~/dotfiles
git pull origin main

# Re-run setup (safe to run multiple times)
./scripts/install-cross-platform.sh

# Or just update configurations
stow -R zsh git tmux nvim
```

##  Troubleshooting

### Common Issues

**Stow Conflicts:**
##  RTX 4090 + Z790 Optimizations

```bash
# Automatic resolution
./scripts/install-cross-platform.sh --force

# Manual resolution
rm ~/.zshrc ~/.gitconfig ~/.tmux.conf
rm -rf ~/.config/nvim
stow zsh git tmux nvim
```

**Permission Issues (macOS):**
```bash
# Grant Terminal keychain access in Security & Privacy
# Or reset Git credentials
git config --global --unset credential.helper
git config --global credential.helper osxkeychain
```

**Missing Dependencies:**
```bash
# Ubuntu
sudo apt update && sudo apt install -y stow git curl wget

# macOS
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Windows 11
# Install Git for Windows from: https://git-scm.com/downloads
# Install winget (usually pre-installed) or chocolatey
```

**RTX 4090 Hardware Scripts Missing:**
```bash
# The installer will skip hardware fixes if scripts aren't found
# Refer to the complete Ubuntu setup guide for manual configuration
```

### Verification Commands

```bash
# Check symlinks (Unix-like systems)
ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/nvim

# Windows symlinks check (Git Bash)
ls -la ~/.zshrc ~/.gitconfig ~/.tmux.conf ~/.config/nvim

# Test applications
nvim --version
tmux -V
zsh --version

# Test Git authentication
cd ~/Documents/notes  # or C:\Users\jk\Documents\notes on Windows
git status
git push origin main  # Should work without password prompt
```

##  Compatibility Matrix

| Feature                  | Ubuntu 22.04 | Other Ubuntu | Other Linux | macOS Intel | macOS ARM | Windows 11 | Windows 10 |
|:-------------------------|:-------------|:-------------|:------------|:------------|:----------|:-----------|:-----------|
| **Dotfiles**             | ✅           | ✅           | ✅          | ✅          | ✅        | ✅         | ✅         |
| **NvChad**               | ✅           | ✅           | ✅          | ✅          | ✅        | ✅         | ✅         |
| **Oh-My-Zsh**            | ✅           | ✅           | ✅          | ✅          | ✅        | ⚠️          | ⚠️          |
| **RTX 4090 Fixes**       | ✅           | ⚠️            | ❌          | ❌          | ❌        | ❌         | ❌         |
| **Full System Setup**    | ✅           | ⚠️            | ❌          | ❌          | ✅        | ✅         | ⚠️          |
| **Obsidian Integration** | ✅           | ✅           | ✅          | ✅          | ✅        | ✅         | ✅         |
| **ROS2 Humble**          | ✅           | ⚠️            | ❌          | ❌          | ❌        | ❌         | ❌         |

## Security

- **Backup System:** All existing configs backed up before changes
- **Credential Management:** Uses OS-native credential storage
- **Minimal Privileges:** Only requests sudo when necessary
- **Source Verification:** All downloads from official sources
- **Keychain Integration:** Secure credential storage on macOS

##  License

MIT License - feel free to use and modify.

---

**Author:** jk1rby  
**Hardware:** Ubuntu 22.04 + Z790 + Intel 14900K + RTX 4090 + MacBook Pro + Windows 11  
**Updated:** July 5, 2025

 **Ready for cross-platform deployment on Ubuntu 22.04, macOS (Apple Silicon), and Windows 11 systems!**
