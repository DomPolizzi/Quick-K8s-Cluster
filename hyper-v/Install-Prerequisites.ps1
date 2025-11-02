#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Install prerequisites for Kubernetes Vagrant cluster on Windows with Hyper-V

.DESCRIPTION
    This script installs and configures all necessary components:
    - Enables Hyper-V (if not already enabled)
    - Installs Chocolatey package manager
    - Installs Vagrant
    - Creates Hyper-V virtual switch for cluster networking

.EXAMPLE
    .\Install-Prerequisites.ps1

.NOTES
    Requires: Windows 10/11 Pro/Enterprise/Education or Windows Server
    Requires: Administrator privileges
    Requires: At least 16GB RAM recommended
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    $originalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $originalColor
}

function Write-Header {
    param([string]$Message)
    Write-Output "`n========================================="
    Write-ColorOutput $Message -ForegroundColor Cyan
    Write-Output "=========================================`n"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as Administrator
Write-Header "Checking Administrator Privileges"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator!"
    Write-Output "Please right-click and select 'Run as Administrator'"
    exit 1
}
Write-Success "Running with Administrator privileges"

# Check Windows version
Write-Header "Checking Windows Version"
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = [System.Environment]::OSVersion.Version
Write-Output "OS: $($osInfo.Caption)"
Write-Output "Version: $($osInfo.Version)"

if ($osInfo.Caption -match "Home") {
    Write-Error "Windows Home edition does not support Hyper-V"
    Write-Output "You need Windows 10/11 Pro, Enterprise, or Education"
    exit 1
}
Write-Success "Windows edition supports Hyper-V"

# Check RAM
Write-Header "Checking System Resources"
$totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
Write-Output "Total RAM: $totalRAM GB"

if ($totalRAM -lt 16) {
    Write-Warning "Less than 16GB RAM detected. Cluster may experience performance issues."
    Write-Output "Recommended: 16GB or more"
} else {
    Write-Success "Sufficient RAM available"
}

# Check if virtualization is enabled
$hyperVStatus = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
if ($hyperVStatus.State -eq "Enabled") {
    Write-Success "Hyper-V is already enabled"
} else {
    Write-Header "Enabling Hyper-V"
    Write-Output "This will require a system reboot..."

    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
        Write-Success "Hyper-V feature enabled"

        Write-Warning "REBOOT REQUIRED!"
        Write-Output "Please reboot your computer and run this script again."
        $response = Read-Host "Reboot now? (y/n)"
        if ($response -eq 'y') {
            Restart-Computer -Force
        }
        exit 0
    } catch {
        Write-Error "Failed to enable Hyper-V: $_"
        exit 1
    }
}

# Check if Chocolatey is installed
Write-Header "Checking Chocolatey Package Manager"
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Success "Chocolatey is already installed"
    choco --version
} else {
    Write-Output "Installing Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installed successfully"

        # Refresh environment
        $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
        refreshenv
    } catch {
        Write-Error "Failed to install Chocolatey: $_"
        exit 1
    }
}

# Check if Vagrant is installed
Write-Header "Checking Vagrant"
if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    $vagrantVersion = vagrant --version
    Write-Success "Vagrant is already installed: $vagrantVersion"
} else {
    Write-Output "Installing Vagrant via Chocolatey..."
    try {
        choco install vagrant -y
        Write-Success "Vagrant installed successfully"

        # Refresh environment to get vagrant command
        refreshenv
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Error "Failed to install Vagrant: $_"
        exit 1
    }
}

# Create Hyper-V Virtual Switch if it doesn't exist
Write-Header "Configuring Hyper-V Virtual Switch"
$switchName = "Default Switch"
$existingSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue

if ($existingSwitch) {
    Write-Success "Virtual Switch '$switchName' already exists"
} else {
    Write-Output "The 'Default Switch' should exist by default on Hyper-V"
    Write-Output "Checking for any external switches..."

    $externalSwitches = Get-VMSwitch | Where-Object { $_.SwitchType -eq "External" }
    if ($externalSwitches) {
        Write-Success "Found existing external switch(es):"
        $externalSwitches | ForEach-Object { Write-Output "  - $($_.Name)" }
    } else {
        Write-Warning "No external virtual switch found"
        Write-Output "You may need to create one manually via Hyper-V Manager"
    }
}

# Check firewall status
Write-Header "Checking Firewall Configuration"
$firewallProfiles = Get-NetFirewallProfile
$activeProfiles = $firewallProfiles | Where-Object { $_.Enabled -eq $true }
if ($activeProfiles) {
    Write-Output "Active firewall profiles detected:"
    $activeProfiles | ForEach-Object { Write-Output "  - $($_.Name)" }
    Write-Warning "If you experience connectivity issues, you may need to configure firewall rules"
} else {
    Write-Output "No active firewall profiles detected"
}

# Summary
Write-Header "Installation Summary"
Write-Success "All prerequisites are installed!"
Write-Output "`nInstalled components:"
Write-Output "  - Hyper-V: Enabled"
Write-Output "  - Chocolatey: $(choco --version)"
Write-Output "  - Vagrant: $(vagrant --version)"
Write-Output ""
Write-Output "Next steps:"
Write-Output "  1. Open PowerShell as Administrator"
Write-Output "  2. Navigate to this directory"
Write-Output "  3. Run: .\Deploy.ps1"
Write-Output ""
Write-ColorOutput "Ready to deploy Kubernetes cluster!" -ForegroundColor Green
