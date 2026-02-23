# --- Paths ---
$ExportDir = "$PWD\Exports"
$CloneBaseDir = "$PWD\Clone"

# 1. แสดงรายการโฟลเดอร์ที่เคย Export ไว้
Write-Host "--- Available Exported VMs ---" -ForegroundColor Magenta
if (Test-Path $ExportDir) { (Get-ChildItem -Path $ExportDir -Directory).Name }

# 2. ถามข้อมูล
$ExportFolderName = Read-Host "Enter the Export folder name to clone from"
$BaseName = Read-Host "Enter Base Name for new VM (e.g., WIN-SERVER)"
$CloneCountStr = Read-Host "Enter number of VMs to clone (e.g., 3)"

if ([string]::IsNullOrWhiteSpace($ExportFolderName) -or [string]::IsNullOrWhiteSpace($BaseName) -or [string]::IsNullOrWhiteSpace($CloneCountStr)) { exit }
$CloneCount = [int]$CloneCountStr

# ค้นหาไฟล์ .vmcx
$VmcxPath = Get-ChildItem -Path "$ExportDir\$ExportFolderName" -Filter "*.vmcx" -Recurse | Select-Object -ExpandProperty FullName -First 1

if (!$VmcxPath) {
    Write-Host "Error: Cannot find .vmcx file in $ExportDir\$ExportFolderName" -ForegroundColor Red
    exit
}

# 3. เริ่ม Loop ตามจำนวนเครื่องที่ระบุ
for ($count = 1; $count -le $CloneCount; $count++) {
    
    # ระบบ Auto-Increment ตรวจสอบเลข 01, 02...
    $i = 1
    do {
        $Suffix = $i.ToString("00")
        $NewVMName = "$BaseName-$Suffix"
        $ExistingVM = Get-VM -Name $NewVMName -ErrorAction SilentlyContinue
        $i++
    } while ($ExistingVM)

    $TargetDir = Join-Path $CloneBaseDir $NewVMName

    Write-Host "--- [ $count / $CloneCount ] ---" -ForegroundColor Magenta
    Write-Host "New VM: $NewVMName" -ForegroundColor Cyan
    
    # 4. สร้างโฟลเดอร์และเริ่ม Clone
    New-Item -Path "$TargetDir\Virtual Hard Disks" -ItemType Directory -Force | Out-Null

    Import-VM -Path $VmcxPath `
        -Copy -GenerateNewId `
        -VhdDestinationPath "$TargetDir\Virtual Hard Disks" `
        -VirtualMachinePath "$TargetDir" | Out-Null

    # 5. เปลี่ยนชื่อ VM ในระบบ
    $ImportedVM = Get-VM | Where-Object { $_.ConfigurationLocation -like "$TargetDir*" }
    if ($ImportedVM) {
        Rename-VM -VM $ImportedVM -NewName $NewVMName
        Write-Host "Success! -> $NewVMName" -ForegroundColor Green
    }
}

Write-Host "Done cloning $CloneCount VMs!" -ForegroundColor Green