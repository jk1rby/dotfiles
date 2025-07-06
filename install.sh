#!/bin/bash
# JK's Dotfiles Installation Script
# Installs and configures all dotfiles with dependency management

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Helper functions
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

# Check if running on supported system
check_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists lsb_release; then
            DISTRO=$(lsb_release -si)
            VERSION=$(lsb_release -sr)
            log_info "Detected $DISTRO $VERSION"
            
            if [[ "$DISTRO" != "Ubuntu" ]]; then
                log_warning "This script is optimized for Ubuntu. Some features may not work properly."
            fi
        else
            log_warning "Cannot detect Linux distribution. Proceeding with caution."
        fi
    else
        log_warning "This script is optimized for Linux. Some features may not work on your system."
    fi
}

# Create backup directory
create_backup() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing dotfiles
    local files=(".bashrc" ".zshrc" ".vimrc" ".tmux.conf" ".gitconfig" ".gitignore_global")
    
    for file in "${files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            log_info "Backing up $file"
            cp "$HOME/$file" "$BACKUP_DIR/"
        fi
    done
    
    log_success "Backup completed in $BACKUP_DIR"
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    # Check if apt is available (Ubuntu/Debian)
    if command_exists apt; then
        log_info "Updating package lists..."
        sudo apt update
        
        # Install basic tools
        sudo apt install -y \
            curl \
            wget \
            git \
            vim \
            tmux \
            zsh \
            htop \
            tree \
            unzip \
            build-essential \
            software-properties-common
        
        # Install optional tools
        log_info "Installing optional tools..."
        sudo apt install -y \
            ripgrep \
            fd-find \
            bat \
            exa \
            fzf \
            xclip \
            neofetch \
            silversearcher-ag
        
    elif command_exists yum; then
        log_info "Installing packages with yum..."
        sudo yum install -y curl wget git vim tmux zsh htop tree unzip
        
    elif command_exists pacman; then
        log_info "Installing packages with pacman..."
        sudo pacman -S --needed curl wget git vim tmux zsh htop tree unzip
        
    else
        log_warning "No supported package manager found. Please install dependencies manually."
    fi
    
    log_success "Dependencies installed"
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
    else
        log_info "zsh-autosuggestions already installed"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$plugins_dir/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_info "zsh-syntax-highlighting already installed"
    fi
}

# Install Tmux Plugin Manager
install_tmux_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ ! -d "$tpm_dir" ]]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        log_success "Tmux Plugin Manager installed"
    else
        log_info "Tmux Plugin Manager already installed"
    fi
}

# Install Vim plugins
install_vim_plugins() {
    local vundle_dir="$HOME/.vim/bundle/Vundle.vim"
    
    if [[ ! -d "$vundle_dir" ]]; then
        log_info "Installing Vundle for Vim..."
        git clone https://github.com/VundleVim/Vundle.vim.git "$vundle_dir"
        log_success "Vundle installed"
    else
        log_info "Vundle already installed"
    fi
}

# Create symbolic links
create_symlinks() {
    log_info "Creating symbolic links..."
    
    # Define file mappings
    declare -A files=(
        ["zsh/.zshrc"]="$HOME/.zshrc"
        ["git/.gitconfig"]="$HOME/.gitconfig"
        ["git/.gitignore_global"]="$HOME/.gitignore_global"
        ["vim/.vimrc"]="$HOME/.vimrc"
        ["tmux/.tmux.conf"]="$HOME/.tmux.conf"
    )
    
    for source_file in "${!files[@]}"; do
        target_file="${files[$source_file]}"
        source_path="$DOTFILES_DIR/$source_file"
        
        if [[ -f "$source_path" ]]; then
            # Remove existing file if it exists
            if [[ -f "$target_file" ]] || [[ -L "$target_file" ]]; then
                rm "$target_file"
            fi
            
            # Create symlink
            ln -sf "$source_path" "$target_file"
            log_success "Linked $source_file -> $target_file"
        else
            log_warning "Source file not found: $source_path"
        fi
    done
}

# Set Zsh as default shell
set_zsh_default() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting Zsh as default shell..."
        if command_exists zsh; then
            chsh -s $(which zsh)
            log_success "Zsh set as default shell (restart terminal to take effect)"
        else
            log_error "Zsh not found. Please install zsh first."
        fi
    else
        log_info "Zsh is already the default shell"
    fi
}

# Install fonts
install_fonts() {
    log_info "Installing fonts..."
    
    # Create fonts directory
    mkdir -p "$HOME/.local/share/fonts"
    
    # Download and install Nerd Fonts
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
    local font_dir="$HOME/.local/share/fonts"
    local temp_dir="/tmp/nerd-fonts"
    
    if [[ ! -f "$font_dir/FiraCodeNerdFont-Regular.ttf" ]]; then
        log_info "Downloading and installing FiraCode Nerd Font..."
        
        mkdir -p "$temp_dir"
        wget -q "$font_url" -O "$temp_dir/FiraCode.zip"
        unzip -q "$temp_dir/FiraCode.zip" -d "$temp_dir"
        cp "$temp_dir"/*.ttf "$font_dir/" 2>/dev/null || true
        
        # Update font cache
        fc-cache -f -v >/dev/null 2>&1
        
        # Clean up
        rm -rf "$temp_dir"
        
        log_success "FiraCode Nerd Font installed"
    else
        log_info "FiraCode Nerd Font already installed"
    fi
}

# Post-installation setup
post_install() {
    log_info "Running post-installation setup..."
    
    # Install Vim plugins
    log_info "Installing Vim plugins..."
    vim +PluginInstall +qall || true
    
    # Install Tmux plugins
    log_info "Installing Tmux plugins..."
    "$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh" || true
    
    log_success "Post-installation setup completed"
}

# Main installation function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    JK's Dotfiles Installation Script   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        log_info "Please clone the repository first:"
        log_info "git clone https://github.com/jk1rby/dotfiles.git $DOTFILES_DIR"
        exit 1
    fi
    
    # Change to dotfiles directory
    cd "$DOTFILES_DIR"
    
    # Run installation steps
    check_system
    create_backup
    install_dependencies
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_plugins
    install_tmux_tpm
    install_vim_plugins
    install_fonts
    create_symlinks
    set_zsh_default
    post_install
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Installation completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Configure Powerlevel10k: p10k configure"
    echo "3. Check backup files in: $BACKUP_DIR"
    echo "4. Customize settings in ~/.zshrc.local"
    echo
    echo -e "${GREEN}Enjoy your new dotfiles setup!${NC}"
}

# Run main function
main "$@"