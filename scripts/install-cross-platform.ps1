# Cross-Platform Dotfiles Installation Script - PowerShell Version
# Author: jk1rby

param(
    [switch]$Force,
    [switch]$WindowsFull,
    [switch]$Minimal,
    [switch]$Help
)

# Configuration
$DOTFILES_DIR = "$env:USERPROFILE\dotfiles"
$LOG_DIR = "$DOTFILES_DIR\logs"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = "$LOG_DIR\install_$TIMESTAMP.log"

# Colors
$Colors = @{
    Red     = 'Red'
    Green   = 'Green'
    Yellow  = 'Yellow'
    Blue    = 'Blue'
    Magenta = 'Magenta'
    Cyan    = 'Cyan'
}

function Write-Log {
    param([string]$Level, [string]$Message)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    switch ($Level) {
        "INFO"    { Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue }
        "SUCCESS" { Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Green }
        "WARNING" { Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow }
        "ERROR"   { Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red }
    }
    
    # Write to log file
    Add-Content -Path $LOG_FILE -Value $logEntry
}

function Write-Section {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor $Colors.Magenta
    Write-Host "    $Title" -ForegroundColor $Colors.Magenta
    Write-Host "========================================" -ForegroundColor $Colors.Magenta
    Write-Host ""
    
    Add-Content -Path $LOG_FILE -Value ""
    Add-Content -Path $LOG_FILE -Value "========================================"
    Add-Content -Path $LOG_FILE -Value "    $Title"
    Add-Content -Path $LOG_FILE -Value "========================================"
    Add-Content -Path $LOG_FILE -Value ""
}

function Initialize-Logging {
    # Create log directory
    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null
    }
    
    # Initialize log file
    $header = @"
================================================================================
Cross-Platform Dotfiles Installation Log - PowerShell Version
================================================================================
Start Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
User: $env:USERNAME
Computer: $env:COMPUTERNAME
PowerShell Version: $($PSVersionTable.PSVersion)
Working Directory: $(Get-Location)
================================================================================

"@
    
    Set-Content -Path $LOG_FILE -Value $header
    Write-Log "INFO" "Logging initialized: $LOG_FILE"
}

function Test-IsWindows11 {
    try {
        $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
        return [int]$build -ge 22000
    }
    catch {
        return $false
    }
}

function Get-SystemInfo {
    Write-Log "INFO" "Gathering system information..."
    
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    
    Add-Content -Path $LOG_FILE -Value "================ SYSTEM INFORMATION ================"
    Add-Content -Path $LOG_FILE -Value "OS: $($os.Caption) $($os.Version)"
    Add-Content -Path $LOG_FILE -Value "Architecture: $($os.OSArchitecture)"
    Add-Content -Path $LOG_FILE -Value "CPU: $($cpu.Name)"
    Add-Content -Path $LOG_FILE -Value "Memory: $memory GB"
    Add-Content -Path $LOG_FILE -Value "PowerShell: $($PSVersionTable.PSVersion)"
    Add-Content -Path $LOG_FILE -Value "======================================================="
    Add-Content -Path $LOG_FILE -Value ""
}

function Test-PackageManager {
    $packageManager = "none"
    
    try {
        $null = Get-Command winget -ErrorAction Stop
        $packageManager = "winget"
        Write-Log "SUCCESS" "winget package manager detected"
    }
    catch {
        try {
            $null = Get-Command choco -ErrorAction Stop
            $packageManager = "choco"
            Write-Log "SUCCESS" "Chocolatey package manager detected"
        }
        catch {
            Write-Log "WARNING" "No package manager found (winget or chocolatey)"
        }
    }
    
    return $packageManager
}

# Installation state management
$STATE_FILE = "$LOG_DIR\installation_state.json"

