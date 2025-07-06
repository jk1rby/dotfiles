#!/bin/bash
# Restore Original Dotfiles Script
# Restores .old files back to original locations

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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Restore Original Dotfiles         ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

log_warning "This will restore your original dotfiles from .old backups"
log_warning "This will REMOVE the current dotfiles and replace them with your originals"
echo

read -p "Are you sure you want to restore your original dotfiles? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Restore cancelled"
    exit 0
fi

# List of files and directories to restore
files=(".zshrc" ".bashrc" ".gitconfig" ".gitignore_global" ".tmux.conf" ".vimrc")
directories=(".config/nvim")

restored_count=0
not_found_count=0

log_info "Restoring original dotfiles..."

# Restore individual files
for file in "${files[@]}"; do
    old_file="$HOME/$file.old"
    current_file="$HOME/$file"
    
    if [[ -f "$old_file" ]]; then
        log_info "Restoring $file from backup"
        
        # Remove current file/symlink
        if [[ -f "$current_file" ]] || [[ -L "$current_file" ]]; then
            rm "$current_file"
        fi
        
        # Restore from .old
        if mv "$old_file" "$current_file"; then
            log_success "Restored $file"
            ((restored_count++))
        else
            log_error "Failed to restore $file"
        fi
    else
        log_info "No backup found for $file (was not backed up originally)"
        ((not_found_count++))
    fi
done

# Restore directories
for dir in "${directories[@]}"; do
    old_dir="$HOME/$dir.old"
    current_dir="$HOME/$dir"
    
    if [[ -d "$old_dir" ]]; then
        log_info "Restoring $(basename "$dir") directory from backup"
        
        # Remove current directory/symlink
        if [[ -d "$current_dir" ]] || [[ -L "$current_dir" ]]; then
            rm -rf "$current_dir"
        fi
        
        # Ensure parent directory exists
        mkdir -p "$(dirname "$current_dir")"
        
        # Restore from .old
        if mv "$old_dir" "$current_dir"; then
            log_success "Restored $(basename "$dir") directory"
            ((restored_count++))
        else
            log_error "Failed to restore $(basename "$dir") directory"
        fi
    else
        log_info "No backup found for $(basename "$dir") (was not backed up originally)"
        ((not_found_count++))
    fi
done

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Restore Complete                   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo

if [[ $restored_count -gt 0 ]]; then
    log_success "Successfully restored $restored_count dotfiles from .old backups"
else
    log_warning "No dotfiles were restored"
fi

if [[ $not_found_count -gt 0 ]]; then
    log_info "$not_found_count files had no .old backups (were not originally present)"
fi

echo
log_info "Your original dotfiles have been restored!"
log_info "You may need to restart your terminal or shell for changes to take effect"

# Check for any remaining .old files
remaining_olds=$(find "$HOME" -maxdepth 2 -name "*.old" 2>/dev/null | wc -l)
if [[ $remaining_olds -gt 0 ]]; then
    echo
    log_info "Found $remaining_olds remaining .old files in your home directory"
    log_info "You can safely remove these if you're happy with the restore:"
    log_info "  find ~/ -maxdepth 2 -name '*.old' -exec rm -rf {} +"
fi