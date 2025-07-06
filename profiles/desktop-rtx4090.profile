#!/bin/bash
# Machine Profile: Desktop with RTX 4090
# Author: jk1rby
# Description: High-performance desktop with NVIDIA RTX 4090 GPU

# Profile Metadata
export MACHINE_PROFILE="desktop-rtx4090"
export MACHINE_TYPE="desktop"
export PROFILE_DESCRIPTION="High-performance desktop with RTX 4090 GPU"

# Hardware Features
export HAS_NVIDIA_GPU=true
export NVIDIA_GPU_MODEL="RTX 4090"
export HAS_MULTIPLE_MONITORS=true
export HAS_HIGH_MEMORY=true  # 32GB+ RAM

# Software Features to Enable
export ENABLE_NVIDIA_DRIVERS=true
export ENABLE_CUDA=true
export ENABLE_DOCKER=true
export ENABLE_DOCKER_NVIDIA=true
export ENABLE_ROS2=true
export ENABLE_ISAAC_SIM=true
export ENABLE_HEAVY_IDE=true  # VS Code, JetBrains, etc.
export ENABLE_GAMING_TOOLS=false
export ENABLE_ML_FRAMEWORKS=true

# Development Tools
export ENABLE_PYTHON_FULL=true
export PYTHON_ENV_TYPE="anaconda"  # anaconda or miniconda
export ENABLE_NODE_DEVELOPMENT=true
export ENABLE_RUST_DEVELOPMENT=true
export ENABLE_CPP_DEVELOPMENT=true

# System Optimizations
export ENABLE_HARDWARE_OPTIMIZATIONS=true
export ENABLE_SUSPEND_FIXES=true
export ENABLE_PERFORMANCE_GOVERNOR=true
export ENABLE_NVIDIA_PERSISTENCE=true

# Package Lists
export DESKTOP_PACKAGES=(
    # Development
    "code" "docker-ce" "docker-compose-plugin"
    # System tools
    "htop" "nvtop" "btop" "iotop"
    # Media
    "vlc" "gimp" "blender"
    # Productivity
    "thunderbird" "libreoffice"
)

export PYTHON_PACKAGES=(
    # Data Science
    "numpy" "pandas" "matplotlib" "seaborn" "jupyter"
    # Machine Learning
    "torch" "torchvision" "tensorflow" "scikit-learn"
    # Computer Vision
    "opencv-python" "pillow"
    # Robotics
    "robotics-toolbox-python" "pybullet"
    # Tools
    "black" "pylint" "pytest"
)

# Custom Functions for this Profile
profile_pre_install() {
    log_info "Preparing desktop RTX 4090 environment..."
    
    # Check for RTX 4090
    if lspci | grep -qi "rtx.*4090"; then
        log_success "RTX 4090 detected - enabling all optimizations"
    else
        log_warning "RTX 4090 not detected - some features may not work"
    fi
}

profile_post_install() {
    log_info "Finalizing desktop RTX 4090 setup..."
    
    # Set performance governor
    if [[ "$ENABLE_PERFORMANCE_GOVERNOR" == "true" ]]; then
        log_info "Setting CPU performance governor..."
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    fi
    
    # Enable NVIDIA persistence daemon
    if [[ "$ENABLE_NVIDIA_PERSISTENCE" == "true" ]] && command_exists nvidia-smi; then
        log_info "Enabling NVIDIA persistence mode..."
        sudo nvidia-smi -pm 1
    fi
}

# Profile-specific configuration overrides
export GIT_CONFIG_USER_EMAIL="${GIT_CONFIG_USER_EMAIL:-user@desktop.local}"
export SHELL_THEME="powerlevel10k"
export TERMINAL_FONT="FiraCode Nerd Font Mono"