# Installation timeouts (in seconds)
$INSTALLATION_TIMEOUTS = @{
    "Git.Git" = 300
    "Microsoft.VisualStudioCode" = 600
    "Google.Chrome" = 300
    "Microsoft.PowerShell" = 300
    "GitHub.cli" = 300
    "Microsoft.VisualStudio.2019.Community" = 3600  # 1 hour
    "Python.Python.3.10" = 600
    "Kitware.CMake" = 600
    "NVIDIA.CUDA" = 1800  # 30 minutes
    "Autodesk.AutoCAD" = 3600  # 1 hour
    "Autodesk.Inventor" = 3600  # 1 hour
    "Autodesk.3dsMax" = 3600  # 1 hour
    "Autodesk.Fusion360" = 1800  # 30 minutes
    "HandBrake.HandBrake" = 600
    "IrfanSkiljan.IrfanView" = 300
    "VideoLAN.VLC" = 600
    "OBSProject.OBSStudio" = 900
    "Valve.Steam" = 900
    "EpicGames.EpicGamesLauncher" = 900
    "Zoom.Zoom" = 600
    "Microsoft.Office" = 3600  # 1 hour
    "ShareX.ShareX" = 300
    "Notion.Notion" = 600
    "Obsidian.Obsidian" = 300
    "AOMEI.Backupper" = 900
    "Oracle.VirtualBox" = 900
    "Rufus.Rufus" = 300
    "RARLab.WinRAR" = 300
    "CrystalDewWorld.CrystalDiskInfo" = 300
    "JAMSoftware.TreeSize" = 300
    "Advanced.IPScanner" = 300
    "MoveMouse.MoveMouse" = 300
    "Wacom.WacomTabletDriver" = 600
    "Logitech.LogiOptionsPlus" = 600
    "Corsair.iCUE" = 900
    "Discord.Discord" = 600
    "PuTTY.PuTTY" = 300
    "TimKosse.FileZillaClient" = 300
    "SikuliX.SikuliX" = 600
    "Siemens.JT2Go" = 600
    "COLMAP.COLMAP" = 900
    "Gyan.FFmpeg" = 600
    "Chocolatey.Chocolatey" = 300
    "Default" = 600  # Default 10 minutes
}

function Save-InstallationState {
    param(
        [string]$PackageId,
        [string]$Status,
        [string]$Details = ""
    )
    
    $state = @{}
    if (Test-Path $STATE_FILE) {
        $state = Get-Content $STATE_FILE | ConvertFrom-Json -AsHashtable
    }
    
    if (-not $state) {
        $state = @{}
    }
    
    $state[$PackageId] = @{
        Status = $Status
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Details = $Details
    }
    
    $state | ConvertTo-Json -Depth 3 | Set-Content $STATE_FILE
}

function Get-InstallationState {
    param([string]$PackageId)
    
    if (-not (Test-Path $STATE_FILE)) {
        return $null
    }
    
    try {
        $state = Get-Content $STATE_FILE | ConvertFrom-Json -AsHashtable
        return $state[$PackageId]
    }
    catch {
        return $null
    }
}

function Test-SoftwareInstalled {
    param(
        [string]$PackageId,
        [string]$SoftwareName = ""
    )
    
    Write-Log "INFO" "Comprehensive installation check for $PackageId..."
    
    # Method 1: Check winget list
    try {
        $wingetResult = winget list --id $PackageId --exact 2>$null
        if ($LASTEXITCODE -eq 0 -and $wingetResult -match $PackageId) {
            Write-Log "SUCCESS" "$PackageId found in winget registry"
            return $true
        }
    }
    catch {
        Write-Log "WARNING" "Winget check failed for $PackageId"
    }
    
    # Method 2: Check Windows Registry (Programs and Features)
    try {
        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        foreach ($key in $uninstallKeys) {
            $programs = Get-ItemProperty $key -ErrorAction SilentlyContinue
            if ($programs) {
                foreach ($program in $programs) {
                    $displayName = $program.DisplayName
                    if ($displayName -and ($displayName -like "*$SoftwareName*" -or $displayName -like "*$($PackageId.Split('.')[1])*")) {
                        Write-Log "SUCCESS" "$PackageId found in registry: $displayName"
                        return $true
                    }
                }
            }
        }
    }
    catch {
        Write-Log "WARNING" "Registry check failed for $PackageId"
    }
    
    # Method 3: Check common installation paths
    $commonPaths = @(
        "${env:ProgramFiles}",
        "${env:ProgramFiles(x86)}",
        "${env:LOCALAPPDATA}\Programs",
        "${env:APPDATA}"
    )
    
    $searchTerms = @($SoftwareName, $PackageId.Split('.')[1], $PackageId.Split('.')[0])
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            foreach ($term in $searchTerms) {
                if ($term) {
                    $found = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$term*" }
                    if ($found) {
                        Write-Log "SUCCESS" "$PackageId found in filesystem: $($found.FullName)"
                        return $true
                    }
                }
            }
        }
    }
    
    # Method 4: Check if executable is in PATH
    $executableNames = @(
        $SoftwareName.ToLower(),
        $PackageId.Split('.')[1].ToLower(),
        ($PackageId.Split('.')[1] + ".exe").ToLower()
    )
    
    foreach ($exec in $executableNames) {
        if ($exec -and (Get-Command $exec -ErrorAction SilentlyContinue)) {
            Write-Log "SUCCESS" "$PackageId executable found in PATH: $exec"
            return $true
        }
    }
    
    Write-Log "INFO" "$PackageId not found through any validation method"
    return $false
}

