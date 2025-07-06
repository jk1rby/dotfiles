#!/bin/bash
# Machine Profile: Minimal Server
# Author: jk1rby
# Description: Lightweight profile for servers and VMs

# Profile Metadata
export MACHINE_PROFILE="server-minimal"
export MACHINE_TYPE="server"
export PROFILE_DESCRIPTION="Minimal server configuration"

# Hardware Features
export HAS_NVIDIA_GPU=false
export HAS_GUI=false
export HEADLESS=true
export LIMITED_RESOURCES=true

# Software Features to Enable
export ENABLE_DOCKER=true
export ENABLE_FIREWALL=true
export ENABLE_SSH_HARDENING=true
export ENABLE_MONITORING=true
export ENABLE_AUTO_UPDATES=true

# Development Tools (minimal)
export ENABLE_PYTHON_FULL=false
export PYTHON_ENV_TYPE="system"  # Use system Python
export ENABLE_NODE_DEVELOPMENT=false
export ENABLE_BUILD_TOOLS=false

# System Optimizations
export ENABLE_SWAP_OPTIMIZATION=true
export ENABLE_KERNEL_TUNING=true
export ENABLE_LOG_ROTATION=true

# Minimal Package Lists
export SERVER_PACKAGES=(
    # Core utilities
    "git" "vim" "tmux" "htop"
    "curl" "wget" "rsync"
    # Security
    "fail2ban" "ufw"
    # Monitoring
    "netdata" "ncdu"
    # Network tools
    "net-tools" "traceroute" "mtr"
)

export PYTHON_PACKAGES=(
    # Minimal Python tools
    "pip" "virtualenv"
    # System management
    "ansible" "fabric"
)

# Custom Functions for this Profile
profile_pre_install() {
    log_info "Preparing minimal server environment..."
    
    # Check available memory
    local total_mem_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ $total_mem_mb -lt 1024 ]]; then
        log_warning "Low memory detected: ${total_mem_mb}MB - using minimal configuration"
        export EXTRA_MINIMAL=true
    fi
    
    # Check if running in container/VM
    if systemd-detect-virt -q; then
        log_info "Virtualized environment detected: $(systemd-detect-virt)"
        export IN_VIRTUAL_ENV=true
    fi
}

profile_post_install() {
    log_info "Finalizing server setup..."
    
    # Configure firewall
    if [[ "$ENABLE_FIREWALL" == "true" ]] && command_exists ufw; then
        log_info "Configuring firewall..."
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow ssh
        sudo ufw --force enable
    fi
    
    # Setup fail2ban
    if [[ "$ENABLE_SSH_HARDENING" == "true" ]] && command_exists fail2ban-client; then
        log_info "Configuring fail2ban..."
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
    fi
    
    # Configure swap for low memory systems
    if [[ "$ENABLE_SWAP_OPTIMIZATION" == "true" ]] && [[ "$EXTRA_MINIMAL" == "true" ]]; then
        log_info "Optimizing swap settings for low memory..."
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi
    
    # Setup automatic security updates
    if [[ "$ENABLE_AUTO_UPDATES" == "true" ]]; then
        log_info "Enabling automatic security updates..."
        echo 'Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}-security";
};' | sudo tee /etc/apt/apt.conf.d/50unattended-upgrades
    fi
}

# Minimal shell configuration
minimal_shell_setup() {
    # Skip heavy themes and plugins for servers
    export SKIP_POWERLEVEL10K=true
    export SKIP_HEAVY_PLUGINS=true
    
    # Use simple prompt
    if [[ -f ~/.zshrc ]]; then
        echo '# Simple server prompt
PROMPT="%n@%m:%~$ "' >> ~/.zshrc.local
    fi
}

# Profile-specific configuration overrides
export GIT_CONFIG_USER_EMAIL="${GIT_CONFIG_USER_EMAIL:-admin@server.local}"
export SHELL_THEME="robbyrussell"  # Simple theme
export SKIP_FONTS_INSTALL=true
export MINIMAL_DOTFILES=true