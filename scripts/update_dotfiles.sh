#!/bin/bash
# Update dotfiles repository and sync changes
# Part of JK's dotfiles setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOTFILES_DIR="$HOME/.dotfiles"

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

# Update git repository
update_repo() {
    log_info "Updating dotfiles repository..."
    
    cd "$DOTFILES_DIR"
    
    # Stash any local changes
    if ! git diff --quiet; then
        log_warning "Local changes detected. Stashing them..."
        git stash push -m "Auto-stash before update $(date)"
    fi
    
    # Pull latest changes
    git pull origin main
    
    log_success "Repository updated"
}

# Update submodules
update_submodules() {
    log_info "Updating git submodules..."
    
    cd "$DOTFILES_DIR"
    git submodule update --init --recursive
    
    log_success "Submodules updated"
}

# Update Oh My Zsh
update_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Updating Oh My Zsh..."
        "$HOME/.oh-my-zsh/tools/upgrade.sh"
        log_success "Oh My Zsh updated"
    fi
}

# Update Zsh plugins
update_zsh_plugins() {
    log_info "Updating Zsh plugins..."
    
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    for plugin_dir in "$plugins_dir"/*; do
        if [[ -d "$plugin_dir/.git" ]]; then
            plugin_name=$(basename "$plugin_dir")
            log_info "Updating $plugin_name..."
            cd "$plugin_dir"
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
        fi
    done
    
    log_success "Zsh plugins updated"
}

# Update Powerlevel10k
update_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [[ -d "$p10k_dir" ]]; then
        log_info "Updating Powerlevel10k..."
        cd "$p10k_dir"
        git pull origin master
        log_success "Powerlevel10k updated"
    fi
}

# Update Tmux plugins
update_tmux_plugins() {
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_info "Updating Tmux plugins..."
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
        log_success "Tmux plugins updated"
    fi
}

# Update Vim plugins
update_vim_plugins() {
    if [[ -d "$HOME/.vim/bundle" ]]; then
        log_info "Updating Vim plugins..."
        vim +PluginUpdate +qall
        log_success "Vim plugins updated"
    fi
}

# Update system packages
update_system_packages() {
    log_info "Updating system packages..."
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt upgrade -y
    elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --noconfirm
    else
        log_warning "No supported package manager found"
    fi
    
    log_success "System packages updated"
}

# Update Node.js packages
update_node_packages() {
    if command -v npm >/dev/null 2>&1; then
        log_info "Updating global npm packages..."
        npm update -g
        log_success "Global npm packages updated"
    fi
}

# Update Python packages
update_python_packages() {
    if command -v pip >/dev/null 2>&1; then
        log_info "Updating Python packages..."
        pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip install -U
        log_success "Python packages updated"
    fi
}

# Cleanup old files
cleanup() {
    log_info "Cleaning up old files..."
    
    # Clean up Vim
    if [[ -d "$HOME/.vim" ]]; then
        find "$HOME/.vim" -name "*.swp" -delete 2>/dev/null || true
        find "$HOME/.vim" -name "*.swo" -delete 2>/dev/null || true
        find "$HOME/.vim" -name "*~" -delete 2>/dev/null || true
    fi
    
    # Clean up Zsh
    if [[ -f "$HOME/.zsh_history" ]]; then
        # Remove duplicate history entries
        awk '!seen[$0]++' "$HOME/.zsh_history" > "$HOME/.zsh_history.tmp"
        mv "$HOME/.zsh_history.tmp" "$HOME/.zsh_history"
    fi
    
    # Clean up tmux
    if [[ -d "$HOME/.tmux" ]]; then
        find "$HOME/.tmux" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    fi
    
    log_success "Cleanup completed"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check if symlinks are working
    if [[ ! -L "$HOME/.zshrc" ]]; then
        log_error "~/.zshrc is not a symlink"
        ((errors++))
    fi
    
    if [[ ! -L "$HOME/.vimrc" ]]; then
        log_error "~/.vimrc is not a symlink"
        ((errors++))
    fi
    
    if [[ ! -L "$HOME/.tmux.conf" ]]; then
        log_error "~/.tmux.conf is not a symlink"
        ((errors++))
    fi
    
    if [[ ! -L "$HOME/.gitconfig" ]]; then
        log_error "~/.gitconfig is not a symlink"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All symlinks are working correctly"
    else
        log_error "Found $errors issues with symlinks"
    fi
    
    return $errors
}

# Show update summary
show_summary() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Update Summary                      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${GREEN}Updated components:${NC}"
    echo "• Dotfiles repository"
    echo "• Oh My Zsh and plugins"
    echo "• Powerlevel10k theme"
    echo "• Tmux plugins"
    echo "• Vim plugins"
    echo "• System packages"
    echo
    echo -e "${YELLOW}Recommendation:${NC}"
    echo "Restart your terminal or run: source ~/.zshrc"
    echo
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Updating Dotfiles                   ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    # Update components
    update_repo
    update_submodules
    update_oh_my_zsh
    update_zsh_plugins
    update_powerlevel10k
    update_tmux_plugins
    update_vim_plugins
    
    # Update system (optional)
    if [[ "${1:-}" == "--system" ]]; then
        update_system_packages
        update_node_packages
        update_python_packages
    fi
    
    # Cleanup and verify
    cleanup
    verify_installation
    
    # Show summary
    show_summary
    
    log_success "Update completed successfully!"
}

# Run main function
main "$@"