function Wait-ForInstallationComplete {
    param(
        [string]$PackageId,
        [int]$TimeoutSeconds = 600
    )
    
    Write-Log "INFO" "Waiting for $PackageId installation to complete (timeout: $TimeoutSeconds seconds)..."
    
    $startTime = Get-Date
    $timeout = $startTime.AddSeconds($TimeoutSeconds)
    $lastProcessCount = 0
    $stableCount = 0
    
    while ((Get-Date) -lt $timeout) {
        # Check for installation-related processes
        $installProcesses = @(
            Get-Process -Name "winget" -ErrorAction SilentlyContinue
            Get-Process -Name "msiexec" -ErrorAction SilentlyContinue
            Get-Process -Name "*install*" -ErrorAction SilentlyContinue
            Get-Process -Name "*setup*" -ErrorAction SilentlyContinue
        ) | Where-Object { $_ -ne $null }
        
        $currentProcessCount = $installProcesses.Count
        
        # Log progress every 30 seconds
        if (((Get-Date) - $startTime).TotalSeconds % 30 -eq 0) {
            $elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 0)
            Write-Log "INFO" "Installation progress: $elapsed/$TimeoutSeconds seconds elapsed, $currentProcessCount active processes"
        }
        
        # Check if processes have stabilized (no change for 3 consecutive checks)
        if ($currentProcessCount -eq $lastProcessCount) {
            $stableCount++
            if ($stableCount -ge 3 -and $currentProcessCount -eq 0) {
                Write-Log "SUCCESS" "Installation processes completed for $PackageId"
                return $true
            }
        } else {
            $stableCount = 0
        }
        
        $lastProcessCount = $currentProcessCount
        Start-Sleep -Seconds 10
    }
    
    Write-Log "WARNING" "Installation timeout reached for $PackageId after $TimeoutSeconds seconds"
    return $false
}

