#!/bin/bash
# Install modern development tools and dependencies
# Part of JK's dotfiles setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Install basic system tools
install_system_tools() {
    log_info "Installing system tools..."
    
    sudo apt update
    sudo apt install -y \
        curl \
        wget \
        git \
        vim \
        neovim \
        tmux \
        zsh \
        htop \
        tree \
        unzip \
        zip \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    log_success "System tools installed"
}

# Install modern command line tools
install_modern_tools() {
    log_info "Installing modern command line tools..."
    
    # ripgrep (better grep)
    if ! command_exists rg; then
        curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
        sudo dpkg -i ripgrep_13.0.0_amd64.deb
        rm ripgrep_13.0.0_amd64.deb
        log_success "ripgrep installed"
    fi
    
    # fd (better find)
    if ! command_exists fd; then
        sudo apt install -y fd-find
        # Create symlink for fd
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
        log_success "fd installed"
    fi
    
    # bat (better cat)
    if ! command_exists bat; then
        sudo apt install -y bat
        # Create symlink for bat
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        log_success "bat installed"
    fi
    
    # exa (better ls)
    if ! command_exists exa; then
        wget -qO- https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip > /tmp/exa.zip
        sudo unzip -o /tmp/exa.zip -d /usr/local/bin/
        sudo chmod +x /usr/local/bin/exa
        rm /tmp/exa.zip
        log_success "exa installed"
    fi
    
    # fzf (fuzzy finder)
    if ! command_exists fzf; then
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        log_success "fzf installed"
    fi
    
    # Other useful tools
    sudo apt install -y \
        silversearcher-ag \
        xclip \
        neofetch \
        jq \
        tldr \
        ncdu \
        duf \
        procs
    
    log_success "Modern tools installed"
}

# Install development tools
install_dev_tools() {
    log_info "Installing development tools..."
    
    # Git tools
    sudo apt install -y \
        git-flow \
        git-extras \
        tig \
        gitg \
        meld
    
    # Docker
    if ! command_exists docker; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo usermod -aG docker $USER
        log_success "Docker installed"
    fi
    
    # Python tools
    sudo apt install -y \
        python3-pip \
        python3-venv \
        python3-dev \
        python-is-python3
    
    # Node.js tools
    if ! command_exists node; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
        log_success "Node.js installed"
    fi
    
    log_success "Development tools installed"
}

# Install fonts
install_fonts() {
    log_info "Installing fonts..."
    
    # Create fonts directory
    mkdir -p ~/.local/share/fonts
    
    # Download and install Nerd Fonts
    local fonts=(
        "FiraCode"
        "JetBrainsMono"
        "Hack"
        "SourceCodePro"
    )
    
    for font in "${fonts[@]}"; do
        if [[ ! -f ~/.local/share/fonts/${font}*.ttf ]]; then
            log_info "Installing $font Nerd Font..."
            wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/${font}.zip" -O /tmp/${font}.zip
            unzip -q /tmp/${font}.zip -d /tmp/${font}/
            cp /tmp/${font}/*.ttf ~/.local/share/fonts/ 2>/dev/null || true
            rm -rf /tmp/${font}*
            log_success "$font Nerd Font installed"
        fi
    done
    
    # Update font cache
    fc-cache -f -v >/dev/null 2>&1
    
    log_success "Fonts installed"
}

# Install Oh My Zsh plugins
install_zsh_plugins() {
    log_info "Installing additional Zsh plugins..."
    
    local plugins_dir="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins"
    
    # zsh-completions
    if [[ ! -d "$plugins_dir/zsh-completions" ]]; then
        git clone https://github.com/zsh-users/zsh-completions "$plugins_dir/zsh-completions"
        log_success "zsh-completions installed"
    fi
    
    # zsh-history-substring-search
    if [[ ! -d "$plugins_dir/zsh-history-substring-search" ]]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search "$plugins_dir/zsh-history-substring-search"
        log_success "zsh-history-substring-search installed"
    fi
    
    # zsh-you-should-use
    if [[ ! -d "$plugins_dir/you-should-use" ]]; then
        git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$plugins_dir/you-should-use"
        log_success "you-should-use installed"
    fi
    
    log_success "Additional Zsh plugins installed"
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Installing Dependencies            ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    install_system_tools
    install_modern_tools
    install_dev_tools
    install_fonts
    install_zsh_plugins
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Dependencies installed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Note: You may need to restart your terminal for some changes to take effect.${NC}"
}

# Run main function
main "$@"