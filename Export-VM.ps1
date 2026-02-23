# --- Set base export path ---
$BaseExportPath = "$PWD\Exports"

# 1. Display all VMs
Write-Host "--- List of Virtual Machines ---" -ForegroundColor Magenta
Get-VM | Select-Object Name, State | Format-Table -AutoSize

# 2. Ask for VM Name in English
$VMName = Read-Host "Please enter the VM Name you want to export"

if ([string]::IsNullOrWhiteSpace($VMName)) { 
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    exit 
}

# 3. Check VM and Prepare Folder Name
$TargetVM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

if ($TargetVM) {
    # Create folder name: VMName-Backup-YYYY-MM-DD (A.D. Format)
    $DateStamp = Get-Date -Format "yyyy-MM-dd"
    $NewFolderName = "${VMName}-Backup-${DateStamp}"
    $FullExportPath = Join-Path $BaseExportPath $NewFolderName

    # Create destination folder
    if (!(Test-Path $FullExportPath)) {
        New-Item -ItemType Directory -Path $FullExportPath -Force | Out-Null
    }

    Write-Host "Exporting VM to: $FullExportPath" -ForegroundColor Cyan

    Get-VMDvdDrive -VMName $VMName | Set-VMDvdDrive -Path $null
    
    # Run Export-VM
    try {
        Export-VM -Name $VMName -Path $FullExportPath
        Write-Host "Export completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred during export: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Error: VM name '$VMName' not found. Please check the name and try again." -ForegroundColor Red
}