function Install-ViaWinget {
    Write-Log "INFO" "Starting comprehensive Windows software installation..."
    
    # Essential packages (always install)
    $essentialPackages = @(
        @{Id="Git.Git"; Name="Git"; Critical=$true},
        @{Id="Microsoft.VisualStudioCode"; Name="Visual Studio Code"; Critical=$true},
        @{Id="Google.Chrome"; Name="Google Chrome"; Critical=$true},
        @{Id="Microsoft.PowerShell"; Name="PowerShell"; Critical=$true},
        @{Id="GitHub.cli"; Name="GitHub CLI"; Critical=$true}
    )
    
    # JK's comprehensive software list
    $comprehensivePackages = @(
        # Development Tools
        @{Id="Microsoft.VisualStudio.2019.Community"; Name="Visual Studio 2019 Community"; Critical=$false},
        @{Id="Python.Python.3.10"; Name="Python 3.10"; Critical=$false},
        @{Id="Kitware.CMake"; Name="CMake"; Critical=$false},
        @{Id="NVIDIA.CUDA"; Name="CUDA Toolkit"; Critical=$false},
        
        # Creative & Design
        @{Id="Autodesk.AutoCAD"; Name="AutoCAD"; Critical=$false},
        @{Id="Autodesk.Inventor"; Name="Inventor"; Critical=$false},
        @{Id="Autodesk.3dsMax"; Name="3ds Max"; Critical=$false},
        @{Id="Autodesk.Fusion360"; Name="Fusion 360"; Critical=$false},
        @{Id="HandBrake.HandBrake"; Name="HandBrake"; Critical=$false},
        @{Id="IrfanSkiljan.IrfanView"; Name="IrfanView"; Critical=$false},
        
        # Media & Entertainment
        @{Id="VideoLAN.VLC"; Name="VLC Media Player"; Critical=$false},
        @{Id="OBSProject.OBSStudio"; Name="OBS Studio"; Critical=$false},
        @{Id="Valve.Steam"; Name="Steam"; Critical=$false},
        @{Id="EpicGames.EpicGamesLauncher"; Name="Epic Games Launcher"; Critical=$false},
        @{Id="Zoom.Zoom"; Name="Zoom"; Critical=$false},
        
        # Productivity & Office
        @{Id="Microsoft.Office"; Name="Microsoft Office"; Critical=$false},
        @{Id="ShareX.ShareX"; Name="ShareX"; Critical=$false},
        @{Id="Notion.Notion"; Name="Notion"; Critical=$false},
        @{Id="Obsidian.Obsidian"; Name="Obsidian"; Critical=$false},
        @{Id="AOMEI.Backupper"; Name="AOMEI Backupper"; Critical=$false},
        
        # System Utilities
        @{Id="Oracle.VirtualBox"; Name="VirtualBox"; Critical=$false},
        @{Id="Rufus.Rufus"; Name="Rufus"; Critical=$false},
        @{Id="RARLab.WinRAR"; Name="WinRAR"; Critical=$false},
        @{Id="CrystalDewWorld.CrystalDiskInfo"; Name="CrystalDiskInfo"; Critical=$false},
        @{Id="JAMSoftware.TreeSize"; Name="TreeSize"; Critical=$false},
        @{Id="Advanced.IPScanner"; Name="Advanced IP Scanner"; Critical=$false},
        @{Id="MoveMouse.MoveMouse"; Name="Move Mouse"; Critical=$false},
        
        # Hardware & Drivers
        @{Id="Wacom.WacomTabletDriver"; Name="Wacom Tablet Driver"; Critical=$false},
        @{Id="Logitech.LogiOptionsPlus"; Name="Logitech Options+"; Critical=$false},
        @{Id="Corsair.iCUE"; Name="Corsair iCUE"; Critical=$false},
        
        # Network & Remote
        @{Id="Discord.Discord"; Name="Discord"; Critical=$false},
        @{Id="PuTTY.PuTTY"; Name="PuTTY"; Critical=$false},
        @{Id="TimKosse.FileZillaClient"; Name="FileZilla Client"; Critical=$false},
        
        # Specialized Tools
        @{Id="SikuliX.SikuliX"; Name="SikuliX"; Critical=$false},
        @{Id="Siemens.JT2Go"; Name="JT2Go"; Critical=$false},
        @{Id="COLMAP.COLMAP"; Name="COLMAP"; Critical=$false},
        @{Id="Gyan.FFmpeg"; Name="FFmpeg"; Critical=$false},
        @{Id="Chocolatey.Chocolatey"; Name="Chocolatey"; Critical=$false}
    )
    
    # Install essential packages first
    Write-Log "INFO" "Installing essential packages (Phase 1/2)..."
    $totalEssential = $essentialPackages.Count
    $currentEssential = 0
    
    foreach ($package in $essentialPackages) {
        $currentEssential++
        Write-Log "INFO" "[$currentEssential/$totalEssential] Processing essential package: $($package.Name)"
        Install-RobustPackage $package.Id $package.Name $package.Critical
    }
    
    # Ask user about comprehensive installation
    Write-Host ""
    Write-Host "Essential packages installation completed!" -ForegroundColor Green
    Write-Host ""
    $response = Read-Host "Install JK's comprehensive software suite? This includes AutoCAD, Inventor, 3dsMax, Office 365, and many more tools (y/N)"
    
    if ($response -match '^[Yy]') {
        Write-Log "INFO" "Installing comprehensive software suite (Phase 2/2)..."
        Write-Log "INFO" "This may take 1-2 hours depending on your internet connection and system performance"
        
        $totalComprehensive = $comprehensivePackages.Count
        $currentComprehensive = 0
        
        foreach ($package in $comprehensivePackages) {
            $currentComprehensive++
            Write-Log "INFO" "[$currentComprehensive/$totalComprehensive] Processing comprehensive package: $($package.Name)"
            Install-RobustPackage $package.Id $package.Name $package.Critical
        }
        
        # Special handling for packages that might not be in winget
        Install-SpecialPackages
    } else {
        Write-Log "INFO" "Skipping comprehensive software installation"
        Write-Log "INFO" "You can run this script again with -WindowsFull to install the full suite"
    }
    
    # Final summary
    Write-Log "INFO" "Installation process completed. Check the log for detailed results."
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [bool]$Essential = $false
    )
    
    Write-Log "INFO" "Installing $PackageId..."
    try {
        # Check if already installed
        $installed = winget list --id $PackageId --exact 2>$null
        if ($LASTEXITCODE -eq 0 -and $installed -match $PackageId) {
            Write-Log "SUCCESS" "$PackageId already installed"
            return
        }
        
        # Install the package
        $result = winget install --id $PackageId --silent --accept-source-agreements --accept-package-agreements 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "SUCCESS" "$PackageId installed successfully"
        } else {
            if ($Essential) {
                Write-Log "ERROR" "Failed to install essential package: $PackageId"
            } else {
                Write-Log "WARNING" "Failed to install $PackageId (non-essential)"
            }
        }
    }
    catch {
        Write-Log "ERROR" "Error installing $PackageId: $($_.Exception.Message)"
    }
}

