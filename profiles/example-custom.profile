#!/bin/bash
# Machine Profile: Example Custom Profile
# Author: jk1rby
# Description: Template for creating custom machine profiles

# Profile Metadata
export MACHINE_PROFILE="example-custom"
export MACHINE_TYPE="custom"  # desktop/laptop/server/custom
export PROFILE_DESCRIPTION="Example custom profile template"

# Hardware Features (set based on your hardware)
export HAS_NVIDIA_GPU=false
export HAS_MULTIPLE_MONITORS=false
export HAS_HIGH_MEMORY=false
export BATTERY_POWERED=false

# Software Features to Enable
export ENABLE_DOCKER=true
export ENABLE_PYTHON_FULL=true
export PYTHON_ENV_TYPE="miniconda"  # anaconda/miniconda/system
export ENABLE_NODE_DEVELOPMENT=true

# Custom Package Lists
export CUSTOM_PACKAGES=(
    # Add your custom packages here
    "vim" "git" "tmux"
)

# Custom Functions
profile_pre_install() {
    log_info "Running custom pre-install setup..."
    
    # Add any pre-installation checks or setup here
    # Example: Check for specific hardware or software requirements
    
    log_success "Custom pre-install complete"
}

profile_post_install() {
    log_info "Running custom post-install setup..."
    
    # Add any post-installation configuration here
    # Example: Configure specific applications or services
    
    log_success "Custom post-install complete"
}

# Profile-specific configuration overrides
export GIT_CONFIG_USER_EMAIL="${GIT_CONFIG_USER_EMAIL:-user@example.com}"
export SHELL_THEME="robbyrussell"  # or any Oh-My-Zsh theme
export TERMINAL_FONT="FiraCode Nerd Font"

# Custom environment variables
export MY_CUSTOM_VAR="value"
export ANOTHER_SETTING="enabled"