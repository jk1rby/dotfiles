#!/bin/bash
# Cross-Platform Dotfiles Installation Script
# Supports Ubuntu 22.04 (RTX 4090 + Z790) and macOS
# Author: jk1rby

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
LOG_DIR="$DOTFILES_DIR/logs"
LOG_FILE="$LOG_DIR/install_$(date +%Y%m%d_%H%M%S).log"
VERBOSE_LOGGING=true
PROFILES_DIR="$DOTFILES_DIR/profiles"
LOADED_PROFILE=""

# System detection
OS_TYPE=""
OS_VERSION=""
ARCH=""
IS_RTX4090_SYSTEM=false

# Feature flags
ENABLE_UBUNTU_HARDWARE_FIXES=false
ENABLE_FULL_UBUNTU_SETUP=false
ENABLE_MACOS_SETUP=false
ENABLE_WINDOWS_SETUP=false
ENABLE_ROS2=false
ENABLE_NVIDIA_SETUP=false

# Installation flags
FORCE_INSTALL=false

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$LOG_DIR"
    
    # Create log file with header
    cat > "$LOG_FILE" << EOF
================================================================================
Cross-Platform Dotfiles Installation Log
================================================================================
Start Time: $(date '+%Y-%m-%d %H:%M:%S %Z')
Script: $0
Arguments: $*
User: $(whoami)
Hostname: $(hostname)
Working Directory: $(pwd)
================================================================================

EOF
    
    log_to_file "Logging initialized: $LOG_FILE"
}

# Log to file function
log_to_file() {
    if [[ "$VERBOSE_LOGGING" == "true" && -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    fi
}

# Enhanced logging functions with file output
log_info() {
    local message="${BLUE}[INFO]${NC} $1"
    echo -e "$message"
    log_to_file "[INFO] $1"
}

log_success() {
    local message="${GREEN}[SUCCESS]${NC} $1"
    echo -e "$message"
    log_to_file "[SUCCESS] $1"
}

log_warning() {
    local message="${YELLOW}[WARNING]${NC} $1"
    echo -e "$message"
    log_to_file "[WARNING] $1"
}

log_error() {
    local message="${RED}[ERROR]${NC} $1"
    echo -e "$message"
    log_to_file "[ERROR] $1"
}

log_section() {
    echo
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}    $1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    echo
    log_to_file ""
    log_to_file "========================================"
    log_to_file "    $1"
    log_to_file "========================================"
    log_to_file ""
}

# Log command execution with output capture
log_command() {
    local cmd="$1"
    local description="${2:-Executing command}"
    
    log_info "$description: $cmd"
    log_to_file "[COMMAND] $description: $cmd"
    
    # Execute command and capture both stdout and stderr
    local output
    local exit_code
    
    output=$(eval "$cmd" 2>&1)
    exit_code=$?
    
    # Log the output
    if [[ -n "$output" ]]; then
        log_to_file "[OUTPUT] $output"
    fi
    
    # Log the result
    if [[ $exit_code -eq 0 ]]; then
        log_to_file "[RESULT] Command succeeded (exit code: $exit_code)"
    else
        log_to_file "[RESULT] Command failed (exit code: $exit_code)"
        log_warning "Command failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Idempotent package installation helpers
is_package_installed() {
    local package="$1"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists dpkg; then
            dpkg -l | grep -q "^ii  $package " && return 0
        elif command_exists rpm; then
            rpm -q "$package" &>/dev/null && return 0
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            brew list "$package" &>/dev/null && return 0
        fi
    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command_exists winget; then
            winget list --id "$package" &>/dev/null && return 0
        elif command_exists choco; then
            choco list --local-only "$package" | grep -q "$package" && return 0
        fi
    fi
    
    # Also check if command exists (for cases where package name != command name)
    command_exists "$package" && return 0
    
    return 1
}

install_package_idempotent() {
    local package="$1"
    local package_name="${2:-$package}"  # Optional display name
    local force="${3:-false}"
    
    # Check if already installed (unless force is true)
    if [[ "$force" != "true" ]] && is_package_installed "$package"; then
        log_info "$package_name already installed ($(which $package 2>/dev/null || echo 'system package'))"
        return 0
    fi
    
    log_info "Installing $package_name..."
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists apt; then
            sudo apt install -y "$package" || {
                log_warning "Failed to install $package_name"
                return 1
            }
        elif command_exists yum; then
            sudo yum install -y "$package" || {
                log_warning "Failed to install $package_name"
                return 1
            }
        elif command_exists dnf; then
            sudo dnf install -y "$package" || {
                log_warning "Failed to install $package_name"
                return 1
            }
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            brew install "$package" || {
                log_warning "Failed to install $package_name"
                return 1
            }
        fi
    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command_exists winget; then
            winget install --id "$package" --silent --accept-source-agreements --accept-package-agreements || {
                log_warning "Failed to install $package_name"
                return 1
            }
        elif command_exists choco; then
            choco install "$package" -y || {
                log_warning "Failed to install $package_name"
                return 1
            }
        fi
    fi
    
    log_success "$package_name installed successfully"
    return 0
}

# Idempotent directory creation
create_directory_idempotent() {
    local dir="$1"
    local description="${2:-directory}"
    
    if [[ -d "$dir" ]]; then
        log_info "$description already exists: $dir"
        return 0
    fi
    
    log_info "Creating $description: $dir"
    if mkdir -p "$dir"; then
        log_success "$description created successfully"
        return 0
    else
        log_error "Failed to create $description: $dir"
        return 1
    fi
}

# Idempotent file download
download_file_idempotent() {
    local url="$1"
    local destination="$2"
    local description="${3:-file}"
    local force="${4:-false}"
    
    if [[ "$force" != "true" ]] && [[ -f "$destination" ]]; then
        log_info "$description already downloaded: $destination"
        return 0
    fi
    
    log_info "Downloading $description from $url..."
    
    # Create parent directory if needed
    local parent_dir=$(dirname "$destination")
    create_directory_idempotent "$parent_dir" "parent directory"
    
    if command_exists wget; then
        wget -q "$url" -O "$destination" || {
            log_error "Failed to download $description"
            rm -f "$destination"  # Clean up partial download
            return 1
        }
    elif command_exists curl; then
        curl -fsSL "$url" -o "$destination" || {
            log_error "Failed to download $description"
            rm -f "$destination"  # Clean up partial download
            return 1
        }
    else
        log_error "Neither wget nor curl available for downloading"
        return 1
    fi
    
    log_success "$description downloaded successfully"
    return 0
}

# Idempotent git clone
clone_repository_idempotent() {
    local repo_url="$1"
    local destination="$2"
    local description="${3:-repository}"
    local force="${4:-false}"
    
    if [[ "$force" != "true" ]] && [[ -d "$destination/.git" ]]; then
        log_info "$description already cloned: $destination"
        
        # Optionally update the repository
        log_info "Updating $description..."
        cd "$destination" && git pull --quiet || log_warning "Failed to update $description"
        cd - >/dev/null
        
        return 0
    fi
    
    # Remove destination if it exists but is not a git repo
    if [[ -d "$destination" ]] && [[ ! -d "$destination/.git" ]]; then
        log_warning "Directory exists but is not a git repository: $destination"
        log_info "Removing and re-cloning..."
        rm -rf "$destination"
    fi
    
    log_info "Cloning $description from $repo_url..."
    
    # Create parent directory if needed
    local parent_dir=$(dirname "$destination")
    create_directory_idempotent "$parent_dir" "parent directory"
    
    if git clone --quiet "$repo_url" "$destination"; then
        log_success "$description cloned successfully"
        return 0
    else
        log_error "Failed to clone $description"
        return 1
    fi
}

# Idempotent symlink creation
create_symlink_idempotent() {
    local source="$1"
    local target="$2"
    local description="${3:-symlink}"
    local force="${4:-false}"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source does not exist for $description: $source"
        return 1
    fi
    
    # Check if target already exists and is correct
    if [[ -L "$target" ]]; then
        local current_source=$(readlink "$target")
        if [[ "$current_source" == "$source" ]]; then
            log_info "$description already correctly linked: $target -> $source"
            return 0
        else
            log_warning "$description exists but points elsewhere: $target -> $current_source"
            if [[ "$force" == "true" ]]; then
                log_info "Removing incorrect symlink..."
                rm -f "$target"
            else
                log_error "Use --force to overwrite existing symlink"
                return 1
            fi
        fi
    elif [[ -e "$target" ]]; then
        log_warning "$description target exists and is not a symlink: $target"
        if [[ "$force" == "true" ]]; then
            log_info "Backing up existing file..."
            mv "$target" "$target.backup.$(date +%Y%m%d_%H%M%S)"
        else
            log_error "Use --force to backup and overwrite existing file"
            return 1
        fi
    fi
    
    # Create the symlink
    log_info "Creating $description: $target -> $source"
    if ln -sf "$source" "$target"; then
        log_success "$description created successfully"
        return 0
    else
        log_error "Failed to create $description"
        return 1
    fi
}

# Log system information
log_system_info() {
    log_to_file ""
    log_to_file "================ SYSTEM INFORMATION ================"
    
    # Operating System
    if [[ -f /etc/os-release ]]; then
        log_to_file "OS Information:"
        while IFS='=' read -r key value; do
            if [[ -n "$key" && ! "$key" =~ ^# ]]; then
                log_to_file "  $key=$value"
            fi
        done < /etc/os-release
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_to_file "OS Information:"
        log_to_file "  NAME=macOS"
        log_to_file "  VERSION=$(sw_vers -productVersion)"
        log_to_file "  BUILD=$(sw_vers -buildVersion)"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        log_to_file "OS Information:"
        log_to_file "  NAME=Windows"
        if command_exists cmd; then
            local win_version=$(cmd /c "ver" 2>/dev/null | grep -o "Version [0-9]*\.[0-9]*\.[0-9]*" | cut -d' ' -f2 2>/dev/null || echo "Unknown")
            log_to_file "  VERSION=$win_version"
        fi
    fi
    
    # Architecture
    log_to_file "Architecture: $(uname -m)"
    
    # Memory
    if command_exists free; then
        log_to_file "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local mem_gb=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
        log_to_file "Memory: ${mem_gb}GB"
    fi
    
    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
        local cpu_cores=$(nproc)
        log_to_file "CPU: $cpu_model ($cpu_cores cores)"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        local cpu_model=$(sysctl -n machdep.cpu.brand_string)
        local cpu_cores=$(sysctl -n hw.ncpu)
        log_to_file "CPU: $cpu_model ($cpu_cores cores)"
    fi
    
    # GPU (if available)
    if command_exists lspci; then
        local gpu_info=$(lspci | grep -i "vga\|3d\|display" | head -3)
        if [[ -n "$gpu_info" ]]; then
            log_to_file "GPU(s):"
            echo "$gpu_info" | while read -r line; do
                log_to_file "  $line"
            done
        fi
    elif command_exists nvidia-smi; then
        local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null)
        if [[ -n "$gpu_name" ]]; then
            log_to_file "GPU: $gpu_name"
        fi
    fi
    
    # Disk space
    if command_exists df; then
        log_to_file "Disk Usage:"
        df -h | grep -E "^/dev|^[A-Z]:" | while read -r line; do
            log_to_file "  $line"
        done
    fi
    
    # Shell
    log_to_file "Current Shell: $SHELL"
    
    # Environment variables of interest
    log_to_file "Environment:"
    log_to_file "  HOME=$HOME"
    log_to_file "  PWD=$PWD"
    log_to_file "  PATH (first 200 chars): ${PATH:0:200}..."
    
    log_to_file "======================================================="
    log_to_file ""
}

# System detection and validation
detect_system() {
    log_section "System Detection"
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if command_exists lsb_release; then
            OS_VERSION=$(lsb_release -sr)
            local distro=$(lsb_release -si)
            log_info "Detected: $distro $OS_VERSION"
            
            if [[ "$distro" == "Ubuntu" && "$OS_VERSION" == "22.04" ]]; then
                log_success "Ubuntu 22.04 detected - Full setup available"
                ENABLE_FULL_UBUNTU_SETUP=true
            elif [[ "$distro" == "Ubuntu" ]]; then
                log_warning "Ubuntu $OS_VERSION detected - Limited compatibility"
            else
                log_warning "Non-Ubuntu Linux detected - Basic setup only"
            fi
        else
            log_warning "Unknown Linux distribution - Basic setup only"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        OS_VERSION=$(sw_vers -productVersion)
        log_info "Detected: macOS $OS_VERSION"
        
        # Check if Apple Silicon
        if [[ "$ARCH" == "arm64" ]]; then
            log_success "Apple Silicon Mac detected - macOS setup available"
            ENABLE_MACOS_SETUP=true
        else
            log_warning "Intel Mac detected - Apple Silicon required for full setup"
            log_info "Minimal dotfiles installation available only"
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        OS_TYPE="windows"
        # Try to detect Windows version
        if command_exists cmd; then
            OS_VERSION=$(cmd /c "ver" 2>/dev/null | grep -o "Version [0-9]*\.[0-9]*\.[0-9]*" | cut -d' ' -f2 2>/dev/null || echo "Unknown")
            log_info "Detected: Windows $OS_VERSION"
            
            # Check if Windows 11 (build 22000+)
            local build_number=$(echo "$OS_VERSION" | cut -d'.' -f3)
            if [[ -n "$build_number" ]] && [[ "$build_number" -ge 22000 ]]; then
                log_success "Windows 11 detected - Windows setup available"
                ENABLE_WINDOWS_SETUP=true
            else
                log_warning "Windows 10 or older detected - Windows 11 required for full setup"
                log_info "Minimal dotfiles installation available only"
            fi
        else
            log_warning "Could not determine Windows version - assuming Windows 11"
            ENABLE_WINDOWS_SETUP=true
        fi
        
        # Check execution environment and delegate to appropriate Windows script
        log_info "Windows detected - checking for optimal script execution..."
        
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local windows_args=""
        
        # Convert bash arguments to Windows script arguments
        for arg in "$@"; do
            case "$arg" in
                --force) windows_args="$windows_args --force" ;;
                --minimal) windows_args="$windows_args --minimal" ;;
                --windows-full) windows_args="$windows_args --windows-full" ;;
                --verbose) ;; # PowerShell script has logging by default
                --no-verbose) ;; # Ignore for Windows
            esac
        done
        
        # Try PowerShell first (best option)
        if command_exists powershell || command_exists pwsh; then
            log_info "PowerShell detected - using PowerShell script for optimal Windows experience"
            log_to_file "[DELEGATION] Delegating to PowerShell script with args: $windows_args"
            
            if command_exists pwsh; then
                pwsh -ExecutionPolicy Bypass -File "$script_dir/install-cross-platform.ps1" $windows_args
            else
                powershell -ExecutionPolicy Bypass -File "$script_dir/install-cross-platform.ps1" $windows_args
            fi
            
            local ps_exit_code=$?
            log_to_file "[DELEGATION] PowerShell script completed with exit code: $ps_exit_code"
            finalize_log $ps_exit_code
            exit $ps_exit_code
            
        # Fallback to batch script
        elif command_exists cmd; then
            log_info "Using Windows batch script for compatibility"
            log_to_file "[DELEGATION] Delegating to batch script with args: $windows_args"
            
            cmd /c "\"$script_dir\\install-cross-platform.bat\" $windows_args"
            
            local bat_exit_code=$?
            log_to_file "[DELEGATION] Batch script completed with exit code: $bat_exit_code"
            finalize_log $bat_exit_code
            exit $bat_exit_code
            
        # Continue with bash script if no Windows tools available
        else
            log_warning "No Windows command interpreters found - continuing with bash script"
            log_info "Note: Install PowerShell Core or ensure cmd.exe is available for better Windows support"
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    # Detect architecture
    ARCH=$(uname -m)
    log_info "Architecture: $ARCH"
    
    # Check for RTX 4090 system (Ubuntu only)
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Enhanced RTX 4090 detection
        local rtx4090_detected=false
        local nvidia_gpu_info=""
        
        if command_exists lspci; then
            # Check for RTX 4090 in lspci output
            nvidia_gpu_info=$(lspci | grep -i "vga.*nvidia" | head -1)
            if echo "$nvidia_gpu_info" | grep -qi "rtx.*4090\|geforce.*4090"; then
                rtx4090_detected=true
                log_success "RTX 4090 detected via lspci: $nvidia_gpu_info"
            fi
        fi
        
        # Alternative detection via nvidia-smi if available
        if [[ "$rtx4090_detected" == "false" ]] && command_exists nvidia-smi; then
            local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null || echo "")
            if echo "$gpu_name" | grep -qi "rtx.*4090\|geforce.*4090"; then
                rtx4090_detected=true
                log_success "RTX 4090 detected via nvidia-smi: $gpu_name"
            fi
        fi
        
        # Set flags based on detection
        if [[ "$rtx4090_detected" == "true" ]]; then
            IS_RTX4090_SYSTEM=true
            ENABLE_UBUNTU_HARDWARE_FIXES=true
            ENABLE_NVIDIA_SETUP=true
            ENABLE_ROS2=true
            log_success "RTX 4090 system - Hardware-specific optimizations enabled"
        else
            # Check for any NVIDIA GPU
            if command_exists lspci && lspci | grep -qi "nvidia"; then
                log_info "NVIDIA GPU detected (non-RTX 4090) - Standard NVIDIA setup available"
                ENABLE_NVIDIA_SETUP=true
            else
                log_info "No NVIDIA GPU detected - Skipping NVIDIA-specific setup"
            fi
        fi
        
        # Check for Z790 chipset
        if command_exists lspci && lspci | grep -qi "Z790"; then
            log_success "Z790 chipset detected - Power management optimizations available"
        fi
    fi
    
    log_success "System detection completed"
}