function Install-SpecialPackages {
    Write-Log "INFO" "Installing packages that may require special handling..."
    
    # NVIDIA OptiX (requires manual download typically)
    Write-Log "INFO" "Checking for NVIDIA OptiX..."
    Write-Log "WARNING" "NVIDIA OptiX requires manual download from NVIDIA Developer Portal"
    Write-Log "INFO" "Visit: https://developer.nvidia.com/designworks/optix/download"
    
    # Benchmate (might not be in winget)
    Write-Log "INFO" "Checking for Benchmate..."
    Install-WingetPackage "Benchmate.Benchmate" $false
    
    # Additional manual installations that are common issues
    $manualInstalls = @(
        @{Name="NVIDIA OptiX"; Url="https://developer.nvidia.com/designworks/optix/download"},
        @{Name="Autodesk Desktop App"; Url="https://www.autodesk.com/products/desktop-app"},
        @{Name="Wacom Tablet Driver"; Url="https://www.wacom.com/en-us/support/product-support/drivers"}
    )
    
    Write-Log "INFO" "Some software may require manual installation:"
    foreach ($item in $manualInstalls) {
        Write-Log "INFO" "  - $($item.Name): $($item.Url)"
    }
}

function Install-ViaChocolatey {
    Write-Log "INFO" "Installing packages via Chocolatey..."
    
    $packages = @(
        "git", "neovim", "vscode", "googlechrome", "firefox", 
        "vlc", "obsidian", "powershell-core", "gh", "bat", "fd", "ripgrep"
    )
    
    foreach ($package in $packages) {
        Write-Log "INFO" "Installing $package..."
        try {
            $result = choco install $package -y 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "SUCCESS" "$package installed successfully"
            } else {
                Write-Log "WARNING" "Failed to install $package"
            }
        }
        catch {
            Write-Log "ERROR" "Error installing $package: $($_.Exception.Message)"
        }
    }
}

