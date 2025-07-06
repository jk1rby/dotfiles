# Installation Logs

This directory contains installation logs from the cross-platform dotfiles automation script.

## Log Format

Each installation creates a timestamped log file: `install_YYYYMMDD_HHMMSS.log`

## Log Contents

- **System Information**: Hardware, OS, environment details
- **Installation Steps**: Detailed command execution and output
- **Error Details**: Comprehensive error reporting with context
- **Verification Results**: Post-installation validation status

## Log Management

- **Automatic Rotation**: Keeps only the 10 most recent logs
- **Size Tracking**: Logs include file size information
- **Timestamped Entries**: All log entries include precise timestamps

## Usage

```bash
# View the latest log
ls -la logs/install_*.log | tail -1

# Monitor a running installation
tail -f logs/install_$(date +%Y%m%d)_*.log

# Search for errors across all logs  
grep -r "ERROR" logs/

# Find specific installation issues
grep -r "RTX 4090" logs/
grep -r "NVIDIA" logs/
```

## Troubleshooting

Check the logs for:
- Failed package installations
- Hardware detection issues  
- Configuration errors
- Network connectivity problems
- Permission issues

The logs provide complete context for debugging and improving the automation.