# Machine Profiles

This directory contains machine-specific profiles that define configuration and software installation preferences for different types of systems.

## Available Profiles

### desktop-rtx4090.profile
High-performance desktop configuration with NVIDIA RTX 4090 GPU support, optimized for:
- Deep learning and CUDA development
- ROS2 and robotics development
- Multi-monitor setups
- Heavy IDEs and development tools

### macbook-m1.profile
Apple Silicon MacBook configuration optimized for:
- macOS-specific applications and integrations
- Battery life optimization
- Obsidian note-taking sync
- Homebrew package management

### server-minimal.profile
Lightweight server/VM configuration for:
- Headless systems with limited resources
- Security hardening
- Minimal package installation
- Container and virtualization environments

## Using Profiles

Profiles can be loaded in several ways:

1. **Automatic detection** - The installer will attempt to detect your machine type
2. **Environment variable** - Set `MACHINE_PROFILE` before running the installer:
   ```bash
   export MACHINE_PROFILE=desktop-rtx4090
   ./scripts/install-cross-platform.sh
   ```
3. **Command line option** - Pass the profile as an argument:
   ```bash
   ./scripts/install-cross-platform.sh --profile desktop-rtx4090
   ```

## Creating Custom Profiles

To create a custom profile:

1. Copy an existing profile as a template
2. Modify the environment variables and functions
3. Save as `profiles/your-profile-name.profile`
4. Use with `--profile your-profile-name`

## Profile Structure

Each profile should export:
- **Metadata**: Profile name, type, and description
- **Feature flags**: What features to enable/disable
- **Package lists**: Arrays of packages to install
- **Functions**: `profile_pre_install()` and `profile_post_install()`
- **Overrides**: Custom configuration values

## Profile Variables

Key variables that can be set:
- `ENABLE_*` - Feature flags (true/false)
- `*_PACKAGES` - Arrays of package names
- `MACHINE_TYPE` - desktop/laptop/server
- `HAS_*` - Hardware capability flags