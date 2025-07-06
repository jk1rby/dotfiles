@echo off
REM Cross-Platform Dotfiles Installation Script - Windows Batch Version
REM Author: jk1rby

setlocal enabledelayedexpansion

REM Colors for Windows (limited support)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

REM Configuration
set "DOTFILES_DIR=%USERPROFILE%\dotfiles"
set "LOG_DIR=%DOTFILES_DIR%\logs"
set "TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "TIMESTAMP=%TIMESTAMP: =0%"
set "LOG_FILE=%LOG_DIR%\install_%TIMESTAMP%.log"

echo ========================================
echo    Cross-Platform Dotfiles Setup      
echo    Author: jk1rby (Windows Version)    
echo ========================================
echo.

REM Create log directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Initialize logging
echo ================================================================================ > "%LOG_FILE%"
echo Cross-Platform Dotfiles Installation Log - Windows Version >> "%LOG_FILE%"
echo ================================================================================ >> "%LOG_FILE%"
echo Start Time: %date% %time% >> "%LOG_FILE%"
echo User: %USERNAME% >> "%LOG_FILE%"
echo Computer: %COMPUTERNAME% >> "%LOG_FILE%"
echo Working Directory: %CD% >> "%LOG_FILE%"
echo ================================================================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo %INFO% Logging initialized: %LOG_FILE%
echo [%date% %time%] [INFO] Logging initialized >> "%LOG_FILE%"

REM System Detection
echo %INFO% Detecting Windows system...
echo [%date% %time%] [INFO] Detecting Windows system >> "%LOG_FILE%"

for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
echo %INFO% Detected: Windows %VERSION%
echo [%date% %time%] [INFO] Detected: Windows %VERSION% >> "%LOG_FILE%"

REM Check if Windows 11 (build 22000+)
for /f "tokens=3" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul') do set BUILD=%%a
if %BUILD% GEQ 22000 (
    echo %SUCCESS% Windows 11 detected - Full setup available
    echo [%date% %time%] [SUCCESS] Windows 11 detected - Full setup available >> "%LOG_FILE%"
    set "ENABLE_WINDOWS_SETUP=true"
) else (
    echo %WARNING% Windows 10 or older detected - Limited compatibility
    echo [%date% %time%] [WARNING] Windows 10 or older detected - Limited compatibility >> "%LOG_FILE%"
    set "ENABLE_WINDOWS_SETUP=false"
)

REM Check for package managers
set "PACKAGE_MANAGER=none"

winget --version >nul 2>&1
if %errorlevel% equ 0 (
    echo %SUCCESS% winget package manager detected
    echo [%date% %time%] [SUCCESS] winget package manager detected >> "%LOG_FILE%"
    set "PACKAGE_MANAGER=winget"
) else (
    choco --version >nul 2>&1
    if !errorlevel! equ 0 (
        echo %SUCCESS% Chocolatey package manager detected
        echo [%date% %time%] [SUCCESS] Chocolatey package manager detected >> "%LOG_FILE%"
        set "PACKAGE_MANAGER=choco"
    ) else (
        echo %WARNING% No package manager found - manual installation required
        echo [%date% %time%] [WARNING] No package manager found >> "%LOG_FILE%"
    )
)

REM Parse command line arguments
set "FORCE_MODE=false"
set "MINIMAL_MODE=false"
set "WINDOWS_FULL_MODE=false"

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--force" (
    set "FORCE_MODE=true"
    echo %INFO% Force mode enabled
    echo [%date% %time%] [INFO] Force mode enabled >> "%LOG_FILE%"
)
if "%~1"=="--minimal" (
    set "MINIMAL_MODE=true"
    echo %INFO% Minimal mode enabled
    echo [%date% %time%] [INFO] Minimal mode enabled >> "%LOG_FILE%"
)
if "%~1"=="--windows-full" (
    set "WINDOWS_FULL_MODE=true"
    echo %INFO% Windows full mode enabled
    echo [%date% %time%] [INFO] Windows full mode enabled >> "%LOG_FILE%"
)
if "%~1"=="--help" (
    call :show_usage
    exit /b 0
)
shift
goto :parse_args

:args_done

REM Install essential packages if not minimal mode
if "%MINIMAL_MODE%"=="false" (
    echo.
    echo ========================================
    echo Installing Windows Dependencies
    echo ========================================
    echo.

    if "%PACKAGE_MANAGER%"=="winget" (
        call :install_via_winget
    ) else if "%PACKAGE_MANAGER%"=="choco" (
        call :install_via_choco
    ) else (
        echo %WARNING% No package manager available - skipping package installation
        echo [%date% %time%] [WARNING] No package manager available >> "%LOG_FILE%"
    )
)

REM Windows-specific setup
if "%WINDOWS_FULL_MODE%"=="true" (
    call :windows_obsidian_setup
)

