#!/bin/bash
# Machine Profile: MacBook with Apple Silicon (M1/M2/M3)
# Author: jk1rby
# Description: macOS development machine with Apple Silicon

# Profile Metadata
export MACHINE_PROFILE="macbook-m1"
export MACHINE_TYPE="laptop"
export PROFILE_DESCRIPTION="MacBook with Apple Silicon"

# Hardware Features
export HAS_APPLE_SILICON=true
export HAS_TOUCHBAR=false  # Set to true for models with Touch Bar
export HAS_EXTERNAL_MONITOR=true
export BATTERY_POWERED=true

# Software Features to Enable
export ENABLE_HOMEBREW=true
export ENABLE_MACOS_APPS=true
export ENABLE_OBSIDIAN_SYNC=true
export ENABLE_ICLOUD_INTEGRATION=true
export ENABLE_DOCKER_DESKTOP=true
export ENABLE_VIRTUALIZATION=false  # Limited on Apple Silicon

# Development Tools
export ENABLE_PYTHON_FULL=true
export PYTHON_ENV_TYPE="miniconda"  # Lighter for laptop
export ENABLE_NODE_DEVELOPMENT=true
export ENABLE_SWIFT_DEVELOPMENT=true
export ENABLE_IOS_DEVELOPMENT=false

# System Optimizations
export ENABLE_BATTERY_OPTIMIZATIONS=true
export ENABLE_MACOS_DEFAULTS=true
export ENABLE_SPOTLIGHT_CUSTOMIZATION=true

# Homebrew Packages
export BREW_PACKAGES=(
    # Core tools
    "git" "gh" "stow" "tmux" "neovim"
    # Development
    "node" "python@3.11" "go" "rust"
    # Utilities
    "ripgrep" "fd" "bat" "exa" "fzf"
    "htop" "tree" "jq" "yq"
    # macOS specific
    "mas"  # Mac App Store CLI
    "rectangle"  # Window management
)

export BREW_CASK_PACKAGES=(
    # Development
    "visual-studio-code" "iterm2" "docker"
    # Productivity
    "obsidian" "notion" "alfred"
    # Communication
    "slack" "zoom" "discord"
    # Utilities
    "raycast" "cleanmymac" "1password"
)

export PYTHON_PACKAGES=(
    # Data Science (lighter selection for laptop)
    "numpy" "pandas" "matplotlib" "jupyter"
    # Tools
    "black" "pylint" "ipython"
    # CLI tools
    "httpie" "poetry"
)

# Custom Functions for this Profile
profile_pre_install() {
    log_info "Preparing macOS Apple Silicon environment..."
    
    # Check architecture
    if [[ "$(uname -m)" == "arm64" ]]; then
        log_success "Apple Silicon detected ($(sysctl -n machdep.cpu.brand_string))"
        
        # Set Homebrew path for Apple Silicon
        export PATH="/opt/homebrew/bin:$PATH"
    else
        log_warning "Intel Mac detected - some optimizations may not apply"
    fi
}

profile_post_install() {
    log_info "Finalizing macOS setup..."
    
    # Configure macOS defaults
    if [[ "$ENABLE_MACOS_DEFAULTS" == "true" ]]; then
        log_info "Configuring macOS defaults..."
        
        # Show hidden files in Finder
        defaults write com.apple.finder AppleShowAllFiles -bool true
        
        # Dock settings
        defaults write com.apple.dock tilesize -int 36
        defaults write com.apple.dock autohide -bool true
        defaults write com.apple.dock show-recents -bool false
        
        # Trackpad settings
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
        defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
        
        # Restart affected services
        killall Finder Dock
    fi
    
    # Setup Obsidian vault sync
    if [[ "$ENABLE_OBSIDIAN_SYNC" == "true" ]]; then
        log_info "Setting up Obsidian vault..."
        macos_obsidian_setup
    fi
}

# macOS specific Obsidian setup
macos_obsidian_setup() {
    local vault_path="$HOME/Documents/notes"
    local repo_url="https://github.com/jk1rby/notes.git"
    
    if [[ ! -d "$vault_path/.git" ]]; then
        log_info "Cloning Obsidian vault..."
        git clone "$repo_url" "$vault_path" || {
            log_warning "Failed to clone Obsidian vault"
            return 1
        }
    else
        log_info "Obsidian vault already exists"
    fi
    
    # Configure Git for vault
    cd "$vault_path"
    git config credential.helper osxkeychain
    git config user.email "${GIT_CONFIG_USER_EMAIL}"
    cd -
}

# Profile-specific configuration overrides
export GIT_CONFIG_USER_EMAIL="${GIT_CONFIG_USER_EMAIL:-user@macbook.local}"
export SHELL_THEME="powerlevel10k"
export TERMINAL_FONT="FiraCode Nerd Font"
export ITERM_PROFILE="Solarized Dark"