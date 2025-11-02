# Kubernetes Cluster Helper Functions for PowerShell
# Source this file to get helpful functions: . .\Helpers.ps1

<#
.SYNOPSIS
    Helper functions for managing Kubernetes Vagrant cluster on Hyper-V

.DESCRIPTION
    This script provides convenient PowerShell functions for common cluster operations.

    To use: . .\Helpers.ps1

    Available functions:
    - Get-ClusterStatus      : Check cluster and node status
    - Get-ClusterPods        : List all pods in all namespaces
    - Start-Cluster          : Start all VMs
    - Stop-Cluster           : Stop all VMs
    - Restart-Cluster        : Restart all VMs
    - Remove-Cluster         : Destroy cluster
    - Invoke-Kubectl         : Run kubectl commands on control plane
    - Get-NodeLogs           : View kubelet logs from a node
    - Get-ClusterInfo        : Display comprehensive cluster information
    - Test-ClusterHealth     : Run health checks on the cluster
#>

function Get-ClusterStatus {
    <#
    .SYNOPSIS
        Check cluster and node status
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n=== Cluster Status ===" -ForegroundColor Cyan
    vagrant status

    Write-Host "`n=== Node Status ===" -ForegroundColor Cyan
    vagrant ssh controlplane -c "kubectl get nodes -o wide"
}

function Get-ClusterPods {
    <#
    .SYNOPSIS
        List all pods in all namespaces
    #>
    [CmdletBinding()]
    param(
        [string]$Namespace = ""
    )

    if ($Namespace) {
        vagrant ssh controlplane -c "kubectl get pods -n $Namespace -o wide"
    } else {
        vagrant ssh controlplane -c "kubectl get pods -A -o wide"
    }
}

function Start-Cluster {
    <#
    .SYNOPSIS
        Start all cluster VMs
    #>
    [CmdletBinding()]
    param()

    Write-Host "Starting Kubernetes cluster..." -ForegroundColor Green
    vagrant up
}

function Stop-Cluster {
    <#
    .SYNOPSIS
        Stop all cluster VMs
    #>
    [CmdletBinding()]
    param()

    Write-Host "Stopping Kubernetes cluster..." -ForegroundColor Yellow
    vagrant halt
}

function Restart-Cluster {
    <#
    .SYNOPSIS
        Restart all cluster VMs
    #>
    [CmdletBinding()]
    param()

    Write-Host "Restarting Kubernetes cluster..." -ForegroundColor Yellow
    vagrant halt
    Start-Sleep -Seconds 5
    vagrant up
}

function Remove-Cluster {
    <#
    .SYNOPSIS
        Destroy the cluster (with confirmation)
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    if (-not $Force) {
        $confirmation = Read-Host "Are you sure you want to destroy the cluster? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return
        }
    }

    Write-Host "Destroying Kubernetes cluster..." -ForegroundColor Red
    vagrant destroy -f

    if (Test-Path "join-command.sh") {
        Remove-Item "join-command.sh" -Force
    }

    Write-Host "Cluster destroyed successfully." -ForegroundColor Green
}

function Invoke-Kubectl {
    <#
    .SYNOPSIS
        Run kubectl commands on control plane
    .EXAMPLE
        Invoke-Kubectl "get nodes"
        Invoke-Kubectl "get pods -A"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command
    )

    vagrant ssh controlplane -c "kubectl $Command"
}

function Get-NodeLogs {
    <#
    .SYNOPSIS
        View kubelet logs from a node
    .EXAMPLE
        Get-NodeLogs -Node controlplane
        Get-NodeLogs -Node worker1 -Lines 50
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("controlplane", "worker1", "worker2")]
        [string]$Node,

        [int]$Lines = 100
    )

    vagrant ssh $Node -c "sudo journalctl -u kubelet -n $Lines --no-pager"
}

function Get-ClusterInfo {
    <#
    .SYNOPSIS
        Display comprehensive cluster information
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Kubernetes Cluster Information" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "VM Status:" -ForegroundColor Yellow
    vagrant status

    Write-Host "`nNode Information:" -ForegroundColor Yellow
    vagrant ssh controlplane -c "kubectl get nodes -o wide"

    Write-Host "`nKubernetes Version:" -ForegroundColor Yellow
    vagrant ssh controlplane -c "kubectl version --short 2>/dev/null || kubectl version"

    Write-Host "`nCluster Info:" -ForegroundColor Yellow
    vagrant ssh controlplane -c "kubectl cluster-info"

    Write-Host "`nNamespaces:" -ForegroundColor Yellow
    vagrant ssh controlplane -c "kubectl get namespaces"

    Write-Host "`nSystem Pods:" -ForegroundColor Yellow
    vagrant ssh controlplane -c "kubectl get pods -n kube-system"

    Write-Host "`nResource Usage:" -ForegroundColor Yellow
    Get-VM | Where-Object {$_.Name -like "k8s-*"} | Select-Object Name, State, CPUUsage, MemoryAssigned, Uptime
}

