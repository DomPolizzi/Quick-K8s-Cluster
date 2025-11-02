#Requires -Version 5.1

<#
.SYNOPSIS
    Quick status check for Kubernetes cluster

.DESCRIPTION
    Checks the status of VMs and cluster health
#>

[CmdletBinding()]
param()

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

Write-ColorOutput "`n=== Vagrant VM Status ===" -ForegroundColor Cyan
vagrant status

Write-ColorOutput "`n=== Hyper-V VM Status ===" -ForegroundColor Cyan
Get-VM | Where-Object {$_.Name -like "k8s-*"} | Format-Table Name, State, CPUUsage, MemoryAssigned, Uptime -AutoSize

Write-ColorOutput "`n=== Attempting to Check Kubernetes Cluster ===" -ForegroundColor Cyan
$nodeCheck = vagrant ssh controlplane -c "kubectl get nodes 2>/dev/null" 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-ColorOutput "[OK] Cluster is accessible:" -ForegroundColor Green
    Write-Output $nodeCheck

    Write-ColorOutput "`n=== System Pods ===" -ForegroundColor Cyan
    vagrant ssh controlplane -c "kubectl get pods -n kube-system"
} else {
    Write-ColorOutput "[INFO] Cluster not yet initialized or not accessible" -ForegroundColor Yellow
    Write-Output "This is normal if deployment hasn't completed yet."
    Write-Output "`nTo continue deployment:"
    Write-Output "  vagrant provision controlplane"
    Write-Output "  vagrant up worker1 worker2"
}

Write-Output ""
