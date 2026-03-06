# --- Set base export path ---
$BaseExportPath = "$PWD\Exports"
$7zPath = "C:\Program Files\7-Zip\7z.exe"

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
    $DateStamp = Get-Date -Format "yyyy-MM-dd"
    $NewFolderName = "${VMName}-Backup-${DateStamp}"
    $FullExportPath = Join-Path $BaseExportPath $NewFolderName
    $ZipPath = "$FullExportPath.zip"

    if (!(Test-Path $FullExportPath)) {
        New-Item -ItemType Directory -Path $FullExportPath -Force | Out-Null
    }

    Write-Host "Exporting VM to: $FullExportPath" -ForegroundColor Cyan
    Get-VMDvdDrive -VMName $VMName | Set-VMDvdDrive -Path $null
    
    # Run Export-VM and ZIP
    try {
        Export-VM -Name $VMName -Path $FullExportPath
        Write-Host "Zipping files with 7-Zip..." -ForegroundColor Cyan
        & $7zPath a -tzip "$ZipPath" "$FullExportPath\*" -bsp1
        
        # ลบโฟลเดอร์ที่ยังไม่ zip ทิ้งเพื่อประหยัดพื้นที่
        Remove-Item -Path $FullExportPath -Recurse -Force
        Write-Host "Export & ZIP completed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Error: VM name '$VMName' not found." -ForegroundColor Red
}