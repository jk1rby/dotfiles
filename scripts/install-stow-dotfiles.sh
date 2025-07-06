#!/bin/bash
# Install and setup Stow-managed dotfiles with NvChad
# JK's dotfiles setup script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/dotfiles"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    cd "$DOTFILES_DIR"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    log_info "Please run these commands manually:"
    echo "sudo apt update"
    echo "sudo apt install -y stow neovim git curl wget zsh tmux"
    echo ""
    read -p "Press Enter after installing dependencies..."
    
    # Verify installations
    local missing_deps=()
    
    if ! command_exists stow; then
        missing_deps+=("stow")
    fi
    
    if ! command_exists nvim; then
        missing_deps+=("neovim")
    fi
    
    if ! command_exists zsh; then
        missing_deps+=("zsh")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_error "Please install them and run this script again."
        exit 1
    fi
    
    log_success "All dependencies are installed"
}

# Backup existing configs
backup_existing() {
    log_info "Backing up existing configurations..."
    
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    local files=(".zshrc" ".gitconfig" ".gitignore_global" ".tmux.conf")
    
    for file in "${files[@]}"; do
        if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
            log_info "Backing up $file"
            cp "$HOME/$file" "$backup_dir/"
        fi
    done
    
    log_success "Backup completed in $backup_dir"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed"
    else
        log_info "Oh My Zsh already installed"
    fi
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [[ ! -d "$p10k_dir" ]]; then
        log_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        log_success "Powerlevel10k installed"
    else
        log_info "Powerlevel10k already installed"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # zsh-autosuggestions
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$plugins_dir/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    fi
    
    # you-should-use
    if [[ ! -d "$plugins_dir/you-should-use" ]]; then
        log_info "Installing you-should-use..."
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$plugins_dir/you-should-use"
        log_success "you-should-use installed"
    fi
}

# Setup NvChad via Stow (no longer cloning directly)
setup_nvchad() {
    log_info "Setting up NvChad configuration via Stow..."
    
    # Backup existing neovim config if it exists and is not a symlink
    if [[ -d "$HOME/.config/nvim" ]] && [[ ! -L "$HOME/.config/nvim" ]]; then
        log_info "Backing up existing Neovim config..."
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # NvChad will be managed via Stow now - the config will handle plugin installation
    log_success "NvChad configuration ready (will be stowed with other configs)"
    log_info "NvChad will auto-install on first nvim launch"
}

# Use Stow to create symlinks
stow_configs() {
    log_info "Using Stow to create symlinks..."
    
    cd "$DOTFILES_DIR"
    
    # Stow each package
    local packages=("zsh" "git" "tmux" "nvim")
    
    for package in "${packages[@]}"; do
        if [[ -d "$package" ]]; then
            log_info "Stowing $package..."
            stow -v "$package"
            log_success "Stowed $package"
        else
            log_warning "Package directory not found: $package"
        fi
    done
    
    log_success "All configurations stowed"
}

# Set Zsh as default shell
set_zsh_default() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting Zsh as default shell..."
        chsh -s $(which zsh)
        log_success "Zsh set as default shell (restart terminal to take effect)"
    else
        log_info "Zsh is already the default shell"
    fi
}

# Install modern CLI tools
install_modern_tools() {
    log_info "Would you like to install modern CLI tools? (y/N)"
    read -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Please install these modern tools manually:"
        echo ""
        echo "# Modern replacements"
        echo "sudo apt install -y bat fd-find ripgrep"
        echo ""
        echo "# Create symlinks"
        echo "sudo ln -sf /usr/bin/batcat /usr/local/bin/bat"
        echo "sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd"
        echo ""
        echo "# Install exa (better ls)"
        echo "wget -qO- https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip > /tmp/exa.zip"
        echo "sudo unzip -o /tmp/exa.zip -d /usr/local/bin/"
        echo "sudo chmod +x /usr/local/bin/exa"
        echo "rm /tmp/exa.zip"
        echo ""
        echo "# Install fzf"
        echo "git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf"
        echo "~/.fzf/install --all"
        echo ""
        read -p "Press Enter after installing tools..."
    fi
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Stow Dotfiles + NvChad Setup       ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    check_directory
    install_dependencies
    backup_existing
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_plugins
    setup_nvchad
    stow_configs
    set_zsh_default
    install_modern_tools
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation completed!            ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal"
    echo "2. Run 'nvim' - NvChad will auto-install plugins on first launch"
    echo "3. Configure Powerlevel10k: p10k configure"
    echo "4. Enjoy your new setup!"
    echo
    echo -e "${BLUE}Stow commands for reference:${NC}"
    echo "• Add package: stow <package-name>"
    echo "• Remove package: stow -D <package-name>"
    echo "• Restow package: stow -R <package-name>"
    echo
    echo -e "${GREEN}NvChad Features:${NC}"
    echo "• <Space>ff - Find files"
    echo "• <Space>fg - Live grep"
    echo "• <Space>e - Toggle file explorer"
    echo "• <Space>th - Change theme"
    echo
}

# Run main function
main "$@"