REM Final steps
echo.
echo ========================================
echo Installation Complete
echo ========================================
echo.

echo %SUCCESS% Windows dotfiles installation completed!
echo [%date% %time%] [SUCCESS] Installation completed >> "%LOG_FILE%"

echo.
echo Next steps:
echo 1. Restart your terminal
echo 2. Configure Git: git config --global user.name "jk1rby"
echo 3. Configure Git: git config --global user.email "jameskirby663@gmail.com"
echo.

echo Installation log saved to: %LOG_FILE%

REM Finalize log
echo. >> "%LOG_FILE%"
echo ================ INSTALLATION SUMMARY ================ >> "%LOG_FILE%"
echo End Time: %date% %time% >> "%LOG_FILE%"
echo Status: SUCCESS >> "%LOG_FILE%"
echo ======================================================= >> "%LOG_FILE%"

exit /b 0

REM ============================= FUNCTIONS =============================

:install_via_winget
echo %INFO% Installing packages via winget...
echo [%date% %time%] [INFO] Installing packages via winget >> "%LOG_FILE%"

set packages=Git.Git Neovim.Neovim Microsoft.VisualStudioCode Google.Chrome Mozilla.Firefox VideoLAN.VLC Obsidian.Obsidian Microsoft.PowerShell GitHub.cli

for %%p in (%packages%) do (
    echo %INFO% Installing %%p...
    echo [%date% %time%] [INFO] Installing %%p >> "%LOG_FILE%"
    winget install --id %%p --silent --accept-source-agreements --accept-package-agreements >> "%LOG_FILE%" 2>&1
    if !errorlevel! equ 0 (
        echo %SUCCESS% %%p installed successfully
        echo [%date% %time%] [SUCCESS] %%p installed successfully >> "%LOG_FILE%"
    ) else (
        echo %WARNING% Failed to install %%p
        echo [%date% %time%] [WARNING] Failed to install %%p >> "%LOG_FILE%"
    )
)
exit /b 0

:install_via_choco
echo %INFO% Installing packages via Chocolatey...
echo [%date% %time%] [INFO] Installing packages via Chocolatey >> "%LOG_FILE%"

set packages=git neovim vscode googlechrome firefox vlc obsidian powershell-core gh

for %%p in (%packages%) do (
    echo %INFO% Installing %%p...
    echo [%date% %time%] [INFO] Installing %%p >> "%LOG_FILE%"
    choco install %%p -y >> "%LOG_FILE%" 2>&1
    if !errorlevel! equ 0 (
        echo %SUCCESS% %%p installed successfully
        echo [%date% %time%] [SUCCESS] %%p installed successfully >> "%LOG_FILE%"
    ) else (
        echo %WARNING% Failed to install %%p
        echo [%date% %time%] [WARNING] Failed to install %%p >> "%LOG_FILE%"
    )
)
exit /b 0

:windows_obsidian_setup
echo.
echo ========================================
echo Windows Obsidian + Git Setup
echo ========================================
echo.

echo %INFO% Configuring Git for Windows...
echo [%date% %time%] [INFO] Configuring Git for Windows >> "%LOG_FILE%"

git config --global user.name "jk1rby" 2>nul
git config --global user.email "jameskirby663@gmail.com" 2>nul
git config --global credential.helper manager 2>nul

echo %SUCCESS% Git configuration completed
echo [%date% %time%] [SUCCESS] Git configuration completed >> "%LOG_FILE%"

REM Create Obsidian vault directory
set "VAULT_DIR=%USERPROFILE%\Documents\notes"
if not exist "%VAULT_DIR%" (
    echo %INFO% Creating Obsidian vault directory...
    echo [%date% %time%] [INFO] Creating Obsidian vault directory >> "%LOG_FILE%"
    mkdir "%VAULT_DIR%"
)

cd /d "%VAULT_DIR%"

REM Initialize Git repository
if not exist ".git" (
    echo %INFO% Initializing Git repository...
    echo [%date% %time%] [INFO] Initializing Git repository >> "%LOG_FILE%"
    git init >> "%LOG_FILE%" 2>&1
    git remote add origin https://github.com/jk1rby/notes.git >> "%LOG_FILE%" 2>&1
)

echo %SUCCESS% Windows Obsidian setup completed
echo [%date% %time%] [SUCCESS] Windows Obsidian setup completed >> "%LOG_FILE%"
exit /b 0

:show_usage
echo Cross-Platform Dotfiles Installation Script - Windows Version
echo.
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --force          Automatically resolve conflicts
echo   --windows-full   Enable full Windows 11 setup
echo   --minimal        Install only essential components
echo   --help           Show this help message
echo.
echo Supported Systems:
echo   - Windows 11 (build 22000+)
echo   - Windows 10 (limited compatibility)
echo.
exit /b 0