function Set-WindowsObsidianSetup {
    Write-Section "Windows Obsidian + Git Setup"
    
    Write-Log "INFO" "Configuring Git for Windows..."
    
    try {
        git config --global user.name "jk1rby" 2>$null
        git config --global user.email "jameskirby663@gmail.com" 2>$null
        git config --global credential.helper manager 2>$null
        Write-Log "SUCCESS" "Git configuration completed"
    }
    catch {
        Write-Log "ERROR" "Failed to configure Git: $($_.Exception.Message)"
    }
    
    # Create Obsidian vault directory
    $vaultDir = "$env:USERPROFILE\Documents\notes"
    if (-not (Test-Path $vaultDir)) {
        Write-Log "INFO" "Creating Obsidian vault directory..."
        New-Item -ItemType Directory -Path $vaultDir -Force | Out-Null
    }
    
    Set-Location $vaultDir
    
    # Initialize Git repository
    if (-not (Test-Path ".git")) {
        Write-Log "INFO" "Initializing Git repository..."
        try {
            git init 2>&1 | Add-Content -Path $LOG_FILE
            git remote add origin https://github.com/jk1rby/notes.git 2>&1 | Add-Content -Path $LOG_FILE
            Write-Log "SUCCESS" "Git repository initialized"
        }
        catch {
            Write-Log "ERROR" "Failed to initialize Git repository: $($_.Exception.Message)"
        }
    }
    
    Write-Log "SUCCESS" "Windows Obsidian setup completed"
}

function Show-Usage {
    Write-Host "Cross-Platform Dotfiles Installation Script - PowerShell Version" -ForegroundColor $Colors.Cyan
    Write-Host ""
    Write-Host "Usage: .\install-cross-platform.ps1 [OPTIONS]" -ForegroundColor $Colors.Blue
    Write-Host ""
    Write-Host "Options:" -ForegroundColor $Colors.Yellow
    Write-Host "  -Force          Automatically resolve conflicts"
    Write-Host "  -WindowsFull    Enable full Windows 11 setup"
    Write-Host "  -Minimal        Install only essential components"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor $Colors.Green
    Write-Host "  .\install-cross-platform.ps1 -WindowsFull"
    Write-Host "  .\install-cross-platform.ps1 -Minimal"
    Write-Host ""
}

function Generate-InstallationSummary {
    $summary = @{
        TotalPackages = 0
        SuccessfulPackages = 0
        FailedPackages = 0
        SkippedPackages = 0
        CriticalFailures = 0
    }
    
    if (Test-Path $STATE_FILE) {
        try {
            $state = Get-Content $STATE_FILE | ConvertFrom-Json -AsHashtable
            
            foreach ($package in $state.Keys) {
                $summary.TotalPackages++
                
                switch ($state[$package].Status) {
                    "SUCCESS" { $summary.SuccessfulPackages++ }
                    "FAILED_CRITICAL" { 
                        $summary.FailedPackages++
                        $summary.CriticalFailures++
                    }
                    "FAILED_NON_CRITICAL" { $summary.FailedPackages++ }
                    "FAILED_EXCEPTION" { $summary.FailedPackages++ }
                    "SKIPPED" { $summary.SkippedPackages++ }
                }
            }
        }
        catch {
            Write-Log "WARNING" "Could not parse installation state for summary"
        }
    }
    
    return $summary
}