# Validate prerequisites
validate_prerequisites() {
    log_section "Prerequisites Validation"
    
    local missing_deps=()
    
    # Check if we're in the right directory
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        log_info "Please clone the repository to ~/dotfiles first"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    
    # Common dependencies
    if [[ "$OS_TYPE" == "linux" ]]; then
        if ! command_exists git; then missing_deps+=("git"); fi
        if ! command_exists curl; then missing_deps+=("curl"); fi
        if ! command_exists wget; then missing_deps+=("wget"); fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if ! command_exists git; then 
            log_warning "Git not found - installing Xcode Command Line Tools"
            xcode-select --install 2>/dev/null || true
        fi
        if ! command_exists brew; then
            log_warning "Homebrew not found - will install during setup"
        fi
    elif [[ "$OS_TYPE" == "windows" ]]; then
        if ! command_exists git; then
            log_warning "Git not found - Git for Windows required"
            log_info "Please install Git for Windows from https://git-scm.com/downloads"
        fi
        if ! command_exists powershell && ! command_exists pwsh; then
            log_warning "PowerShell not found - Windows PowerShell or PowerShell Core required"
        fi
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "These will be installed during setup"
    else
        log_success "All prerequisites validated"
    fi
}

# Comprehensive preflight checks for system readiness
preflight_check() {
    log_section "Preflight System Checks"
    
    local errors=0
    local warnings=0
    
    # 1. Disk Space Check
    log_info "Checking available disk space..."
    local home_partition=$(df "$HOME" | tail -1 | awk '{print $1}')
    local available_space_kb=$(df "$HOME" | tail -1 | awk '{print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))
    
    if [[ $available_space_gb -lt 5 ]]; then
        log_error "Insufficient disk space: ${available_space_gb}GB available (5GB minimum required)"
        log_info "  Partition: $home_partition"
        log_info "  Consider freeing up space before installation"
        ((errors++))
    elif [[ $available_space_gb -lt 10 ]]; then
        log_warning "Low disk space: ${available_space_gb}GB available (10GB recommended)"
        ((warnings++))
    else
        log_success "Disk space OK: ${available_space_gb}GB available"
    fi
    
    # 2. Network Connectivity Check
    log_info "Checking network connectivity..."
    local network_ok=true
    
    # Check multiple endpoints for reliability
    local endpoints=("github.com" "raw.githubusercontent.com" "google.com")
    local failed_endpoints=()
    
    for endpoint in "${endpoints[@]}"; do
        if ! ping -c 1 -W 2 "$endpoint" &>/dev/null; then
            failed_endpoints+=("$endpoint")
            network_ok=false
        fi
    done
    
    if [[ "$network_ok" == "false" ]]; then
        if [[ ${#failed_endpoints[@]} -eq ${#endpoints[@]} ]]; then
            log_error "No network connectivity detected"
            log_info "  Failed to reach: ${failed_endpoints[*]}"
            log_info "  Please check your internet connection"
            ((errors++))
        else
            log_warning "Partial network connectivity issues"
            log_info "  Failed to reach: ${failed_endpoints[*]}"
            ((warnings++))
        fi
    else
        log_success "Network connectivity OK"
    fi
    
    # 3. Git Configuration Check
    log_info "Checking Git configuration..."
    local git_user=$(git config --global user.name 2>/dev/null || echo "")
    local git_email=$(git config --global user.email 2>/dev/null || echo "")
    
    if [[ -z "$git_user" ]]; then
        log_warning "Git user.name not configured"
        log_info "  Run: git config --global user.name \"Your Name\""
        ((warnings++))
    else
        log_success "Git user configured: $git_user"
    fi
    
    if [[ -z "$git_email" ]]; then
        log_warning "Git user.email not configured"
        log_info "  Run: git config --global user.email \"your.email@example.com\""
        ((warnings++))
    else
        log_success "Git email configured: $git_email"
    fi
    
    # 4. Shell Environment Check
    log_info "Checking shell environment..."
    if [[ -n "$SHELL" ]]; then
        log_success "Current shell: $SHELL"
        
        # Check if running in restricted shell
        if [[ "$SHELL" == *"rbash"* ]] || [[ "$SHELL" == *"rksh"* ]]; then
            log_warning "Running in restricted shell - some features may not work"
            ((warnings++))
        fi
    else
        log_warning "SHELL environment variable not set"
        ((warnings++))
    fi
    
    # 5. Permission Checks
    log_info "Checking permissions..."
    
    # Check if we can write to home directory
    if ! touch "$HOME/.dotfiles_test_$$" 2>/dev/null; then
        log_error "Cannot write to home directory: $HOME"
        ((errors++))
    else
        rm -f "$HOME/.dotfiles_test_$$"
        log_success "Home directory writable"
    fi
    
    # Check sudo availability (Linux/macOS)
    if [[ "$OS_TYPE" == "linux" ]] || [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists sudo; then
            if sudo -n true 2>/dev/null; then
                log_success "Passwordless sudo available"
            else
                log_info "Sudo available (password will be required)"
            fi
        else
            log_warning "Sudo not available - some installations may fail"
            ((warnings++))
        fi
    fi
    
    # 6. Existing Installation Check
    log_info "Checking for existing installations..."
    local existing_installs=0
    
    if [[ -L "$HOME/.zshrc" ]] && [[ "$(readlink "$HOME/.zshrc")" == *"dotfiles"* ]]; then
        log_info "Found existing dotfiles installation (zsh)"
        ((existing_installs++))
    fi
    
    if [[ -L "$HOME/.gitconfig" ]] && [[ "$(readlink "$HOME/.gitconfig")" == *"dotfiles"* ]]; then
        log_info "Found existing dotfiles installation (git)"
        ((existing_installs++))
    fi
    
    if [[ $existing_installs -gt 0 ]]; then
        log_warning "Found $existing_installs existing dotfile symlinks"
        log_info "  The installer will handle conflicts gracefully"
    else
        log_success "No existing dotfiles installation detected"
    fi
    
    # 7. System Resource Check
    log_info "Checking system resources..."
    
    # Memory check
    if [[ "$OS_TYPE" == "linux" ]]; then
        local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local total_mem_gb=$((total_mem_kb / 1024 / 1024))
        
        if [[ $total_mem_gb -lt 2 ]]; then
            log_warning "Low memory: ${total_mem_gb}GB (2GB minimum recommended)"
            ((warnings++))
        else
            log_success "Memory OK: ${total_mem_gb}GB available"
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        local total_mem_bytes=$(sysctl -n hw.memsize)
        local total_mem_gb=$((total_mem_bytes / 1024 / 1024 / 1024))
        
        if [[ $total_mem_gb -lt 4 ]]; then
            log_warning "Low memory: ${total_mem_gb}GB (4GB minimum recommended)"
            ((warnings++))
        else
            log_success "Memory OK: ${total_mem_gb}GB available"
        fi
    fi
    
    # 8. Package Manager Availability
    log_info "Checking package managers..."
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists apt; then
            log_success "APT package manager available"
        elif command_exists yum; then
            log_info "YUM package manager available (limited support)"
        elif command_exists dnf; then
            log_info "DNF package manager available (limited support)"
        else
            log_error "No supported package manager found"
            ((errors++))
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            log_success "Homebrew available"
        else
            log_info "Homebrew not found (will be installed)"
        fi
    elif [[ "$OS_TYPE" == "windows" ]]; then
        if command_exists winget; then
            log_success "Windows Package Manager (winget) available"
        elif command_exists choco; then
            log_success "Chocolatey available"
        else
            log_warning "No package manager found (manual installation may be required)"
            ((warnings++))
        fi
    fi
    
    # Summary
    echo
    log_info "Preflight Check Summary:"
    log_info "  Errors: $errors"
    log_info "  Warnings: $warnings"
    
    if [[ $errors -gt 0 ]]; then
        log_error "❌ Preflight checks failed with $errors error(s)"
        log_info "Please resolve the errors above before continuing"
        
        # Ask user if they want to continue anyway
        if [[ "$FORCE_INSTALL" != "true" ]]; then
            read -p "Do you want to continue anyway? (not recommended) [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled"
                exit 1
            else
                log_warning "Continuing despite errors (forced by user)"
            fi
        else
            log_warning "Continuing despite errors (--force flag used)"
        fi
    elif [[ $warnings -gt 0 ]]; then
        log_warning "⚠️  Preflight checks completed with $warnings warning(s)"
        log_info "Installation can proceed, but some features may be limited"
    else
        log_success "✅ All preflight checks passed!"
    fi
    
    return 0
}

# Profile management functions
load_profile() {
    local profile_name="$1"
    local profile_path="$PROFILES_DIR/${profile_name}.profile"
    
    if [[ ! -f "$profile_path" ]]; then
        log_error "Profile not found: $profile_path"
        log_info "Available profiles:"
        ls "$PROFILES_DIR"/*.profile 2>/dev/null | while read -r p; do
            log_info "  - $(basename "$p" .profile)"
        done
        return 1
    fi
    
    log_info "Loading machine profile: $profile_name"
    
    # Source the profile
    source "$profile_path" || {
        log_error "Failed to load profile: $profile_name"
        return 1
    }
    
    LOADED_PROFILE="$profile_name"
    log_success "Profile loaded: $profile_name"
    log_info "Profile description: $PROFILE_DESCRIPTION"
    
    # Run profile pre-install if defined
    if declare -f profile_pre_install >/dev/null; then
        log_info "Running profile pre-install setup..."
        profile_pre_install
    fi
    
    return 0
}

detect_machine_profile() {
    log_section "Machine Profile Detection"
    
    # Check if profile already specified
    if [[ -n "$MACHINE_PROFILE" ]]; then
        log_info "Profile specified via environment: $MACHINE_PROFILE"
        load_profile "$MACHINE_PROFILE"
        return $?
    fi
    
    # Auto-detect based on system characteristics
    local detected_profile=""
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Check for RTX 4090 desktop
        if [[ "$IS_RTX4090_SYSTEM" == "true" ]]; then
            detected_profile="desktop-rtx4090"
            log_info "Detected RTX 4090 system - suggesting desktop profile"
        # Check for server/headless
        elif [[ ! -v DISPLAY ]] || [[ -z "$DISPLAY" ]]; then
            detected_profile="server-minimal"
            log_info "No display detected - suggesting server profile"
        # Check for VM/container
        elif systemd-detect-virt -q 2>/dev/null; then
            detected_profile="server-minimal"
            log_info "Virtual environment detected - suggesting minimal profile"
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        # Check for Apple Silicon
        if [[ "$ARCH" == "arm64" ]]; then
            detected_profile="macbook-m1"
            log_info "Apple Silicon Mac detected - suggesting MacBook profile"
        fi
    fi
    
    # If we detected a profile, offer to use it
    if [[ -n "$detected_profile" ]]; then
        log_info "Suggested profile: $detected_profile"
        echo
        read -p "Use detected profile '$detected_profile'? (Y/n): " -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            load_profile "$detected_profile"
            return $?
        fi
    fi
    
    # Otherwise, show available profiles
    log_info "Available machine profiles:"
    local profiles=()
    while IFS= read -r profile_file; do
        local profile_name=$(basename "$profile_file" .profile)
        profiles+=("$profile_name")
        
        # Source profile temporarily to get description
        local desc=""
        if source "$profile_file" 2>/dev/null && [[ -n "$PROFILE_DESCRIPTION" ]]; then
            desc=" - $PROFILE_DESCRIPTION"
        fi
        
        log_info "  • $profile_name$desc"
    done < <(find "$PROFILES_DIR" -name "*.profile" -type f | sort)
    
    # Ask user to select
    echo
    read -p "Enter profile name (or press Enter to skip): " selected_profile
    
    if [[ -n "$selected_profile" ]]; then
        load_profile "$selected_profile"
    else
        log_info "No profile selected - using default configuration"
    fi
}

# Apply profile-specific package installations
apply_profile_packages() {
    if [[ -z "$LOADED_PROFILE" ]]; then
        return 0
    fi
    
    log_section "Installing Profile-Specific Packages"
    
    # Install desktop packages if defined
    if [[ -n "${DESKTOP_PACKAGES[@]}" ]] && [[ "$MACHINE_TYPE" == "desktop" ]]; then
        log_info "Installing desktop packages..."
        for package in "${DESKTOP_PACKAGES[@]}"; do
            install_package_idempotent "$package" "$package"
        done
    fi
    
    # Install server packages if defined
    if [[ -n "${SERVER_PACKAGES[@]}" ]] && [[ "$MACHINE_TYPE" == "server" ]]; then
        log_info "Installing server packages..."
        for package in "${SERVER_PACKAGES[@]}"; do
            install_package_idempotent "$package" "$package"
        done
    fi
    
    # Install Homebrew packages for macOS
    if [[ "$OS_TYPE" == "macos" ]] && [[ -n "${BREW_PACKAGES[@]}" ]]; then
        log_info "Installing Homebrew packages..."
        for package in "${BREW_PACKAGES[@]}"; do
            install_package_idempotent "$package" "$package"
        done
    fi
    
    # Install Homebrew cask packages for macOS
    if [[ "$OS_TYPE" == "macos" ]] && [[ -n "${BREW_CASK_PACKAGES[@]}" ]]; then
        log_info "Installing Homebrew cask packages..."
        for package in "${BREW_CASK_PACKAGES[@]}"; do
            if ! brew list --cask "$package" &>/dev/null; then
                log_info "Installing $package..."
                brew install --cask "$package" || log_warning "Failed to install $package"
            else
                log_info "$package already installed"
            fi
        done
    fi
}

# Restore point and rollback functionality
create_restore_point() {
    local name="${1:-auto}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local restore_dir="$HOME/.dotfiles_restore/${name}-${timestamp}"
    
    log_section "Creating Restore Point: $name"
    
    # Create restore directory
    if ! create_directory_idempotent "$restore_dir" "restore point directory"; then
        log_error "Failed to create restore point directory"
        return 1
    fi
    
    # Save current dotfiles state
    log_info "Saving current dotfiles state..."
    
    # Save list of stowed packages
    if command_exists stow; then
        cd "$DOTFILES_DIR"
        local stowed_packages=()
        for package in zsh git tmux nvim; do
            if [[ -L "$HOME/.$(basename $package)" ]] || [[ -L "$HOME/.config/$(basename $package)" ]]; then
                stowed_packages+=("$package")
            fi
        done
        echo "${stowed_packages[@]}" > "$restore_dir/stowed_packages.txt"
        log_info "Saved stowed packages: ${stowed_packages[*]}"
    fi
    
    # Save current configurations
    local configs_to_save=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
    )
    
    for config in "${configs_to_save[@]}"; do
        if [[ -e "$config" ]]; then
            local config_name=$(basename "$config")
            if [[ -d "$config" ]]; then
                log_info "Backing up directory: $config_name"
                cp -rL "$config" "$restore_dir/$config_name" 2>/dev/null || log_warning "Failed to backup $config_name"
            else
                log_info "Backing up file: $config_name"
                cp -L "$config" "$restore_dir/$config_name" 2>/dev/null || log_warning "Failed to backup $config_name"
            fi
        fi
    done
    
    # Save system package list (for reference)
    if [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists dpkg; then
            dpkg -l > "$restore_dir/packages_dpkg.txt"
        fi
        if command_exists snap; then
            snap list > "$restore_dir/packages_snap.txt" 2>/dev/null
        fi
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            brew list > "$restore_dir/packages_brew.txt"
            brew list --cask > "$restore_dir/packages_brew_cask.txt" 2>/dev/null
        fi
    fi
    
    # Save metadata
    cat > "$restore_dir/metadata.txt" << EOF
Restore Point: $name
Created: $(date)
Hostname: $(hostname)
User: $(whoami)
OS: $OS_TYPE $OS_VERSION
Profile: ${LOADED_PROFILE:-none}
Script Version: $(git -C "$DOTFILES_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
EOF
    
    # Create restore script
    cat > "$restore_dir/restore.sh" << 'EOF'
#!/bin/bash
# Restore script for this restore point

RESTORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$HOME/dotfiles"

echo "Restoring from: $RESTORE_DIR"
echo "This will restore your dotfiles to the state saved at: $(grep Created "$RESTORE_DIR/metadata.txt" | cut -d' ' -f2-)"
echo
read -p "Are you sure you want to restore? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 1
fi

# Unstow current dotfiles
if command -v stow >/dev/null 2>&1 && [[ -f "$RESTORE_DIR/stowed_packages.txt" ]]; then
    cd "$DOTFILES_DIR"
    for package in zsh git tmux nvim; do
        stow -D "$package" 2>/dev/null
    done
fi

# Restore backed up files
for file in "$RESTORE_DIR"/*; do
    filename=$(basename "$file")
    case "$filename" in
        metadata.txt|restore.sh|stowed_packages.txt|packages_*.txt)
            continue
            ;;
        nvim)
            mkdir -p "$HOME/.config"
            rm -rf "$HOME/.config/nvim"
            cp -r "$file" "$HOME/.config/nvim"
            echo "Restored: .config/nvim"
            ;;
        *)
            cp -f "$file" "$HOME/.$filename"
            echo "Restored: .$filename"
            ;;
    esac
done

echo
echo "Restore complete!"
echo "You may need to restart your terminal for changes to take effect."
EOF
    
    chmod +x "$restore_dir/restore.sh"
    
    # Save restore point info
    echo "$restore_dir" >> "$HOME/.dotfiles_restore/restore_points.log"
    
    log_success "Restore point created: $restore_dir"
    log_info "To restore, run: $restore_dir/restore.sh"
    
    return 0
}

list_restore_points() {
    log_section "Available Restore Points"
    
    if [[ ! -d "$HOME/.dotfiles_restore" ]] || [[ ! -f "$HOME/.dotfiles_restore/restore_points.log" ]]; then
        log_info "No restore points found"
        return 1
    fi
    
    local count=0
    while IFS= read -r restore_dir; do
        if [[ -d "$restore_dir" ]] && [[ -f "$restore_dir/metadata.txt" ]]; then
            ((count++))
            echo
            echo "[$count] $(basename "$restore_dir")"
            grep -E "^(Created|Profile|Hostname):" "$restore_dir/metadata.txt" | sed 's/^/    /'
        fi
    done < "$HOME/.dotfiles_restore/restore_points.log"
    
    if [[ $count -eq 0 ]]; then
        log_info "No valid restore points found"
        return 1
    fi
    
    return 0
}

restore_from_point() {
    local point_name="$1"
    
    if [[ -z "$point_name" ]]; then
        # Interactive selection
        if ! list_restore_points; then
            return 1
        fi
        
        echo
        read -p "Enter restore point number or name: " selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            # Numeric selection
            local count=0
            while IFS= read -r restore_dir; do
                if [[ -d "$restore_dir" ]]; then
                    ((count++))
                    if [[ $count -eq $selection ]]; then
                        point_name="$restore_dir"
                        break
                    fi
                fi
            done < "$HOME/.dotfiles_restore/restore_points.log"
        else
            # Name selection
            point_name="$HOME/.dotfiles_restore/$selection"
        fi
    else
        # Direct path or name provided
        if [[ ! "$point_name" =~ ^/ ]]; then
            point_name="$HOME/.dotfiles_restore/$point_name"
        fi
    fi
    
    if [[ ! -d "$point_name" ]] || [[ ! -f "$point_name/restore.sh" ]]; then
        log_error "Invalid restore point: $point_name"
        return 1
    fi
    
    log_info "Restoring from: $point_name"
    bash "$point_name/restore.sh"
}

cleanup_old_restore_points() {
    local keep_count="${1:-5}"
    
    log_info "Cleaning up old restore points (keeping $keep_count most recent)..."
    
    if [[ ! -f "$HOME/.dotfiles_restore/restore_points.log" ]]; then
        return 0
    fi
    
    # Get list of valid restore points sorted by date
    local valid_points=()
    while IFS= read -r restore_dir; do
        if [[ -d "$restore_dir" ]]; then
            valid_points+=("$restore_dir")
        fi
    done < "$HOME/.dotfiles_restore/restore_points.log"
    
    local total=${#valid_points[@]}
    if [[ $total -le $keep_count ]]; then
        log_info "Only $total restore points exist, no cleanup needed"
        return 0
    fi
    
    # Remove oldest restore points
    local remove_count=$((total - keep_count))
    log_info "Removing $remove_count old restore points..."
    
    for ((i=0; i<$remove_count; i++)); do
        local old_point="${valid_points[$i]}"
        if [[ -d "$old_point" ]]; then
            log_info "Removing: $(basename "$old_point")"
            rm -rf "$old_point"
        fi
    done
    
    # Rebuild restore points log
    local temp_log=$(mktemp)
    for ((i=$remove_count; i<$total; i++)); do
        echo "${valid_points[$i]}" >> "$temp_log"
    done
    mv "$temp_log" "$HOME/.dotfiles_restore/restore_points.log"
    
    log_success "Cleanup complete"
}

# Archive existing dotfiles with .old suffix for safety
# Legacy archive function removed - replaced by Stow --adopt method

# Remove existing dotfiles to allow clean overwrite
# Legacy remove function removed - replaced by Stow --adopt method

# Enhanced backup function (keeping for reference and additional safety)
create_backup() {
    log_section "Creating Additional Backup"
    
    if ! mkdir -p "$BACKUP_DIR"; then
        log_error "Failed to create backup directory: $BACKUP_DIR"
        return 1
    fi
    
    local files=(".zshrc" ".bashrc" ".gitconfig" ".gitignore_global" ".tmux.conf" ".vimrc")
    local backed_up=0
    
    for file in "${files[@]}"; do
        local target="$HOME/$file"
        if [[ -f "$target.old" ]]; then
            log_info "Backing up archived $file.old to backup directory"
            
            # Use timeout to prevent hanging on file operations
            if run_with_timeout 10 "backup-$file" cp "$target.old" "$BACKUP_DIR/"; then
                backed_up=$((backed_up + 1))
                log_info "Successfully backed up $file.old"
            else
                log_error "Failed to backup $file.old (timeout or error)"
            fi
        fi
    done
    
    # Backup archived Neovim config if it exists
    if [[ -d "$HOME/.config/nvim.old" ]]; then
        log_info "Backing up archived Neovim configuration"
        
        if run_with_timeout 30 "backup-nvim" cp -r "$HOME/.config/nvim.old" "$BACKUP_DIR/nvim_config.old"; then
            backed_up=$((backed_up + 1))
            log_success "Archived Neovim configuration backed up"
        else
            log_error "Failed to backup archived Neovim configuration"
        fi
    fi
    
    if [[ $backed_up -gt 0 ]]; then
        log_success "Backed up $backed_up archived items to $BACKUP_DIR"
    else
        log_info "No archived files found to backup"
        rmdir "$BACKUP_DIR" 2>/dev/null || true
    fi
}

# Install stow if needed and check availability
install_stow() {
    # First check if stow is already installed
    if command_exists stow; then
        log_success "GNU Stow is already installed: $(which stow)"
        return 0
    fi
    
    log_info "GNU Stow not found - attempting installation..."
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        if command_exists apt; then
            log_info "Installing GNU Stow via apt..."
            
            # Try to install with sudo (handle password prompt gracefully)
            if sudo apt update >/dev/null 2>&1 && sudo apt install -y stow >/dev/null 2>&1; then
                if command_exists stow; then
                    log_success "GNU Stow installed successfully: $(which stow)"
                    return 0
                else
                    log_error "Installation appeared successful but stow command not found"
                fi
            else
                log_error "Failed to install GNU Stow via apt"
                log_info "This could be due to:"
                log_info "  - No sudo privileges"
                log_info "  - Network connectivity issues"
                log_info "  - Package repository problems"
            fi
        else
            log_error "apt package manager not found"
        fi
        
        # Provide manual installation instructions
        log_info "Manual installation options:"
        log_info "  Ubuntu/Debian: sudo apt install stow"
        log_info "  CentOS/RHEL:   sudo yum install stow"
        log_info "  Fedora:        sudo dnf install stow"
        log_info "  Arch:          sudo pacman -S stow"
        
    elif [[ "$OS_TYPE" == "macos" ]]; then
        if command_exists brew; then
            log_info "Installing GNU Stow via Homebrew..."
            if brew install stow >/dev/null 2>&1; then
                if command_exists stow; then
                    log_success "GNU Stow installed successfully: $(which stow)"
                    return 0
                else
                    log_error "Installation appeared successful but stow command not found"
                fi
            else
                log_error "Failed to install GNU Stow via Homebrew"
            fi
        else
            log_error "Homebrew not found"
            log_info "Install Homebrew first: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            log_info "Then install stow: brew install stow"
        fi
        
    elif [[ "$OS_TYPE" == "windows" ]]; then
        log_error "GNU Stow installation on Windows requires manual setup"
        log_info "Consider using WSL2 or installing via Cygwin/MSYS2"
    fi
    
    return 1
}

# Check if stow is available (simpler check after installation attempt)
check_stow_availability() {
    if command_exists stow; then
        log_info "GNU Stow is available: $(which stow)"
        return 0
    else
        log_error "GNU Stow is not available"
        return 1
    fi
}

# Timeout wrapper for commands that might hang
run_with_timeout() {
    local timeout_duration="$1"
    local command_name="$2"
    shift 2
    
    log_info "Running $command_name (timeout: ${timeout_duration}s)"
    log_to_file "Command: $*"
    
    if command_exists timeout; then
        # Capture output in a variable to avoid tee issues
        local output
        if output=$(timeout "$timeout_duration" "$@" 2>&1); then
            log_info "$command_name completed successfully"
            log_to_file "SUCCESS: $command_name completed"
            [[ -n "$output" ]] && log_to_file "Output: $output"
            return 0
        else
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                log_error "$command_name timed out after ${timeout_duration}s"
                log_to_file "TIMEOUT: $command_name exceeded ${timeout_duration}s limit"
            else
                log_error "$command_name failed with exit code $exit_code"
                log_to_file "FAILURE: $command_name exited with code $exit_code"
            fi
            [[ -n "$output" ]] && log_to_file "Error output: $output"
            return $exit_code
        fi
    else
        # Fallback: run without timeout but warn user
        log_warning "timeout command not available - running $command_name without timeout"
        log_to_file "WARNING: No timeout protection for $command_name"
        "$@"
    fi
}

# Manual symlink creation as fallback when stow fails
create_manual_symlinks() {
    local package="$1"
    
    log_info "Creating manual symlinks for $package as fallback"
    
    if [[ ! -d "$package" ]]; then
        log_error "Package directory not found: $package"
        return 1
    fi
    
    case "$package" in
        "zsh")
            if [[ -f "zsh/.zshrc" ]]; then
                ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" 2>/dev/null && \
                    log_success "Manually linked .zshrc" || \
                    log_error "Failed to link .zshrc"
            fi
            ;;
        "git")
            if [[ -f "git/.gitconfig" ]]; then
                ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig" 2>/dev/null && \
                    log_success "Manually linked .gitconfig" || \
                    log_error "Failed to link .gitconfig"
            fi
            if [[ -f "git/.gitignore_global" ]]; then
                ln -sf "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global" 2>/dev/null && \
                    log_success "Manually linked .gitignore_global"
            fi
            ;;
        "tmux")
            if [[ -f "tmux/.tmux.conf" ]]; then
                ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null && \
                    log_success "Manually linked .tmux.conf" || \
                    log_error "Failed to link .tmux.conf"
            fi
            ;;
        "nvim")
            if [[ -d "nvim/.config/nvim" ]]; then
                mkdir -p "$HOME/.config" 2>/dev/null
                ln -sf "$DOTFILES_DIR/nvim/.config/nvim" "$HOME/.config/nvim" 2>/dev/null && \
                    log_success "Manually linked nvim config" || \
                    log_error "Failed to link nvim config"
            fi
            ;;
        *)
            log_warning "Manual symlink creation not implemented for $package"
            return 1
            ;;
    esac
    
    return 0
}

# Graceful Stow function with conflict resolution and timeout handling
stow_with_grace() {
    local package="$1"
    local force="${2:-false}"
    
    log_info "Processing dotfiles package: $package"
    
    # Verify stow is available (should be installed by now)
    if ! check_stow_availability; then
        log_error "GNU Stow is not available - falling back to manual symlinks"
        create_manual_symlinks "$package"
        return $?
    fi
    
    log_info "Using GNU Stow for $package..."
    
    # First, try normal stow - this will fail if conflicts exist
    if run_with_timeout 30 "stow-install" stow -v "$package" 2>/dev/null; then
        log_success "Stowed $package successfully"
        return 0
    fi
    
    # If conflicts exist, use stow --adopt to take over existing files
    log_info "Conflicts detected - using Stow's --adopt method to take over existing files"
    log_info "This preserves the ability to unstow and restore originals later"
    
    if run_with_timeout 30 "stow-adopt" stow --adopt -v "$package"; then
        log_success "Adopted and stowed $package successfully"
        log_info "Original files are now managed by Stow and can be restored with 'stow -D $package'"
        
        # Reset the dotfiles to our version after adoption
        log_info "Resetting $package to our dotfiles version..."
        cd "$DOTFILES_DIR"
        if git checkout HEAD -- "$package"/ 2>/dev/null; then
            log_success "Reset $package to our configuration"
        else
            log_info "No git reset needed for $package"
        fi
        
        return 0
    else
        log_warning "Stow --adopt failed for $package, trying manual symlinks as fallback"
        create_manual_symlinks "$package"
        return $?
    fi
}

# Unstow dotfiles (reverse the stow process)
unstow_dotfiles() {
    log_section "Unstowing Dotfiles"
    log_info "This will remove symlinks and restore original files"
    
    cd "$DOTFILES_DIR"
    local packages=("zsh" "git" "tmux" "nvim")
    
    for package in "${packages[@]}"; do
        if [[ -d "$package" ]]; then
            log_info "Unstowing $package..."
            if stow -D -v "$package"; then
                log_success "Unstowed $package - original files restored"
            else
                log_warning "Failed to unstow $package"
            fi
        fi
    done
    
    log_success "Dotfiles unstowed - system restored to original state"
    log_info "To reinstall: run the script again"
}

# Quick health check for dotfiles installation
health_check() {
    log_section "Dotfiles Installation Health Check"
    
    local issues=0
    
    # Check symlinks
    local files=(".zshrc" ".gitconfig" ".tmux.conf" ".config/nvim")
    for file in "${files[@]}"; do
        if [[ -L "$HOME/$file" ]]; then
            local target=$(readlink "$HOME/$file")
            if [[ "$target" == *"dotfiles"* ]]; then
                log_success "✓ $file correctly symlinked"
            else
                log_warning "⚠ $file symlinked elsewhere: $target"
                ((issues++))
            fi
        else
            log_error "✗ $file not symlinked"
            ((issues++))
        fi
    done
    
    # Check shell plugins
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins" ]]; then
        local broken_plugins=$(ls "$HOME/.oh-my-zsh/custom/plugins" | grep ":https" | wc -l)
        if [[ $broken_plugins -eq 0 ]]; then
            log_success "✓ Shell plugins healthy (no :https suffixes)"
        else
            log_warning "⚠ Found $broken_plugins broken plugin directories"
            ((issues++))
        fi
    fi
    
    # Check NvChad
    if [[ -d "$HOME/.local/share/nvim/nvchad/base46" ]]; then
        local cache_files=$(ls "$HOME/.local/share/nvim/nvchad/base46" | wc -l)
        if [[ $cache_files -gt 10 ]]; then
            log_success "✓ NvChad base46 cache healthy ($cache_files files)"
        else
            log_warning "⚠ NvChad cache incomplete ($cache_files files)"
            ((issues++))
        fi
    else
        log_warning "⚠ NvChad cache directory missing"
        ((issues++))
    fi
    
    # Check NvChad functionality
    if command_exists nvim; then
        if nvim --headless -c "echo 'NvChad health check'" -c "qa" 2>/dev/null; then
            log_success "✓ NvChad loads without errors"
        else
            log_warning "⚠ NvChad has loading issues"
            ((issues++))
        fi
    fi
    
    # Summary
    echo
    if [[ $issues -eq 0 ]]; then
        log_success "🎉 Dotfiles installation is healthy! All systems operational."
    else
        log_warning "⚠️ Found $issues issues. Consider running the installer again."
        echo
        echo "Quick fixes:"
        echo "• Re-run installer: ./scripts/install-cross-platform.sh --minimal"
        echo "• Fix plugins only: ./scripts/install-cross-platform.sh (install shell framework)"
        echo "• Reset everything: ./scripts/install-cross-platform.sh --unstow && ./scripts/install-cross-platform.sh"
    fi
}

# Initialize NvChad for optimal first-run experience
initialize_nvchad() {
    log_info "Initializing NvChad plugins and cache..."
    
    # First, initialize base46 cache to prevent errors
    if command_exists nvim; then
        log_info "Generating NvChad base46 cache..."
        if run_with_timeout 30 "nvchad-cache" nvim --headless -c "lua require('base46').load_all_highlights()" -c "qa" 2>/dev/null; then
            log_success "Base46 cache generated successfully"
        else
            log_warning "Base46 cache generation had issues but NvChad will still work"
        fi
        
        # Initialize lazy plugins (download and setup)
        log_info "Installing NvChad plugins via Lazy..."
        if run_with_timeout 60 "nvchad-lazy" nvim --headless -c "Lazy! sync" -c "qa" 2>/dev/null; then
            log_success "NvChad plugins installed successfully"
        else
            log_warning "Plugin installation had issues but will complete on first run"
        fi
        
        # Test that basic functionality works
        log_info "Testing NvChad functionality..."
        if run_with_timeout 10 "nvchad-test" nvim --headless -c "echo 'NvChad test successful'" -c "qa" 2>/dev/null; then
            log_success "NvChad functionality verified"
            return 0
        else
            log_warning "NvChad test had issues but should work on first run"
            return 1
        fi
    else
        log_error "Neovim not found - cannot initialize NvChad"
        return 1
    fi
}

# Install dependencies based on OS
install_dependencies() {
    log_section "Installing Dependencies"
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        log_info "Installing Linux dependencies..."
        
        # Try to detect if we need sudo
        if [[ $EUID -ne 0 ]] && command_exists sudo; then
            local SUDO="sudo"
        else
            local SUDO=""
        fi
        
        # Basic packages
        if command_exists apt; then
            log_info "Using apt package manager"
            $SUDO apt update || log_warning "Could not update package lists"
            
            local packages=(
                "stow" "git" "curl" "wget" "zsh" "tmux" "neovim"
                "build-essential" "software-properties-common"
            )
            
            for package in "${packages[@]}"; do
                install_package_idempotent "$package" "$package"
            done
            
        else
            log_warning "APT not available - manual dependency installation required"
        fi
        
    elif [[ "$OS_TYPE" == "macos" ]]; then
        log_info "Installing macOS dependencies..."
        
        # Install Homebrew if not present (Apple Silicon only)
        if ! command_exists brew; then
            if [[ "$ARCH" == "arm64" ]]; then
                log_info "Installing Homebrew for Apple Silicon..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                    log_error "Failed to install Homebrew"
                    return 1
                }
                
                # Add Homebrew to PATH for current session
                export PATH="/opt/homebrew/bin:$PATH"
                log_success "Homebrew installed at /opt/homebrew"
            else
                log_error "Intel Mac detected - Homebrew installation skipped"
                log_info "Apple Silicon Mac required for full macOS setup"
                return 1
            fi
        fi
        
        # Install packages
        local packages=("stow" "git" "neovim" "tmux" "zsh")
        
        for package in "${packages[@]}"; do
            install_package_idempotent "$package" "$package"
        done
    
    elif [[ "$OS_TYPE" == "windows" ]]; then
        log_info "Installing Windows dependencies..."
        
        # Check for package managers
        if command_exists winget; then
            log_info "Using winget package manager..."
            
            # Essential packages via winget
            local packages=(
                "Git.Git:Git"
                "Neovim.Neovim:Neovim"
            )
            
            for package_spec in "${packages[@]}"; do
                local package_id="${package_spec%%:*}"
                local package_name="${package_spec##*:}"
                install_package_idempotent "$package_id" "$package_name"
            done
            
        elif command_exists choco; then
            log_info "Using Chocolatey package manager..."
            
            # Essential packages via chocolatey
            local packages=("git" "neovim" "powershell-core")
            
            for package in "${packages[@]}"; do
                install_package_idempotent "$package" "$package"
            done
            
        else
            log_warning "No package manager found (winget or chocolatey)"
            log_info "Manual installation required for:"
            log_info "  - Git for Windows: https://git-scm.com/downloads"
            log_info "  - Neovim: https://neovim.io/"
            log_info "  - PowerShell Core: https://github.com/PowerShell/PowerShell"
        fi
    fi
    
    log_success "Dependencies installation completed"
}

# Ubuntu-specific comprehensive software installation
ubuntu_comprehensive_setup() {
    if [[ "$ENABLE_FULL_UBUNTU_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "Ubuntu 22.04 Comprehensive Software Setup"
    
    # Essential APT packages
    log_info "Installing essential APT packages..."
    local apt_packages=(
        "git-all" "gitg" "vim" "neovim" "htop" "tree" "unzip" "curl" "wget"
        "vlc" "thunderbird" "synaptic" "gparted" "dconf-editor"
        "gnome-tweaks" "gnome-shell-extensions" "ubuntu-restricted-extras"
        "unattended-upgrades" "tmux" "zsh" "build-essential" "gh"
        "python3-pip" "python3-dev" "python3-setuptools" "python3-wheel" "nodejs" "npm" "tmux" "stow"
    )
    
    for package in "${apt_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "Installing $package..."
            sudo apt install -y "$package" || log_warning "Failed to install $package"
        else
            log_info "$package already installed"
        fi
    done
    
    # Google Chrome via deb package
    if ! command_exists google-chrome; then
        log_info "Installing Google Chrome..."
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
        echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
        sudo apt update
        sudo apt install -y google-chrome-stable
    else
        log_info "Google Chrome already installed"
    fi
    
    # VSCode via snap (if not already installed)
    if ! snap list | grep -q "code"; then
        log_info "Installing Visual Studio Code..."
        sudo snap install code --classic || log_warning "Failed to install VSCode"
    else
        log_info "Visual Studio Code already installed"
    fi
    
    # Docker if not installed
    if ! command_exists docker; then
        log_info "Installing Docker..."
        ubuntu_docker_setup
    else
        log_info "Docker already installed"
    fi
    
    # NVM and Node.js if not installed
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
    else
        log_info "NVM already installed"
    fi
    
    # Anaconda3 if not installed
    if [[ ! -d "$HOME/anaconda3" ]] && [[ ! -d "$HOME/miniconda3" ]]; then
        log_info "Anaconda3 not found - installing..."
        install_python_env
    else
        log_info "Python environment (Anaconda3/Miniconda) already installed"
    fi
    
    # Oh-My-Zsh if not installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-My-Zsh..."
        install_shell_framework
    else
        log_info "Oh-My-Zsh already installed"
    fi
    
    # Obsidian AppImage if not installed
    if [[ ! -f "$HOME/Obsidian.AppImage" ]]; then
        log_info "Installing Obsidian..."
        wget -O "$HOME/Obsidian.AppImage" "https://github.com/obsidianmd/obsidian-releases/releases/latest/download/Obsidian-1.4.16.AppImage"
        chmod +x "$HOME/Obsidian.AppImage"
        
        # Create desktop entry
        cat > "$HOME/.local/share/applications/obsidian.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Exec=$HOME/Obsidian.AppImage --no-sandbox %U
Icon=obsidian
StartupWMClass=obsidian
Comment=Obsidian
MimeType=x-scheme-handler/obsidian;
Categories=Office;
EOF
    else
        log_info "Obsidian already installed"
    fi
    
    # Snap applications
    local snap_packages=(
        "vlc"
        "firefox"
        "curl"
    )
    
    for package in "${snap_packages[@]}"; do
        if ! snap list | grep -q "$package"; then
            log_info "Installing $package via snap..."
            sudo snap install "$package" || log_warning "Failed to install $package via snap"
        else
            log_info "$package already installed via snap"
        fi
    done
    
    # Flatpak applications (if user wants them)
    read -p "Install additional Flatpak applications? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! command_exists flatpak; then
            log_info "Installing Flatpak..."
            sudo apt install -y flatpak gnome-software-plugin-flatpak
        fi
        
        # Ensure Flathub remote is added
        log_info "Configuring Flathub repository..."
        if ! flatpak remote-list | grep -q flathub; then
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            log_success "Flathub repository added"
        else
            log_info "Flathub repository already configured"
        fi
        
        local flatpak_apps=(
            "org.gimp.GIMP"
            "org.inkscape.Inkscape"
            "com.spotify.Client"
            "org.signal.Signal"
            "com.discordapp.Discord"
            "com.slack.Slack"
        )
        
        for app in "${flatpak_apps[@]}"; do
            if ! flatpak list | grep -q "$app"; then
                log_info "Installing $app via Flatpak..."
                log_info "This may take several minutes for first-time Flatpak installations..."
                
                # Use run_with_timeout for better timeout handling
                if run_with_timeout 300 "flatpak-install-$app" flatpak install -y flathub "$app"; then
                    log_success "$app installed successfully"
                else
                    log_warning "Failed to install $app (timeout or error)"
                    log_info "You can install it manually: flatpak install flathub $app"
                fi
            else
                log_info "$app already installed via Flatpak"
            fi
        done
    fi
    
    # Enable firewall
    log_info "Configuring firewall..."
    sudo ufw enable || true
    sudo ufw default deny incoming || true
    sudo ufw default allow outgoing || true
    
    log_success "Ubuntu comprehensive setup completed"
}

# RTX 4090 + Z790 hardware fixes
ubuntu_hardware_fixes() {
    if [[ "$ENABLE_UBUNTU_HARDWARE_FIXES" != "true" ]]; then
        return 0
    fi
    
    log_section "RTX 4090 + Z790 Hardware Fixes"
    
    log_warning "Hardware-specific fixes require existing scripts"
    log_info "Looking for RTX 4090 suspend scripts..."
    
    # Check for existing scripts
    local scripts_found=false
    
    if [[ -f "$HOME/rtx4090_suspend_fix.sh" ]]; then
        log_info "Found RTX 4090 suspend fix script"
        scripts_found=true
        
        read -p "Apply RTX 4090 suspend fixes? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Applying RTX 4090 suspend fixes..."
            chmod +x "$HOME/rtx4090_suspend_fix.sh"
            sudo "$HOME/rtx4090_suspend_fix.sh" || log_warning "RTX 4090 fix script failed"
            
            # Additional fixes if scripts exist
            if [[ -f "$HOME/disable_usb_wakeup_manual.sh" ]]; then
                chmod +x "$HOME/disable_usb_wakeup_manual.sh"
                sudo "$HOME/disable_usb_wakeup_manual.sh" || log_warning "USB wakeup fix failed"
            fi
            
            if [[ -f "$HOME/rtx4090-suspend.service" ]]; then
                sudo cp "$HOME/rtx4090-suspend.service" /etc/systemd/system/
                sudo systemctl daemon-reload
                sudo systemctl enable rtx4090-suspend.service || log_warning "Failed to enable suspend service"
            fi
        fi
    fi
    
    if [[ "$scripts_found" != "true" ]]; then
        log_warning "RTX 4090 suspend fix scripts not found at expected locations"
        log_info "Hardware fixes will be skipped - refer to manual guide for setup"
    fi
}

# RTX 4090 specific NVIDIA driver and CUDA setup
ubuntu_nvidia_setup() {
    if [[ "$ENABLE_NVIDIA_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "NVIDIA Driver and CUDA Setup"
    
    # Detect RTX 4090 specifically
    local gpu_info=""
    local is_rtx4090=false
    local current_driver=""
    local recommended_driver=""
    
    # Check if NVIDIA GPU is present
    if command_exists lspci && lspci | grep -qi "nvidia"; then
        gpu_info=$(lspci | grep -i "vga.*nvidia" | head -1)
        log_info "Detected NVIDIA GPU: $gpu_info"
        
        # Check specifically for RTX 4090
        if echo "$gpu_info" | grep -qi "rtx.*4090\|geforce.*4090"; then
            is_rtx4090=true
            log_success "RTX 4090 detected - applying optimized configuration"
        else
            log_info "Non-RTX 4090 NVIDIA GPU detected - standard configuration"
        fi
    else
        log_warning "No NVIDIA GPU detected - skipping NVIDIA setup"
        return 0
    fi
    
    # Check current driver if nvidia-smi exists
    if command_exists nvidia-smi; then
        current_driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null || echo "Unknown")
        log_info "Current NVIDIA driver: $current_driver"
    fi
    
    # Get recommended driver
    if command_exists ubuntu-drivers; then
        recommended_driver=$(ubuntu-drivers devices 2>/dev/null | grep "recommended" | awk '{print $3}' | head -1)
        if [[ -n "$recommended_driver" ]]; then
            log_info "Recommended driver: $recommended_driver"
        fi
    fi
    
    # Prompt for installation/update
    local should_install=false
    if [[ -z "$current_driver" || "$current_driver" == "Unknown" ]]; then
        log_warning "No NVIDIA driver detected"
        read -p "Install NVIDIA drivers? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && should_install=true
    else
        read -p "Update/reinstall NVIDIA drivers? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && should_install=true
    fi
    
    if [[ "$should_install" == "true" ]]; then
        log_info "Installing NVIDIA drivers..."
        
        # Add NVIDIA PPA for latest drivers
        sudo add-apt-repository ppa:graphics-drivers/ppa -y
        sudo apt update
        
        # Install drivers
        if [[ -n "$recommended_driver" ]]; then
            log_info "Installing recommended driver: $recommended_driver"
            sudo apt install -y "$recommended_driver" || {
                log_warning "Failed to install specific driver, trying autoinstall"
                sudo ubuntu-drivers autoinstall
            }
        else
            log_info "Using ubuntu-drivers autoinstall"
            sudo ubuntu-drivers autoinstall
        fi
        
        # RTX 4090 specific configuration
        if [[ "$is_rtx4090" == "true" ]]; then
            log_info "Applying RTX 4090 optimized configuration..."
            
            # Create RTX 4090 specific modprobe config
            sudo tee /etc/modprobe.d/nvidia-graphics-drivers-kms.conf > /dev/null << 'EOF'
# NVIDIA RTX 4090 optimized suspend configuration
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp NVreg_EnableGpuFirmware=0
EOF
            
            # Create RTX 4090 power management config
            sudo tee /etc/modprobe.d/nvidia-rtx4090-power.conf > /dev/null << 'EOF'
# RTX 4090 specific power management options
options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia NVreg_EnableMSI=1
options nvidia NVreg_UsePageAttributeTable=1
EOF
            
            log_success "RTX 4090 optimized configuration applied"
        fi
        
        # Update initramfs to apply new configuration
        log_info "Updating initramfs..."
        sudo update-initramfs -u || log_warning "Failed to update initramfs"
        
        log_success "NVIDIA drivers installed successfully"
        log_warning "System reboot required for changes to take effect"
        
        # Optional CUDA installation
        read -p "Install CUDA toolkit? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_cuda_toolkit
        fi
        
    else
        log_info "Skipping NVIDIA driver installation"
    fi
}

# CUDA toolkit installation
install_cuda_toolkit() {
    log_info "Installing CUDA toolkit..."
    
    # Check for existing CUDA installation
    if command_exists nvcc; then
        local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
        log_info "CUDA already installed: $cuda_version"
        read -p "Reinstall CUDA toolkit? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 0
    fi
    
    # Install CUDA via Ubuntu repository (easier than manual download)
    log_info "Installing CUDA via Ubuntu repository..."
    
    # Add NVIDIA CUDA repository
    wget -O /tmp/cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i /tmp/cuda-keyring.deb
    sudo apt update
    
    # Install CUDA toolkit
    sudo apt install -y cuda-toolkit || {
        log_warning "Failed to install CUDA via repository"
        log_info "Manual CUDA installation may be required"
        log_info "Visit: https://developer.nvidia.com/cuda-downloads"
        return 1
    }
    
    # Add CUDA to PATH
    if ! grep -q "cuda" ~/.bashrc; then
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        log_info "CUDA paths added to ~/.bashrc"
    fi
    
    # Also add to zshrc if it exists
    if [[ -f ~/.zshrc ]] && ! grep -q "cuda" ~/.zshrc; then
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.zshrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.zshrc
        log_info "CUDA paths added to ~/.zshrc"
    fi
    
    # Clean up
    rm -f /tmp/cuda-keyring.deb
    
    log_success "CUDA toolkit installation completed"
    log_info "Restart terminal or source your shell config to use CUDA"
}

# Verify NVIDIA installation
verify_nvidia_setup() {
    local issues=0
    
    log_section "NVIDIA Setup Verification"
    
    # Check NVIDIA driver
    if command_exists nvidia-smi; then
        local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null)
        local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null)
        
        if [[ -n "$driver_version" && -n "$gpu_name" ]]; then
            log_success "✓ NVIDIA driver working: $driver_version"
            log_success "✓ GPU detected: $gpu_name"
            
            # Check for RTX 4090 specific verification
            if echo "$gpu_name" | grep -qi "rtx.*4090\|geforce.*4090"; then
                # Verify RTX 4090 specific configs
                if [[ -f "/etc/modprobe.d/nvidia-graphics-drivers-kms.conf" ]]; then
                    log_success "✓ RTX 4090 suspend configuration present"
                else
                    log_error "✗ RTX 4090 suspend configuration missing"
                    ((issues++))
                fi
                
                if [[ -f "/etc/modprobe.d/nvidia-rtx4090-power.conf" ]]; then
                    log_success "✓ RTX 4090 power management configuration present"
                else
                    log_error "✗ RTX 4090 power management configuration missing"
                    ((issues++))
                fi
            fi
        else
            log_error "✗ NVIDIA driver not working properly"
            ((issues++))
        fi
    else
        log_error "✗ nvidia-smi not found"
        ((issues++))
    fi
    
    # Check CUDA if expected
    if command_exists nvcc; then
        local cuda_version=$(nvcc --version | grep "release" | awk '{print $6}' | cut -c2-)
        log_success "✓ CUDA toolkit working: $cuda_version"
        
        # Test basic CUDA functionality
        if nvidia-smi -L &>/dev/null; then
            log_success "✓ CUDA device enumeration working"
        else
            log_warning "⚠ CUDA device enumeration issues detected"
        fi
    else
        log_info "ℹ CUDA toolkit not installed (optional)"
    fi
    
    # Check modprobe configurations are loaded
    if lsmod | grep -q nvidia; then
        log_success "✓ NVIDIA kernel modules loaded"
    else
        log_error "✗ NVIDIA kernel modules not loaded"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "All NVIDIA components verified successfully!"
    else
        log_warning "Found $issues issues - some manual fixes may be required"
        log_info "Consider rebooting if drivers were just installed"
    fi
    
    return $issues
}

# Finalize logging
finalize_log() {
    local exit_code=${1:-0}
    local end_time=$(date '+%Y-%m-%d %H:%M:%S %Z')
    
    log_to_file ""
    log_to_file "================ INSTALLATION SUMMARY ================"
    log_to_file "End Time: $end_time"
    log_to_file "Exit Code: $exit_code"
    
    if [[ $exit_code -eq 0 ]]; then
        log_to_file "Status: SUCCESS"
    else
        log_to_file "Status: FAILED"
    fi
    
    # Calculate duration
    if [[ -f "$LOG_FILE" ]]; then
        local start_time=$(grep "Start Time:" "$LOG_FILE" | cut -d' ' -f3-4)
        log_to_file "Log File: $LOG_FILE"
        log_to_file "Log Size: $(du -h "$LOG_FILE" | cut -f1)"
    fi
    
    log_to_file "======================================================="
    
    # Display log information to user
    echo
    log_success "Installation log saved to: $LOG_FILE"
    
    if [[ $exit_code -ne 0 ]]; then
        log_info "Check the log file for detailed error information"
    fi
    
    # Log rotation - keep only last 10 logs
    cleanup_old_logs
}

# Clean up old log files
cleanup_old_logs() {
    if [[ -d "$LOG_DIR" ]]; then
        local log_count=$(find "$LOG_DIR" -name "install_*.log" | wc -l)
        
        if [[ $log_count -gt 10 ]]; then
            log_to_file "Cleaning up old logs (keeping 10 most recent)"
            
            # Remove all but the 10 most recent log files
            find "$LOG_DIR" -name "install_*.log" -type f -printf '%T@ %p\n' | \
                sort -n | head -n $((log_count - 10)) | cut -d' ' -f2- | \
                while read -r old_log; do
                    log_to_file "Removing old log: $old_log"
                    rm -f "$old_log"
                done
        fi
    fi
}

# Enhanced error handling with logging
handle_error() {
    local exit_code=$?
    local line_number=${1:-"Unknown"}
    
    log_error "Script failed at line $line_number with exit code $exit_code"
    log_to_file "[FATAL] Script terminated unexpectedly"
    
    finalize_log $exit_code
    exit $exit_code
}

# Set up error trap
trap 'handle_error $LINENO' ERR

# User prompt for NVIDIA setup
ask_nvidia_setup() {
    log_section "NVIDIA Graphics Setup"
    log_info "Would you like to install/configure NVIDIA drivers and CUDA?"
    log_info "This includes RTX 4090 specific optimizations if applicable."
    echo
    read -p "Install NVIDIA drivers and CUDA? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ubuntu_nvidia_setup
    else
        log_info "Skipping NVIDIA setup"
    fi
}

# User prompt for ROS2 setup
ask_ros2_setup() {
    log_section "ROS2 Development Environment"
    log_info "Would you like to install ROS2 Humble development environment?"
    log_info "This includes colcon, workspace setup, and ROS2 packages."
    echo
    read -p "Install ROS2 Humble? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ubuntu_ros2_setup
    else
        log_info "Skipping ROS2 setup"
    fi
}

# ROS2 setup for Ubuntu
ubuntu_ros2_setup() {
    if [[ "$ENABLE_ROS2" != "true" ]]; then
        return 0
    fi
    
    log_section "ROS2 Development Environment"
    
    read -p "Install ROS2 Humble? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installing ROS2 Humble..."
        
        # ROS2 repository setup
        sudo apt install -y curl gnupg lsb-release
        sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
        
        sudo apt update
        sudo apt install -y ros-humble-desktop-full
        sudo apt install -y python3-colcon-common-extensions python3-rosdep python3-argcomplete
        
        # Setup environment
        echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
        
        # Initialize rosdep
        sudo rosdep init || true
        rosdep update
        
        # Create workspace
        mkdir -p ~/Documents/ros_workspaces/humble_ws/src
        cd ~/Documents/ros_workspaces/humble_ws
        colcon build
        
        log_success "ROS2 Humble installed successfully"
    fi
}

# Docker setup
ubuntu_docker_setup() {
    if [[ "$OS_TYPE" != "linux" ]]; then
        return 0
    fi
    
    log_section "Docker Setup"
    
    read -p "Install Docker? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installing Docker..."
        
        # Remove old versions
        sudo apt remove docker docker-engine docker.io containerd runc || true
        
        # Install Docker
        sudo apt install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Add user to docker group
        sudo usermod -aG docker $USER
        
        log_success "Docker installed - logout/login required for group membership"
    fi
}

# Python development environment
install_python_env() {
    log_section "Python Development Environment"
    
    # Check for existing installations first
    if [[ -d "$HOME/anaconda3" ]]; then
        log_success "Anaconda3 already installed at $HOME/anaconda3"
        log_info "Available conda environments:"
        if command -v conda >/dev/null 2>&1; then
            conda env list 2>/dev/null | head -5 || echo "  (conda not in PATH)"
        fi
        log_info "Skipping Python environment installation"
        return 0
    elif [[ -d "$HOME/miniconda3" ]]; then
        log_success "Miniconda3 already installed at $HOME/miniconda3"
        log_info "Available conda environments:"
        if command -v conda >/dev/null 2>&1; then
            conda env list 2>/dev/null | head -5 || echo "  (conda not in PATH)"
        fi
        log_info "Skipping Python environment installation"
        return 0
    fi
    
    echo
    echo "Choose Python Environment:"
    echo "1) Anaconda3 (Full distribution with data science packages)"
    echo "2) Miniconda3 (Minimal installation)"
    echo "3) Skip Python environment installation"
    read -p "Enter choice (1/2/3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            if [[ "$OS_TYPE" == "linux" ]]; then
                log_info "Installing Anaconda3 for Linux..."
                
                # Download with error handling
                if ! run_with_timeout 300 "anaconda-download" wget -q --show-progress "https://repo.anaconda.com/archive/Anaconda3-2024.02-1-Linux-x86_64.sh" -O "/tmp/anaconda.sh"; then
                    log_error "Failed to download Anaconda3 installer"
                    log_info "You can install manually from: https://www.anaconda.com/download"
                    return 1
                fi
                
                # Install with error handling
                log_info "Installing Anaconda3 (this may take several minutes)..."
                if bash /tmp/anaconda.sh -b -u -p "$HOME/anaconda3" 2>/dev/null; then
                    log_success "Anaconda3 installation completed"
                else
                    log_warning "Anaconda3 installation encountered issues, but may have succeeded"
                fi
                
                # Cleanup
                rm -f /tmp/anaconda.sh 2>/dev/null || true
                
                # Add to PATH
                echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/anaconda3/bin:$PATH"
                
                # Initialize conda safely
                if [[ -f "$HOME/anaconda3/bin/conda" ]]; then
                    log_info "Initializing Anaconda3..."
                    "$HOME/anaconda3/bin/conda" init bash 2>/dev/null || log_warning "Failed to initialize conda"
                    
                    # Install additional robotics and data science packages with timeout
                    log_info "Installing additional packages for robotics and data science..."
                    if run_with_timeout 600 "anaconda-packages" "$HOME/anaconda3/bin/conda" install -y -c conda-forge \
                        opencv pytorch tensorboard jupyter jupyterlab plotly bokeh dask xarray cartopy 2>/dev/null; then
                        log_success "Additional packages installed successfully"
                    else
                        log_warning "Some packages failed to install - Anaconda3 is still functional"
                    fi
                    
                    log_success "Anaconda3 installation completed"
                else
                    log_error "Anaconda3 installation failed - conda binary not found"
                    return 1
                fi
                
            elif [[ "$OS_TYPE" == "macos" ]]; then
                log_info "Installing Anaconda3 for macOS..."
                if [[ "$ARCH" == "arm64" ]]; then
                    wget https://repo.anaconda.com/archive/Anaconda3-2024.02-1-MacOSX-arm64.sh -O /tmp/anaconda.sh
                else
                    wget https://repo.anaconda.com/archive/Anaconda3-2024.02-1-MacOSX-x86_64.sh -O /tmp/anaconda.sh
                fi
                bash /tmp/anaconda.sh -b -u -p $HOME/anaconda3
                rm /tmp/anaconda.sh
                
                # Add to PATH
                echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc
                export PATH="$HOME/anaconda3/bin:$PATH"
                
                # Initialize conda
                $HOME/anaconda3/bin/conda init zsh
                
                # Install additional robotics and data science packages
                log_info "Installing additional packages for robotics and data science..."
                $HOME/anaconda3/bin/conda install -y -c conda-forge \
                    opencv \
                    pytorch \
                    tensorboard \
                    jupyter \
                    jupyterlab \
                    plotly \
                    bokeh \
                    dask \
                    xarray \
                    cartopy
                
                log_success "Anaconda3 installed successfully with robotics and data science packages"
            fi
            ;;
        2)
            if [[ "$OS_TYPE" == "linux" ]]; then
                log_info "Installing Miniconda3 for Linux..."
                
                # Download with error handling
                if ! run_with_timeout 180 "miniconda-download" wget -q --show-progress "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "/tmp/miniconda.sh"; then
                    log_error "Failed to download Miniconda3 installer"
                    log_info "You can install manually from: https://docs.conda.io/en/latest/miniconda.html"
                    return 1
                fi
                
                # Install with error handling
                log_info "Installing Miniconda3 (this may take a few minutes)..."
                if bash /tmp/miniconda.sh -b -u -p "$HOME/miniconda3" 2>/dev/null; then
                    log_success "Miniconda3 installation completed"
                else
                    log_warning "Miniconda3 installation encountered issues, but may have succeeded"
                fi
                
                # Cleanup
                rm -f /tmp/miniconda.sh 2>/dev/null || true
                
                # Add to PATH
                echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc
                export PATH="$HOME/miniconda3/bin:$PATH"
                
                # Initialize conda safely
                if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
                    log_info "Initializing Miniconda3..."
                    "$HOME/miniconda3/bin/conda" init bash 2>/dev/null || log_warning "Failed to initialize conda"
                    log_success "Miniconda3 installation completed"
                else
                    log_error "Miniconda3 installation failed - conda binary not found"
                    return 1
                fi
                
            elif [[ "$OS_TYPE" == "macos" ]]; then
                log_info "Installing Miniconda3 for macOS..."
                if [[ "$ARCH" == "arm64" ]]; then
                    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh -O /tmp/miniconda.sh
                else
                    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O /tmp/miniconda.sh
                fi
                bash /tmp/miniconda.sh -b -u -p $HOME/miniconda3
                rm /tmp/miniconda.sh
                
                # Add to PATH
                echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.zshrc
                export PATH="$HOME/miniconda3/bin:$PATH"
                
                # Initialize conda
                $HOME/miniconda3/bin/conda init zsh
            fi
            ;;
        3)
            log_info "Skipping Python environment installation"
            ;;
        *)
            log_warning "Invalid choice, skipping Python environment installation"
            ;;
    esac
    
    # Final verification
    if [[ -d "$HOME/anaconda3" ]] || [[ -d "$HOME/miniconda3" ]]; then
        log_success "Python environment available"
        if command -v conda >/dev/null 2>&1; then
            log_info "Conda version: $(conda --version 2>/dev/null || echo 'Not in PATH yet')"
        else
            log_info "Note: Restart terminal or run 'source ~/.bashrc' to use conda"
        fi
    fi
}

# macOS comprehensive setup
macos_comprehensive_setup() {
    if [[ "$ENABLE_MACOS_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "macOS Comprehensive Setup"
    
    # Essential Homebrew packages
    log_info "Installing essential Homebrew packages..."
    local brew_packages=(
        "git" "neovim" "tmux" "zsh" "stow" "bat" "exa" "fd" "ripgrep" "fzf"
        "node" "python@3.11" "gh" "curl" "wget" "tree" "htop"
    )
    
    for package in "${brew_packages[@]}"; do
        if ! brew list | grep -q "$package"; then
            log_info "Installing $package..."
            brew install "$package" || log_warning "Failed to install $package"
        else
            log_info "$package already installed"
        fi
    done
    
    # Homebrew casks (applications)
    local cask_packages=(
        "visual-studio-code" "obsidian" "docker" "vlc" "google-chrome"
        "firefox" "discord" "slack" "spotify" "signal"
    )
    
    read -p "Install GUI applications via Homebrew casks? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for cask in "${cask_packages[@]}"; do
            if ! brew list --cask | grep -q "$cask"; then
                log_info "Installing $cask..."
                brew install --cask "$cask" || log_warning "Failed to install $cask"
            else
                log_info "$cask already installed"
            fi
        done
    fi
    
    # NVM for Node.js version management
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
    else
        log_info "NVM already installed"
    fi
    
    # Oh-My-Zsh if not installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-My-Zsh..."
        install_shell_framework
    else
        log_info "Oh-My-Zsh already installed"
    fi
    
    # Git configuration and Obsidian setup
    macos_obsidian_setup
    
    log_success "macOS comprehensive setup completed"
}

# Obsidian setup for macOS
macos_obsidian_setup() {
    if [[ "$ENABLE_MACOS_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "macOS Obsidian + Git Setup"
    
    # Git configuration
    log_info "Configuring Git for macOS..."
    git config --global user.name "jk1rby" || true
    git config --global user.email "jameskirby663@gmail.com" || true
    git config --global credential.helper osxkeychain || true
    
    # Check for Obsidian vault
    local vault_dir="$HOME/Documents/notes"
    if [[ ! -d "$vault_dir" ]]; then
        log_info "Creating Obsidian vault directory..."
        mkdir -p "$vault_dir"
    fi
    
    cd "$vault_dir"
    
    # Git repository setup
    if [[ ! -d ".git" ]]; then
        log_info "Initializing Git repository..."
        git init
        git remote add origin https://github.com/jk1rby/notes.git || true
    fi
    
    # Check authentication
    log_info "Testing Git authentication..."
    if git ls-remote origin &>/dev/null; then
        log_success "Git authentication working"
        
        # Sync with remote
        git fetch origin || log_warning "Could not fetch from remote"
        
        # Set up main branch
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            git checkout -b main origin/main 2>/dev/null || git checkout main
            log_success "Switched to main branch"
        fi
        
    else
        log_warning "Git authentication failed - manual setup required"
        log_info "Please set up GitHub credentials in Keychain Access"
    fi
    
    log_success "macOS Obsidian setup completed"
}

# Windows 11 comprehensive setup
windows_comprehensive_setup() {
    if [[ "$ENABLE_WINDOWS_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "Windows 11 Comprehensive Setup"
    
    # Essential winget packages
    if command_exists winget; then
        log_info "Installing essential packages via winget..."
        local winget_packages=(
            "Git.Git" "Neovim.Neovim" "Microsoft.VisualStudioCode"
            "Google.Chrome" "Mozilla.Firefox" "VideoLAN.VLC"
            "Obsidian.Obsidian" "Discord.Discord" "SlackTechnologies.Slack"
            "Docker.DockerDesktop" "Microsoft.PowerShell" "GitHub.cli"
            "sharkdp.bat" "sharkdp.fd" "BurntSushi.ripgrep.MSVC"
        )
        
        for package in "${winget_packages[@]}"; do
            if ! winget list | grep -q "$package"; then
                log_info "Installing $package..."
                winget install --id "$package" --silent --accept-source-agreements --accept-package-agreements || log_warning "Failed to install $package"
            else
                log_info "$package already installed"
            fi
        done
    elif command_exists choco; then
        log_info "Installing essential packages via chocolatey..."
        local choco_packages=(
            "git" "neovim" "vscode" "googlechrome" "firefox" "vlc"
            "obsidian" "discord" "slack" "docker-desktop" "powershell-core"
            "gh" "bat" "fd" "ripgrep"
        )
        
        for package in "${choco_packages[@]}"; do
            if ! choco list --local-only | grep -q "$package"; then
                log_info "Installing $package..."
                choco install "$package" -y || log_warning "Failed to install $package"
            else
                log_info "$package already installed"
            fi
        done
    else
        log_warning "No package manager found (winget or chocolatey)"
        log_info "Please install applications manually"
    fi
    
    # NVM for Windows if not installed
    if [[ ! -d "$USERPROFILE/AppData/Roaming/nvm" ]]; then
        log_info "Installing NVM for Windows..."
        log_info "Please download and install from: https://github.com/coreybutler/nvm-windows"
    else
        log_info "NVM for Windows already installed"
    fi
    
    # WSL2 setup (optional)
    read -p "Install Windows Subsystem for Linux (WSL2)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Enabling WSL2..."
        powershell.exe -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" || log_warning "Failed to enable WSL"
        powershell.exe -Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" || log_warning "Failed to enable Virtual Machine Platform"
        log_info "WSL2 enabled - reboot required"
    fi
    
    # Git configuration and Obsidian setup
    windows_obsidian_setup
    
    log_success "Windows 11 comprehensive setup completed"
}

# Obsidian setup for Windows 11
windows_obsidian_setup() {
    if [[ "$ENABLE_WINDOWS_SETUP" != "true" ]]; then
        return 0
    fi
    
    log_section "Windows 11 Obsidian + Git Setup"
    
    # Git configuration
    log_info "Configuring Git for Windows..."
    git config --global user.name "jk1rby" || true
    git config --global user.email "jameskirby663@gmail.com" || true
    git config --global credential.helper manager || true
    
    # Check for Obsidian vault (Windows path)
    local vault_dir
    if [[ -n "$USERPROFILE" ]]; then
        vault_dir="$USERPROFILE/Documents/notes"
    else
        vault_dir="/c/Users/jk/Documents/notes"
    fi
    
    # Convert to Unix-style path if needed
    vault_dir=$(echo "$vault_dir" | sed 's|\\|/|g')
    
    if [[ ! -d "$vault_dir" ]]; then
        log_info "Creating Obsidian vault directory..."
        mkdir -p "$vault_dir"
    fi
    
    cd "$vault_dir"
    
    # Git repository setup
    if [[ ! -d ".git" ]]; then
        log_info "Initializing Git repository..."
        git init
        git remote add origin https://github.com/jk1rby/notes.git || true
    fi
    
    # Check authentication
    log_info "Testing Git authentication..."
    if git ls-remote origin &>/dev/null; then
        log_success "Git authentication working"
        
        # Sync with remote
        git fetch origin || log_warning "Could not fetch from remote"
        
        # Set up main branch
        if git show-ref --verify --quiet refs/remotes/origin/main; then
            git checkout -b main origin/main 2>/dev/null || git checkout main
            log_success "Switched to main branch"
        fi
        
    else
        log_warning "Git authentication failed - manual setup required"
        log_info "Please configure GitHub credentials in Windows Credential Manager"
        log_info "Or run: git config --global credential.helper manager"
    fi
    
    log_success "Windows 11 Obsidian setup completed"
}

# Shell framework installation
install_shell_framework() {
    log_section "Shell Framework Installation"
    
    # Install Oh-My-Zsh using idempotent approach
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || {
            log_warning "Oh-My-Zsh installation failed"
            return 1
        }
        log_success "Oh-My-Zsh installed"
    else
        log_info "Oh-My-Zsh already installed at $HOME/.oh-my-zsh"
    fi
    
    # Install Powerlevel10k theme using idempotent git clone
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    clone_repository_idempotent \
        "https://github.com/romkatv/powerlevel10k.git" \
        "$p10k_dir" \
        "Powerlevel10k theme"
    
    # Install Zsh plugins using idempotent git clone
    local plugins_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    local plugins=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting"
        "you-should-use|https://github.com/MichaelAquilina/zsh-you-should-use.git"
    )
    
    for plugin_info in "${plugins[@]}"; do
        local plugin_name="${plugin_info%|*}"
        local plugin_url="${plugin_info#*|}"
        local plugin_dir="$plugins_dir/$plugin_name"
        
        clone_repository_idempotent \
            "$plugin_url" \
            "$plugin_dir" \
            "$plugin_name plugin"
    done
    
    # Clean up any broken plugin directories with :https suffix
    log_info "Cleaning up any broken plugin directories..."
    if ls "$plugins_dir"/*:https 2>/dev/null; then
        for broken_dir in "$plugins_dir"/*:https; do
            if [[ -d "$broken_dir" ]]; then
                local plugin_name=$(basename "$broken_dir" | sed 's/:https$//')
                log_info "Removing broken plugin directory: $(basename "$broken_dir")"
                rm -rf "$broken_dir"
                log_success "Cleaned up broken plugin directory"
            fi
        done
    else
        log_info "No broken plugin directories found - all clean!"
    fi
}

# Check if dotfiles need to be overwritten (always returns true since we want clean installs)
check_for_overwrite() {
    local config_files=(
        "$HOME/.zshrc"
        "$HOME/.gitconfig" 
        "$HOME/.gitignore_global"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
    )
    
    log_info "Checking for existing configuration files..."
    
    local existing_found=false
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]] || [[ -d "$config_file" ]]; then
            if [[ -L "$config_file" ]]; then
                local link_target=$(readlink "$config_file")
                if [[ "$link_target" == *"dotfiles"* ]]; then
                    log_info "$(basename "$config_file") already correctly symlinked"
                else
                    log_info "$(basename "$config_file") symlinked elsewhere - will overwrite"
                    existing_found=true
                fi
            else
                log_info "Found existing $(basename "$config_file") - will overwrite safely"
                existing_found=true
            fi
        fi
    done
    
    if [[ "$existing_found" == "true" ]]; then
        log_warning "Existing configuration files detected"
        log_info "Will archive with .old suffix before clean installation"
        return 0  # overwrite needed
    else
        log_info "No existing configuration conflicts - clean installation"
        return 1  # no overwrite needed
    fi
}

# Apply dotfiles with Stow
apply_dotfiles() {
    log_section "Applying Dotfiles with Stow"
    
    cd "$DOTFILES_DIR"
    
    # Ensure GNU Stow is installed before proceeding
    log_info "Ensuring GNU Stow is available..."
    if ! install_stow; then
        log_error "GNU Stow installation failed"
        log_error "Cannot proceed with dotfiles installation without stow"
        log_info "Please install stow manually:"
        log_info "  Ubuntu/Debian: sudo apt install stow"
        log_info "  macOS:         brew install stow"
        return 1
    fi
    
    local packages=("zsh" "git" "tmux" "nvim")
    local force_mode=false
    
    # Check if we need to overwrite existing dotfiles
    local overwrite_needed=false
    if [[ "$1" == "--force" ]]; then
        overwrite_needed=true
        log_warning "Force mode explicitly enabled via --force flag"
    else
        # Check if overwrite is needed
        if check_for_overwrite; then
            overwrite_needed=true
            log_warning "Overwrite mode auto-enabled due to existing config files"
        fi
    fi
    
    # Use Stow --adopt method to handle existing files
    if [[ "$overwrite_needed" == "true" ]]; then
        log_section "Stow Integration with Existing Files"
        log_info "Using Stow's --adopt method to manage existing configurations"
        log_info "Original files will be preserved and can be restored with 'stow -D'"
    fi
    
    for package in "${packages[@]}"; do
        if [[ -d "$package" ]]; then
            if ! stow_with_grace "$package" "$force_mode"; then
                log_error "Failed to stow $package"
                if [[ "$force_mode" != "true" ]]; then
                    log_info "Use --force flag to automatically resolve conflicts"
                    return 1
                fi
            fi
        else
            log_warning "Package directory not found: $package"
        fi
    done
    
    log_success "All dotfiles applied successfully"
}

# Set default shell
set_default_shell() {
    log_section "Setting Default Shell"
    
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting Zsh as default shell..."
        
        local zsh_path
        if command_exists zsh; then
            zsh_path=$(which zsh)
            
            # Add zsh to /etc/shells if not present
            if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
            fi
            
            # Change shell
            chsh -s "$zsh_path" || {
                log_warning "Could not change default shell automatically"
                log_info "Run: chsh -s $zsh_path"
                return 1
            }
            
            log_success "Zsh set as default shell (restart terminal to take effect)"
        else
            log_error "Zsh not found"
            return 1
        fi
    else
        log_info "Zsh is already the default shell"
    fi
}

# Install Nerd Fonts for proper icon display
install_nerd_fonts() {
    log_section "Nerd Fonts Installation"
    
    # Check if Nerd Fonts are already installed
    if fc-list | grep -i "nerd" >/dev/null 2>&1; then
        log_success "Nerd Fonts already installed!"
        log_info "Available Nerd Fonts:"
        fc-list | grep -i "nerd" | head -3 | while read -r font; do
            local font_name=$(echo "$font" | cut -d':' -f2 | cut -d',' -f1)
            log_info "  - $font_name"
        done
        log_info ""
        log_info "To fix missing icons:"
        log_info "  1. Set your terminal font to 'FiraCode Nerd Font Mono' or similar"
        log_info "  2. Restart your terminal"
        log_info "  3. Icons should display correctly in NvChad and file managers"
        return 0
    fi
    
    read -p "Install Nerd Fonts for proper icons in terminal and NvChad? (Y/n): " -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Skipping Nerd Fonts installation"
        return 0
    fi
    
    log_info "Installing Nerd Fonts for proper icon display..."
    
    # Create fonts directory using idempotent helper
    create_directory_idempotent ~/.local/share/fonts "fonts directory"
    
    # Download and install essential Nerd Fonts (FiraCode only for reliability)
    local fonts=(
        "FiraCode"
    )
    
    local font_version="v3.1.1"
    local fonts_installed=0
    
    for font in "${fonts[@]}"; do
        # Check if font already installed
        if ls ~/.local/share/fonts/${font}*.ttf 2>/dev/null | grep -q .; then
            log_info "$font Nerd Font already installed"
            ((fonts_installed++))
            continue
        fi
        
        log_info "Installing $font Nerd Font..."
        
        # Download font using idempotent helper
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/${font}.zip"
        local font_zip="/tmp/${font}.zip"
        
        if download_file_idempotent "$font_url" "$font_zip" "$font Nerd Font"; then
            log_info "Extracting $font (this may take a moment)..."
            
            # Create temporary extraction directory
            local extract_dir="/tmp/${font}_extract"
            create_directory_idempotent "$extract_dir" "extraction directory"
            
            if run_with_timeout 60 "unzip-$font" unzip -q "$font_zip" -d "$extract_dir" 2>/dev/null; then
                # Copy TTF/OTF files, ignoring errors for fonts without TTF variants
                local font_files_copied=0
                
                # Try TTF files first
                if ls "$extract_dir"/*.ttf 2>/dev/null | grep -q .; then
                    cp "$extract_dir"/*.ttf ~/.local/share/fonts/ 2>/dev/null && font_files_copied=1
                fi
                
                # Try OTF files if no TTF found
                if [[ $font_files_copied -eq 0 ]] && ls "$extract_dir"/*.otf 2>/dev/null | grep -q .; then
                    cp "$extract_dir"/*.otf ~/.local/share/fonts/ 2>/dev/null && font_files_copied=1
                fi
                
                if [[ $font_files_copied -eq 1 ]]; then
                    log_success "$font Nerd Font installed"
                    ((fonts_installed++))
                else
                    log_warning "$font: No TTF/OTF files found in archive"
                fi
            else
                log_warning "Failed to extract $font (timeout or corruption)"
            fi
            
            # Cleanup
            rm -rf "$extract_dir" "$font_zip" 2>/dev/null || true
        else
            log_warning "Failed to download $font Nerd Font"
        fi
    done
    
    if [[ $fonts_installed -gt 0 ]]; then
        log_info "Updating font cache..."
        if fc-cache -f -v >/dev/null 2>&1; then
            log_success "Font cache updated successfully"
        else
            log_warning "Font cache update failed, but fonts should still work after restart"
        fi
        
        log_success "Nerd Fonts installation completed ($fonts_installed fonts available)"
        log_info "To use icons properly:"
        log_info "  1. Set your terminal font to a Nerd Font (e.g., 'JetBrainsMono Nerd Font')"
        log_info "  2. Restart your terminal"
        log_info "  3. Icons should now display correctly in NvChad and file managers"
    else
        log_warning "No fonts were installed"
    fi
}

# Install modern CLI tools
install_modern_tools() {
    log_section "Modern CLI Tools"
    
    read -p "Install modern CLI tools (bat, exa, fd, ripgrep, fzf)? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 0
    fi
    
    if [[ "$OS_TYPE" == "linux" ]]; then
        log_info "Installing modern tools for Linux..."
        
        # Install via apt
        sudo apt install -y bat fd-find ripgrep || log_warning "Some packages failed to install"
        
        # Create symlinks
        sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
        
        # Install exa manually
        if ! command_exists exa; then
            log_info "Installing exa..."
            wget -qO- https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip > /tmp/exa.zip
            sudo unzip -o /tmp/exa.zip -d /usr/local/bin/ || log_warning "Could not install exa"
            sudo chmod +x /usr/local/bin/exa 2>/dev/null || true
            rm /tmp/exa.zip
        fi
        
        # Install fzf
        if [[ ! -d "$HOME/.fzf" ]]; then
            log_info "Installing fzf..."
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            ~/.fzf/install --all || log_warning "fzf installation failed"
        fi
        
    elif [[ "$OS_TYPE" == "macos" ]]; then
        log_info "Installing modern tools for macOS..."
        
        local tools=("bat" "exa" "fd" "ripgrep" "fzf")
        for tool in "${tools[@]}"; do
            if ! command_exists "$tool"; then
                log_info "Installing $tool..."
                brew install "$tool" || log_warning "Failed to install $tool"
            fi
        done
        
    elif [[ "$OS_TYPE" == "windows" ]]; then
        log_info "Installing modern tools for Windows..."
        
        if command_exists winget; then
            local tools=("sharkdp.bat" "sharkdp.fd" "BurntSushi.ripgrep.MSVC")
            for tool in "${tools[@]}"; do
                log_info "Installing $tool..."
                winget install --id "$tool" --silent --accept-source-agreements --accept-package-agreements || log_warning "Failed to install $tool"
            done
        elif command_exists choco; then
            local tools=("bat" "fd" "ripgrep")
            for tool in "${tools[@]}"; do
                log_info "Installing $tool..."
                choco install "$tool" -y || log_warning "Failed to install $tool"
            done
        else
            log_warning "No package manager found - skipping modern tools installation"
            log_info "Consider installing winget or chocolatey for package management"
        fi
    fi
    
    log_success "Modern CLI tools installation completed"
}

# Final verification and summary
verify_installation() {
    log_section "Installation Verification"
    
    local issues=0
    
    # Check Stow symlinks
    local files=("$HOME/.zshrc" "$HOME/.gitconfig" "$HOME/.tmux.conf")
    for file in "${files[@]}"; do
        if [[ -L "$file" ]]; then
            log_success "✓ $file is correctly symlinked"
        else
            log_error "✗ $file is not symlinked"
            ((issues++))
        fi
    done
    
    # Check and initialize NvChad
    if [[ -L "$HOME/.config/nvim" ]]; then
        log_success "✓ NvChad configuration is symlinked"
        
        # Initialize NvChad for proper first-run experience
        log_info "Initializing NvChad for optimal first-run experience..."
        if initialize_nvchad; then
            log_success "✓ NvChad initialized successfully"
        else
            log_warning "⚠ NvChad initialization had issues but will work"
        fi
    else
        log_warning "✗ NvChad configuration not symlinked"
        ((issues++))
    fi
    
    # Check shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_success "✓ Zsh is the default shell"
    else
        log_warning "✗ Zsh is not the default shell"
    fi
    
    # Check Oh-My-Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "✓ Oh-My-Zsh is installed"
    else
        log_error "✗ Oh-My-Zsh is not installed"
        ((issues++))
    fi
    
    # Check NVIDIA setup if RTX 4090 system
    if [[ "$IS_RTX4090_SYSTEM" == "true" ]]; then
        log_info "Verifying NVIDIA RTX 4090 setup..."
        verify_nvidia_setup
        local nvidia_issues=$?
        ((issues += nvidia_issues))
    elif [[ "$ENABLE_NVIDIA_SETUP" == "true" ]]; then
        log_info "Verifying NVIDIA setup..."
        verify_nvidia_setup
        local nvidia_issues=$?
        ((issues += nvidia_issues))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "All critical components verified successfully!"
    else
        log_warning "Found $issues issues - some manual fixes may be required"
    fi
}

# Usage information
show_usage() {
    echo "Cross-Platform Dotfiles Installation Script"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --force          Automatically resolve Stow conflicts"
    echo "  --profile NAME   Use specific machine profile (desktop-rtx4090, macbook-m1, server-minimal)"
    echo "  --ubuntu-full    Enable full Ubuntu 22.04 setup (RTX 4090 + Z790)"
    echo "  --macos-full     Enable full macOS setup (Apple Silicon only)"
    echo "  --windows-full   Enable full Windows 11 setup"
    echo "  --minimal        Install only dotfiles (no system packages)"
    echo "  --unstow         Remove dotfiles and restore original configs"
    echo "  --health         Check dotfiles installation health"
    echo
    echo "Restore Point Options:"
    echo "  --create-restore-point [NAME]  Create a restore point (default: manual)"
    echo "  --list-restore-points          List available restore points"
    echo "  --restore [NAME/NUMBER]        Restore from a specific point"
    echo "  --cleanup-restore-points [N]   Keep only N most recent points (default: 5)"
    echo
    echo "Other Options:"
    echo "  --verbose        Enable verbose logging (default: enabled)"
    echo "  --no-verbose     Disable verbose logging"
    echo "  --help           Show this help message"
    echo
    echo "Supported Systems:"
    echo "  - Ubuntu 22.04 LTS (with RTX 4090 + Z790 optimizations)"
    echo "  - macOS (Apple Silicon only - Monterey, Ventura, Sonoma)"
    echo "  - Windows 11 (build 22000+)"
    echo
}

# Main installation flow
main() {
    local force_mode=false
    local minimal_mode=false
    local ubuntu_full_mode=false
    local macos_full_mode=false
    local windows_full_mode=false
    local profile_name=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force_mode=true
                FORCE_INSTALL=true
                shift
                ;;
            --profile)
                profile_name="$2"
                shift 2
                ;;
            --minimal)
                minimal_mode=true
                shift
                ;;
            --ubuntu-full)
                ubuntu_full_mode=true
                shift
                ;;
            --macos-full)
                macos_full_mode=true
                shift
                ;;
            --windows-full)
                windows_full_mode=true
                shift
                ;;
            --verbose)
                VERBOSE_LOGGING=true
                shift
                ;;
            --no-verbose)
                VERBOSE_LOGGING=false
                shift
                ;;
            --unstow)
                unstow_dotfiles
                exit 0
                ;;
            --health)
                health_check
                exit 0
                ;;
            --create-restore-point)
                detect_system
                create_restore_point "${2:-manual}"
                exit 0
                ;;
            --list-restore-points)
                list_restore_points
                exit 0
                ;;
            --restore)
                detect_system
                restore_from_point "$2"
                exit 0
                ;;
            --cleanup-restore-points)
                cleanup_old_restore_points "${2:-5}"
                exit 0
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Initialize logging first
    init_logging "$@"
    
    # Log system information
    log_system_info
    
    # Header
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    Cross-Platform Dotfiles Setup      ${NC}"
    echo -e "${CYAN}    Author: jk1rby                     ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
    
    if [[ "$VERBOSE_LOGGING" == "true" ]]; then
        log_info "Verbose logging enabled - log file: $LOG_FILE"
    fi
    
    # Core setup flow
    detect_system
    validate_prerequisites
    
    # Load machine profile if specified or detect
    if [[ -n "$profile_name" ]]; then
        load_profile "$profile_name"
    else
        detect_machine_profile
    fi
    
    # Run comprehensive preflight checks
    preflight_check
    
    # Create automatic restore point before making changes
    if [[ "$minimal_mode" != "true" ]]; then
        log_info "Creating automatic restore point before installation..."
        create_restore_point "pre-install" || log_warning "Failed to create restore point, continuing anyway"
    fi
    
    create_backup
    
    # Install software first, then configure it
    if [[ "$minimal_mode" != "true" ]]; then
        install_dependencies
        install_shell_framework
        
        # Apply profile-specific packages
        apply_profile_packages
    fi
    
    # OS-specific software installation (before dotfiles configuration)
    if [[ "$ubuntu_full_mode" == "true" ]] || [[ "$ENABLE_FULL_UBUNTU_SETUP" == "true" && "$minimal_mode" != "true" ]]; then
        ubuntu_comprehensive_setup
        ubuntu_hardware_fixes
        
        # Ask user about optional components
        ask_nvidia_setup
        ask_ros2_setup
    fi
    
    # Apply dotfiles configuration after software is installed
    # Note: apply_dotfiles now auto-detects conflicts and enables force mode as needed
    if [[ "$force_mode" == "true" ]]; then
        apply_dotfiles --force
    else
        apply_dotfiles
    fi
    
    # Install fonts (essential for proper icons in terminal and NvChad)
    install_nerd_fonts
    
    if [[ "$macos_full_mode" == "true" ]] || [[ "$ENABLE_MACOS_SETUP" == "true" && "$minimal_mode" != "true" ]]; then
        macos_comprehensive_setup
    fi
    
    if [[ "$windows_full_mode" == "true" ]] || [[ "$ENABLE_WINDOWS_SETUP" == "true" && "$minimal_mode" != "true" ]]; then
        windows_comprehensive_setup
    fi
    
    # Common optional components
    if [[ "$minimal_mode" != "true" ]]; then
        install_python_env
        install_modern_tools
        set_default_shell
    fi
    
    # Final steps
    verify_installation
    local verification_result=$?
    
    # Run profile post-install if defined
    if [[ -n "$LOADED_PROFILE" ]] && declare -f profile_post_install >/dev/null; then
        log_section "Running Profile Post-Install"
        profile_post_install
    fi
    
    # Success message
    log_section "Installation Complete!"
    
    if [[ $verification_result -eq 0 ]]; then
        echo -e "${GREEN}🎉 Dotfiles installation completed successfully!${NC}"
        
        # Clean up old restore points on successful installation
        if [[ -d "$HOME/.dotfiles_restore" ]]; then
            log_info "Cleaning up old restore points..."
            cleanup_old_restore_points 5
        fi
        
        finalize_log 0
    else
        echo -e "${YELLOW}⚠️ Dotfiles installation completed with some issues!${NC}"
        log_info "Restore points preserved due to installation issues"
        finalize_log $verification_result
    fi
    
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart your terminal (or source ~/.zshrc)"
    echo "2. Open 'nvim' - NvChad should work immediately with all keybinds!"
    if command_exists p10k; then
        echo "3. Configure Powerlevel10k: p10k configure"
    fi
    echo
    echo -e "${BLUE}Key bindings:${NC}"
    echo "• Space+ff - Find files (NvChad)"
    echo "• Space+fg - Live grep (NvChad)"
    echo "• Space+e - File explorer (NvChad)"
    echo "• Ctrl+\\ - Toggle terminal (NvChad)"
    echo
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${CYAN}Backup location:${NC} $BACKUP_DIR"
    fi
    echo
    
    # Exit with verification result
    exit $verification_result
}

# Run main function with all arguments
main "$@"