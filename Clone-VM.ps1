# --- Paths ---
$ExportDir = "$PWD\Exports"
$CloneBaseDir = "$PWD\Clone"
$7zPath = "C:\Program Files\7-Zip\7z.exe"

$ProgressPreference = 'Continue'
# 1. แสดงรายการไฟล์ ZIP ที่เคย Export ไว้
Write-Host "--- Available Exported VMs (.zip) ---" -ForegroundColor Magenta
if (Test-Path $ExportDir) { (Get-ChildItem -Path $ExportDir -Filter "*.zip").Name }

# 2. ถามข้อมูล
$ZipFileName = Read-Host "Enter the ZIP file name (e.g., VM-Backup.zip)"
$BaseName = Read-Host "Enter Base Name for new VM (e.g., WIN-SERVER)"
$CloneCountStr = Read-Host "Enter number of VMs to clone (e.g., 3)"

if ([string]::IsNullOrWhiteSpace($ZipFileName) -or [string]::IsNullOrWhiteSpace($BaseName) -or [string]::IsNullOrWhiteSpace($CloneCountStr)) { exit }
$CloneCount = [int]$CloneCountStr

$ZipFilePath = Join-Path $ExportDir $ZipFileName
if (!(Test-Path $ZipFilePath)) {
    Write-Host "Error: Cannot find $ZipFilePath" -ForegroundColor Red
    exit
}

# สร้างโฟลเดอร์ Temp สำหรับแตกไฟล์
$TempDir = Join-Path $ExportDir "Temp_$([guid]::NewGuid().ToString().Substring(0,8))"
Write-Host "Extracting ZIP to temporary folder..." -ForegroundColor Cyan
& $7zPath x "$ZipFilePath" -o"$TempDir" -y -bsp1 -bso0

# ค้นหาไฟล์ .vmcx ในโฟลเดอร์ Temp
$VmcxPath = Get-ChildItem -Path $TempDir -Filter "*.vmcx" -Recurse | Select-Object -ExpandProperty FullName -First 1

if (!$VmcxPath) {
    Write-Host "Error: Cannot find .vmcx file in extracted folder." -ForegroundColor Red
    Remove-Item -Path $TempDir -Recurse -Force
    exit
}

# 3. เริ่ม Loop ตามจำนวนเครื่องที่ระบุ
for ($count = 1; $count -le $CloneCount; $count++) {
    
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
    New-Item -Path "$TargetDir\Virtual Hard Disks" -ItemType Directory -Force

    Import-VM -Path $VmcxPath `
        -Copy -GenerateNewId `
        -VhdDestinationPath "$TargetDir\Virtual Hard Disks" `
        -VirtualMachinePath "$TargetDir"

    # 5. เปลี่ยนชื่อ VM ในระบบ
    $ImportedVM = Get-VM | Where-Object { $_.ConfigurationLocation -like "$TargetDir*" }
    if ($ImportedVM) {
        Rename-VM -VM $ImportedVM -NewName $NewVMName
        Write-Host "Success! -> $NewVMName" -ForegroundColor Green
    }
}

# ลบโฟลเดอร์ Temp ทิ้งหลังทำงานเสร็จ
Remove-Item -Path $TempDir -Recurse -Force
Write-Host "Done cloning $CloneCount VMs!" -ForegroundColor Green