function Complete-Installation {
    param([int]$ExitCode = 0)
    
    $endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Generate comprehensive installation summary
    $summary = Generate-InstallationSummary
    
    Add-Content -Path $LOG_FILE -Value ""
    Add-Content -Path $LOG_FILE -Value "================ INSTALLATION SUMMARY ================"
    Add-Content -Path $LOG_FILE -Value "End Time: $endTime"
    Add-Content -Path $LOG_FILE -Value "Exit Code: $ExitCode"
    
    if ($ExitCode -eq 0) {
        Add-Content -Path $LOG_FILE -Value "Status: SUCCESS"
        Write-Log "SUCCESS" "Installation completed successfully!"
    } else {
        Add-Content -Path $LOG_FILE -Value "Status: FAILED"
        Write-Log "ERROR" "Installation completed with errors!"
    }
    
    # Add summary statistics
    Add-Content -Path $LOG_FILE -Value ""
    Add-Content -Path $LOG_FILE -Value "Installation Statistics:"
    Add-Content -Path $LOG_FILE -Value "- Total Packages: $($summary.TotalPackages)"
    Add-Content -Path $LOG_FILE -Value "- Successful: $($summary.SuccessfulPackages)"
    Add-Content -Path $LOG_FILE -Value "- Failed: $($summary.FailedPackages)"
    Add-Content -Path $LOG_FILE -Value "- Skipped (Already Installed): $($summary.SkippedPackages)"
    Add-Content -Path $LOG_FILE -Value "- Critical Failures: $($summary.CriticalFailures)"
    
    $logSize = [math]::Round((Get-Item $LOG_FILE).Length / 1KB, 2)
    Add-Content -Path $LOG_FILE -Value "Log Size: $logSize KB"
    Add-Content -Path $LOG_FILE -Value "======================================================="
    
    # Display summary to user
    Write-Host ""
    Write-Host "================ INSTALLATION SUMMARY ================" -ForegroundColor Cyan
    Write-Host "Total Packages: $($summary.TotalPackages)" -ForegroundColor White
    Write-Host "Successful: $($summary.SuccessfulPackages)" -ForegroundColor Green
    Write-Host "Failed: $($summary.FailedPackages)" -ForegroundColor Red
    Write-Host "Skipped (Already Installed): $($summary.SkippedPackages)" -ForegroundColor Yellow
    Write-Host "Critical Failures: $($summary.CriticalFailures)" -ForegroundColor Red
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($summary.CriticalFailures -gt 0) {
        Write-Host "WARNING: Some critical installations failed!" -ForegroundColor Red
        Write-Host "Please review the log for details and manual installation requirements." -ForegroundColor Yellow
    }
    
    Write-Log "SUCCESS" "Installation log saved to: $LOG_FILE"
    Write-Log "INFO" "Installation state saved to: $STATE_FILE"
    
    # Check for manual installation requirements
    $manualInstallLog = "$LOG_DIR\manual_installations_required.txt"
    if (Test-Path $manualInstallLog) {
        Write-Log "INFO" "Manual installation requirements: $manualInstallLog"
        Write-Host "Manual installation guide created: $manualInstallLog" -ForegroundColor Yellow
    }
    
    # Display next steps
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Review the installation log for any issues"
    Write-Host "2. Check manual installation requirements if any"
    Write-Host "3. Restart applications that may have been updated"
    Write-Host "4. Run Windows Update to ensure all components are current"
    
    if ($summary.FailedPackages -gt 0) {
        Write-Host "5. Consider retrying failed installations manually" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Main execution
try {
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    # Initialize
    Initialize-Logging
    Get-SystemInfo
    
    # Header
    Write-Host "========================================" -ForegroundColor $Colors.Cyan
    Write-Host "    Cross-Platform Dotfiles Setup      " -ForegroundColor $Colors.Cyan
    Write-Host "    Author: jk1rby (PowerShell)        " -ForegroundColor $Colors.Cyan
    Write-Host "========================================" -ForegroundColor $Colors.Cyan
    Write-Host ""
    
    Write-Log "INFO" "PowerShell version: $($PSVersionTable.PSVersion)"
    
    # System detection
    Write-Section "System Detection"
    
    $osVersion = [System.Environment]::OSVersion.Version
    Write-Log "INFO" "Detected: Windows $($osVersion.Major).$($osVersion.Minor)"
    
    if (Test-IsWindows11) {
        Write-Log "SUCCESS" "Windows 11 detected - Full setup available"
        $enableWindowsSetup = $true
    } else {
        Write-Log "WARNING" "Windows 10 or older detected - Limited compatibility"
        $enableWindowsSetup = $false
    }
    
    # Package manager detection
    $packageManager = Test-PackageManager
    
    # Installation
    if (-not $Minimal) {
        Write-Section "Installing Windows Dependencies"
        
        switch ($packageManager) {
            "winget" { Install-ViaWinget }
            "choco"  { Install-ViaChocolatey }
            default  { Write-Log "WARNING" "No package manager available - skipping package installation" }
        }
    }
    
    # Windows-specific setup
    if ($WindowsFull -and $enableWindowsSetup) {
        Set-WindowsObsidianSetup
    }
    
    # Final steps
    Write-Section "Installation Complete"
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor $Colors.Yellow
    Write-Host "1. Restart your terminal"
    Write-Host "2. Open PowerShell as Administrator if needed"
    Write-Host "3. Test installed applications"
    Write-Host ""
    
    Complete-Installation 0
}
catch {
    Write-Log "ERROR" "Installation failed: $($_.Exception.Message)"
    Complete-Installation 1
}