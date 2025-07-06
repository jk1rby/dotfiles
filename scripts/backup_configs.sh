#!/bin/bash
# Backup existing configuration files before installing dotfiles
# Part of JK's dotfiles setup

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

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

# Create backup directory
create_backup_dir() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    log_success "Backup directory created"
}

# Backup configuration files
backup_configs() {
    log_info "Backing up configuration files..."
    
    # Define files to backup
    local files=(
        ".bashrc"
        ".zshrc"
        ".vimrc"
        ".tmux.conf"
        ".gitconfig"
        ".gitignore_global"
        ".p10k.zsh"
        ".zsh_history"
        ".viminfo"
        ".tmux"
        ".vim"
        ".oh-my-zsh"
        ".ssh/config"
        ".aws/config"
        ".aws/credentials"
    )
    
    local backed_up=0
    
    for file in "${files[@]}"; do
        local source_path="$HOME/$file"
        local backup_path="$BACKUP_DIR/$file"
        
        if [[ -f "$source_path" ]] || [[ -d "$source_path" ]]; then
            # Create parent directories if needed
            mkdir -p "$(dirname "$backup_path")"
            
            # Copy file or directory
            if [[ -d "$source_path" ]]; then
                cp -r "$source_path" "$backup_path"
                log_info "Backed up directory: $file"
            else
                cp "$source_path" "$backup_path"
                log_info "Backed up file: $file"
            fi
            
            ((backed_up++))
        fi
    done
    
    log_success "Backed up $backed_up configuration files/directories"
}

# Backup package lists
backup_packages() {
    log_info "Backing up package lists..."
    
    # APT packages
    if command -v apt >/dev/null 2>&1; then
        dpkg --get-selections > "$BACKUP_DIR/apt_packages.txt"
        log_info "APT packages backed up"
    fi
    
    # Snap packages
    if command -v snap >/dev/null 2>&1; then
        snap list > "$BACKUP_DIR/snap_packages.txt"
        log_info "Snap packages backed up"
    fi
    
    # Flatpak packages
    if command -v flatpak >/dev/null 2>&1; then
        flatpak list > "$BACKUP_DIR/flatpak_packages.txt"
        log_info "Flatpak packages backed up"
    fi
    
    # Python packages
    if command -v pip >/dev/null 2>&1; then
        pip freeze > "$BACKUP_DIR/python_packages.txt"
        log_info "Python packages backed up"
    fi
    
    # Node.js packages
    if command -v npm >/dev/null 2>&1; then
        npm list -g --depth=0 > "$BACKUP_DIR/npm_packages.txt"
        log_info "NPM packages backed up"
    fi
    
    log_success "Package lists backed up"
}

# Backup system information
backup_system_info() {
    log_info "Backing up system information..."
    
    # System information
    {
        echo "=== System Information ==="
        echo "Date: $(date)"
        echo "User: $(whoami)"
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d | cut -f2)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo
        
        echo "=== Hardware Information ==="
        echo "CPU: $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
        echo "Memory: $(free -h | grep "Mem:" | awk '{print $2}')"
        echo "Storage: $(df -h / | tail -1 | awk '{print $2}')"
        echo
        
        echo "=== Environment Variables ==="
        echo "SHELL: $SHELL"
        echo "PATH: $PATH"
        echo "HOME: $HOME"
        echo "USER: $USER"
        echo
        
        echo "=== Installed Shells ==="
        cat /etc/shells
        echo
        
        echo "=== Current Shell Configuration ==="
        echo "Default shell: $(getent passwd $USER | cut -d: -f7)"
        echo "Current shell: $0"
        echo
        
    } > "$BACKUP_DIR/system_info.txt"
    
    log_success "System information backed up"
}

# Create restore script
create_restore_script() {
    log_info "Creating restore script..."
    
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Restore script for dotfiles backup
# This script will restore the backed up configuration files

set -e

BACKUP_DIR="$(dirname "$0")"
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Restoring Configuration Files      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

log_warning "This will overwrite your current configuration files!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Restore cancelled"
    exit 0
fi

# Restore files
for file in .bashrc .zshrc .vimrc .tmux.conf .gitconfig .gitignore_global .p10k.zsh; do
    if [[ -f "$BACKUP_DIR/$file" ]]; then
        log_info "Restoring $file"
        cp "$BACKUP_DIR/$file" "$HOME/$file"
    fi
done

# Restore directories
for dir in .vim .oh-my-zsh .tmux; do
    if [[ -d "$BACKUP_DIR/$dir" ]]; then
        log_info "Restoring $dir"
        rm -rf "$HOME/$dir"
        cp -r "$BACKUP_DIR/$dir" "$HOME/$dir"
    fi
done

log_success "Configuration files restored successfully!"
log_info "You may need to restart your terminal for changes to take effect"
EOF

    chmod +x "$BACKUP_DIR/restore.sh"
    log_success "Restore script created: $BACKUP_DIR/restore.sh"
}

# Create backup summary
create_summary() {
    log_info "Creating backup summary..."
    
    {
        echo "=== Dotfiles Backup Summary ==="
        echo "Backup created: $(date)"
        echo "Backup location: $BACKUP_DIR"
        echo "User: $(whoami)"
        echo "Hostname: $(hostname)"
        echo
        
        echo "=== Backed Up Files ==="
        find "$BACKUP_DIR" -type f -name ".*" -o -name "*.txt" -o -name "*.sh" | sort
        echo
        
        echo "=== Backed Up Directories ==="
        find "$BACKUP_DIR" -type d -name ".*" | sort
        echo
        
        echo "=== Restore Instructions ==="
        echo "1. To restore all files: cd '$BACKUP_DIR' && ./restore.sh"
        echo "2. To restore individual files: cp '$BACKUP_DIR/filename' ~/"
        echo "3. To view package lists: cat '$BACKUP_DIR/*_packages.txt'"
        echo "4. To view system info: cat '$BACKUP_DIR/system_info.txt'"
        echo
        
    } > "$BACKUP_DIR/README.txt"
    
    log_success "Backup summary created: $BACKUP_DIR/README.txt"
}

# Main function
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    Backing Up Configuration Files     ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    create_backup_dir
    backup_configs
    backup_packages
    backup_system_info
    create_restore_script
    create_summary
    
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}    Backup completed successfully!     ${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Backup location:${NC} $BACKUP_DIR"
    echo -e "${YELLOW}To restore:${NC} cd '$BACKUP_DIR' && ./restore.sh"
    echo
}

# Run main function
main "$@"