function Test-ClusterHealth {
    <#
    .SYNOPSIS
        Run health checks on the cluster
    #>
    [CmdletBinding()]
    param()

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Cluster Health Check" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    $allHealthy = $true

    # Check VMs are running
    Write-Host "Checking VMs..." -ForegroundColor Yellow
    $vms = Get-VM | Where-Object {$_.Name -like "k8s-*"}
    foreach ($vm in $vms) {
        if ($vm.State -eq "Running") {
            Write-Host "  [OK] $($vm.Name) is running" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $($vm.Name) is $($vm.State)" -ForegroundColor Red
            $allHealthy = $false
        }
    }

    # Check nodes are ready
    Write-Host "`nChecking Nodes..." -ForegroundColor Yellow
    $nodeStatus = vagrant ssh controlplane -c "kubectl get nodes --no-headers" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $nodeStatus -split "`n" | ForEach-Object {
            if ($_ -match "Ready") {
                Write-Host "  [OK] $_" -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] $_" -ForegroundColor Red
                $allHealthy = $false
            }
        }
    } else {
        Write-Host "  [FAIL] Could not connect to control plane" -ForegroundColor Red
        $allHealthy = $false
    }

    # Check system pods
    Write-Host "`nChecking System Pods..." -ForegroundColor Yellow
    $podStatus = vagrant ssh controlplane -c "kubectl get pods -n kube-system --no-headers" 2>&1
    if ($LASTEXITCODE -eq 0) {
        $runningPods = ($podStatus -split "`n" | Where-Object { $_ -match "Running" }).Count
        $totalPods = ($podStatus -split "`n" | Where-Object { $_.Trim() -ne "" }).Count

        if ($runningPods -eq $totalPods) {
            Write-Host "  [OK] All system pods running ($runningPods/$totalPods)" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] Some pods not running ($runningPods/$totalPods)" -ForegroundColor Yellow
            $allHealthy = $false
        }
    }

    # Check component health
    Write-Host "`nChecking Component Health..." -ForegroundColor Yellow
    $componentStatus = vagrant ssh controlplane -c "kubectl get --raw='/readyz?verbose'" 2>&1
    if ($LASTEXITCODE -eq 0 -and $componentStatus -match "ok") {
        Write-Host "  [OK] All components healthy" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Some components may have issues" -ForegroundColor Yellow
    }

    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    if ($allHealthy) {
        Write-Host "Cluster Status: HEALTHY" -ForegroundColor Green
    } else {
        Write-Host "Cluster Status: ISSUES DETECTED" -ForegroundColor Red
    }
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Get-KubeConfig {
    <#
    .SYNOPSIS
        Copy kubeconfig from cluster to local machine
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath = "$HOME\.kube\k8s-vagrant-config"
    )

    $kubePath = Split-Path -Parent $OutputPath
    if (-not (Test-Path $kubePath)) {
        New-Item -ItemType Directory -Force -Path $kubePath | Out-Null
    }

    Write-Host "Copying kubeconfig to $OutputPath..." -ForegroundColor Yellow
    vagrant ssh controlplane -c "cat ~/.kube/config" | Out-File -Encoding utf8 $OutputPath

    Write-Host "Kubeconfig saved!" -ForegroundColor Green
    Write-Host "`nTo use kubectl locally:" -ForegroundColor Cyan
    Write-Host '  $env:KUBECONFIG="' + $OutputPath + '"' -ForegroundColor White
    Write-Host "  kubectl get nodes" -ForegroundColor White
}

# Display available functions when sourced
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Kubernetes Helper Functions Loaded" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Available functions:" -ForegroundColor Yellow
Write-Host "  Get-ClusterStatus    - Check cluster and node status"
Write-Host "  Get-ClusterPods      - List all pods"
Write-Host "  Start-Cluster        - Start all VMs"
Write-Host "  Stop-Cluster         - Stop all VMs"
Write-Host "  Restart-Cluster      - Restart all VMs"
Write-Host "  Remove-Cluster       - Destroy cluster"
Write-Host "  Invoke-Kubectl       - Run kubectl commands"
Write-Host "  Get-NodeLogs         - View kubelet logs"
Write-Host "  Get-ClusterInfo      - Display cluster information"
Write-Host "  Test-ClusterHealth   - Run health checks"
Write-Host "  Get-KubeConfig       - Copy kubeconfig locally"
Write-Host "`nExamples:" -ForegroundColor Yellow
Write-Host '  Get-ClusterStatus'
Write-Host '  Invoke-Kubectl "get pods -A"'
Write-Host '  Get-NodeLogs -Node worker1 -Lines 50'
Write-Host '  Test-ClusterHealth'
Write-Host ""
