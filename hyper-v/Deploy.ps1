#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Deploy Kubernetes multi-node cluster using Vagrant and Hyper-V

.DESCRIPTION
    This script automates the deployment of a complete Kubernetes cluster:
    - Creates 1 control plane node (2 CPU, 4GB RAM)
    - Creates 2 worker nodes (2 CPU, 4GB RAM each)
    - Installs Kubernetes v1.33.x
    - Configures Calico CNI
    - Automatically joins workers to the cluster

.PARAMETER Destroy
    Destroy existing cluster before deploying new one

.PARAMETER SkipPrereqs
    Skip prerequisite checks

.EXAMPLE
    .\Deploy.ps1

.EXAMPLE
    .\Deploy.ps1 -Destroy

.NOTES
    Deployment takes approximately 15-20 minutes depending on internet connection
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage="Destroy existing cluster before deploying")]
    [switch]$Destroy,

    [Parameter(HelpMessage="Skip prerequisite checks")]
    [switch]$SkipPrereqs
)

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

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" -ForegroundColor Cyan
}

# Check if running as Administrator
if (-not $SkipPrereqs) {
    Write-Header "Checking Prerequisites"
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator!"
        Write-Output "Please right-click and select 'Run as Administrator'"
        exit 1
    }
    Write-Success "Running with Administrator privileges"

    # Check Vagrant
    if (-not (Get-Command vagrant -ErrorAction SilentlyContinue)) {
        Write-Error "Vagrant is not installed!"
        Write-Output "Please run .\Install-Prerequisites.ps1 first"
        exit 1
    }
    Write-Success "Vagrant is installed: $(vagrant --version)"

    # Check Hyper-V
    $hyperVStatus = Get-WindowsOptionalFeature -FeatureName Microsoft-Hyper-V-All -Online
    if ($hyperVStatus.State -ne "Enabled") {
        Write-Error "Hyper-V is not enabled!"
        Write-Output "Please run .\Install-Prerequisites.ps1 first"
        exit 1
    }
    Write-Success "Hyper-V is enabled"
}

# Change to script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath
Write-Info "Working directory: $scriptPath"

# Handle destroy flag
if ($Destroy) {
    Write-Header "Destroying Existing Cluster"
    Write-Warning "This will permanently delete all VMs and data!"

    $confirmation = Read-Host "Are you sure you want to destroy the cluster? (yes/no)"
    if ($confirmation -ne "yes") {
        Write-Output "Deployment cancelled."
        exit 0
    }

    Write-Output "Destroying cluster..."
    try {
        vagrant destroy -f
        Write-Success "Cluster destroyed successfully"

        # Clean up join command file
        if (Test-Path "join-command.sh") {
            Remove-Item "join-command.sh" -Force
            Write-Info "Cleaned up join-command.sh"
        }
    } catch {
        Write-Error "Failed to destroy cluster: $_"
        Write-Warning "You may need to manually clean up VMs in Hyper-V Manager"
    }

    Write-Output ""
}

# Check if VMs already exist
Write-Header "Checking Existing VMs"
try {
    $vagrantStatus = vagrant status 2>&1 | Out-String
    if ($vagrantStatus -match "running") {
        Write-Warning "Some VMs are already running"
        Write-Output $vagrantStatus
        Write-Output ""

        $response = Read-Host "Destroy and rebuild? (y/n)"
        if ($response -eq 'y') {
            Write-Output "Destroying existing VMs..."
            vagrant destroy -f
            Write-Success "Existing VMs destroyed"
        } else {
            Write-Output "Deployment cancelled. Use 'vagrant up' to start existing VMs."
            exit 0
        }
    }
} catch {
    # No existing Vagrant environment, continue
    Write-Info "No existing cluster found"
}

# Configure SMB credentials for synced folders
Write-Header "Configuring SMB Credentials"
Write-Output "Vagrant needs SMB credentials to share folders with the VMs."
Write-Output "Enter your Windows username and password (used for SMB authentication)."
Write-Output ""

if (-not $env:VAGRANT_SMB_USERNAME) {
    $username = Read-Host "Windows Username (default: $env:USERNAME)"
    if ([string]::IsNullOrWhiteSpace($username)) {
        $username = $env:USERNAME
    }
    $env:VAGRANT_SMB_USERNAME = $username
}

if (-not $env:VAGRANT_SMB_PASSWORD) {
    Write-Warning "Note: Password will be stored in environment variable for this session only"
    $securePassword = Read-Host "Windows Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $env:VAGRANT_SMB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

Write-Success "SMB credentials configured"

# Start deployment
Write-Header "Starting Kubernetes Cluster Deployment"
Write-Info "This will take approximately 15-20 minutes"
Write-Output ""
Write-Output "Cluster specifications:"
Write-Output "  - Control Plane: 1 node (2 CPU, 4GB RAM) - 192.168.56.10"
Write-Output "  - Workers: 2 nodes (2 CPU, 4GB RAM each) - 192.168.56.11-12"
Write-Output "  - Kubernetes: v1.33.x"
Write-Output "  - CNI: Calico"
Write-Output "  - OS: Ubuntu 22.04 LTS"
Write-Output ""

$startTime = Get-Date

try {
    Write-Info "Running vagrant up..."
    Write-Output ""

    vagrant up --provider hyperv

    Write-Output ""
    Write-Success "Deployment completed successfully!"

    $endTime = Get-Date
    $duration = $endTime - $startTime
    Write-Info "Total time: $($duration.Minutes) minutes $($duration.Seconds) seconds"

} catch {
    Write-Error "Deployment failed: $_"
    Write-Output ""
    Write-Output "Troubleshooting steps:"
    Write-Output "  1. Check Hyper-V Manager for VM status"
    Write-Output "  2. Review error messages above"
    Write-Output "  3. Try: vagrant destroy -f && vagrant up --provider hyperv"
    Write-Output "  4. Check firewall and network settings"
    exit 1
}

# Verify cluster
Write-Header "Verifying Cluster Status"
try {
    Write-Output "Checking node status..."
    $nodeStatus = vagrant ssh controlplane -c "kubectl get nodes" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Output $nodeStatus
        Write-Output ""
        Write-Success "Cluster is operational!"
    } else {
        Write-Warning "Could not verify cluster status"
        Write-Output "You can manually check with: vagrant ssh controlplane -c 'kubectl get nodes'"
    }
} catch {
    Write-Warning "Could not verify cluster status: $_"
}

# Display access information
Write-Header "Cluster Access Information"
Write-Output "SSH into nodes:"
Write-Output "  vagrant ssh controlplane"
Write-Output "  vagrant ssh worker1"
Write-Output "  vagrant ssh worker2"
Write-Output ""
Write-Output "Verify cluster:"
Write-Output "  vagrant ssh controlplane -c 'kubectl get nodes'"
Write-Output "  vagrant ssh controlplane -c 'kubectl get pods -A'"
Write-Output ""
Write-Output "Test deployment:"
Write-Output "  vagrant ssh controlplane -c 'kubectl create deployment nginx --image=nginx'"
Write-Output "  vagrant ssh controlplane -c 'kubectl get pods'"
Write-Output ""

Write-Header "Common Commands"
Write-Output "Stop cluster:    vagrant halt"
Write-Output "Start cluster:   vagrant up"
Write-Output "Destroy cluster: vagrant destroy -f"
Write-Output "Cluster status:  vagrant status"
Write-Output ""

Write-ColorOutput "Kubernetes cluster is ready for use!" -ForegroundColor Green
Write-Output ""
