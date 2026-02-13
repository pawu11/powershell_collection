# Veeam & PostgreSQL Komplett-Deinstallation
# Als Administrator ausführen!

# Farben für bessere Lesbarkeit
$Host.UI.RawUI.ForegroundColor = "Green"
Write-Host "=== Veeam & PostgreSQL Komplett-Deinstallation ===" -ForegroundColor Cyan
Write-Host "Dieses Skript entfernt VEEAM und POSTGRESQL vollständig!" -ForegroundColor Red
Write-Host "Backup-Dateien bleiben erhalten, Konfiguration wird gelöscht.`n" -ForegroundColor Yellow

# Sicherheitsabfrage
$confirmation = Read-Host "Wirklich fortfahren? (ja/nein)"
if ($confirmation -ne "ja") {
    Write-Host "Abbruch durch Benutzer" -ForegroundColor Red
    exit
}

# 1. Backup der Registry erstellen
Write-Host "`n[1/9] Erstelle Registry-Backup..." -ForegroundColor Cyan
$backupPath = "$env:USERPROFILE\Desktop\Veeam_Uninstall_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
reg export "HKLM\SOFTWARE\Veeam" "$backupPath\Veeam_HKLM.reg" /y 2>$null
reg export "HKLM\SOFTWARE\WOW6432Node\Veeam" "$backupPath\Veeam_HKLM_WOW.reg" /y 2>$null
reg export "HKLM\SOFTWARE\PostgreSQL" "$backupPath\PostgreSQL_HKLM.reg" /y 2>$null
Write-Host "Backup erstellt in: $backupPath" -ForegroundColor Green

# 2. Veeam-Dienste stoppen
Write-Host "`n[2/9] Stoppe Veeam-Dienste..." -ForegroundColor Cyan
$veeamServices = @(
    "VeeamBackupSvc",
    "VeeamCatalogSvc",
    "VeeamBrokerSvc",
    "VeeamCloudSvc",
    "VeeamEnterpriseManagerSvc",
    "VeeamMountSvc",
    "VeeamNFSSvc",
    "VeeamRESTSvc",
    "VeeamSmbSvc",
    "VeeamTransportSvc"
)

foreach ($service in $veeamServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "Stoppe $service..." -NoNewline
        Stop-Service $service -Force -ErrorAction SilentlyContinue
        Write-Host " OK" -ForegroundColor Green
    }
}

# 3. PostgreSQL-Dienste stoppen
Write-Host "`n[3/9] Stoppe PostgreSQL-Dienste..." -ForegroundColor Cyan
$pgServices = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
foreach ($service in $pgServices) {
    Write-Host "Stoppe $($service.Name)..." -NoNewline
    Stop-Service $service -Force -ErrorAction SilentlyContinue
    Write-Host " OK" -ForegroundColor Green
}

# 4. Deinstallation über Windows Installer
Write-Host "`n[4/9] Deinstalliere Veeam über Windows Installer..." -ForegroundColor Cyan

# Veeam Produkte finden und deinstallieren
$veeamProducts = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*Veeam*"}
foreach ($product in $veeamProducts) {
    Write-Host "Deinstalliere: $($product.Name)" -NoNewline
    try {
        $product.Uninstall() | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " FEHLER: $_" -ForegroundColor Red
    }
}

# PostgreSQL finden und deinstallieren
$pgProducts = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like "*PostgreSQL*"}
foreach ($product in $pgProducts) {
    Write-Host "Deinstalliere: $($product.Name)" -NoNewline
    try {
        $product.Uninstall() | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " FEHLER: $_" -ForegroundColor Red
    }
}

# 5. Ordner löschen
Write-Host "`n[5/9] Lösche Veeam-Ordner..." -ForegroundColor Cyan
$foldersToDelete = @(
    "$env:ProgramFiles\Veeam",
    "${env:ProgramFiles(x86)}\Veeam",
    "$env:ProgramData\Veeam",
    "$env:LOCALAPPDATA\Veeam",
    "$env:APPDATA\Veeam",
    "$env:ALLUSERSPROFILE\Veeam",
    "C:\Program Files\PostgreSQL",
    "$env:ProgramData\PostgreSQL"
)

foreach ($folder in $foldersToDelete) {
    if (Test-Path $folder) {
        Write-Host "Lösche: $folder" -NoNewline
        try {
            Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " OK" -ForegroundColor Green
        }
        catch {
            Write-Host " FEHLER: $_" -ForegroundColor Red
        }
    }
}

# 6. Temporäre Dateien löschen
Write-Host "`n[6/9] Lösche temporäre Dateien..." -ForegroundColor Cyan
$tempPaths = @(
    "$env:TEMP\*.vib",
    "$env:TEMP\Veeam*",
    "$env:TEMP\PostgreSQL*"
)

foreach ($pattern in $tempPaths) {
    Remove-Item -Path $pattern -Force -ErrorAction SilentlyContinue
}
Write-Host "Temporäre Dateien gelöscht" -ForegroundColor Green

# 7. Registry-Einträge löschen
Write-Host "`n[7/9] Lösche Registry-Einträge..." -ForegroundColor Cyan
$registryPaths = @(
    "HKLM:\SOFTWARE\Veeam",
    "HKLM:\SOFTWARE\WOW6432Node\Veeam",
    "HKCU:\SOFTWARE\Veeam",
    "HKLM:\SOFTWARE\PostgreSQL",
    "HKLM:\SOFTWARE\WOW6432Node\PostgreSQL"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        Write-Host "Lösche: $regPath" -NoNewline
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " OK" -ForegroundColor Green
        }
        catch {
            Write-Host " FEHLER: $_" -ForegroundColor Red
        }
    }
}

# 8. Dienst-Registrierungen löschen
Write-Host "`n[8/9] Entferne Dienst-Registrierungen..." -ForegroundColor Cyan
$serviceRegPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\Veeam*",
    "HKLM:\SYSTEM\CurrentControlSet\Services\postgresql*"
)

foreach ($pattern in $serviceRegPaths) {
    $services = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services" | Where-Object {$_.PSChildName -like $pattern}
    foreach ($service in $services) {
        Write-Host "Lösche Dienst: $($service.PSChildName)" -NoNewline
        try {
            Remove-Item -Path $service.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host " OK" -ForegroundColor Green
        }
        catch {
            Write-Host " FEHLER: $_" -ForegroundColor Red
        }
    }
}

# 9. Zusammenfassung
Write-Host "`n[9/9] Bereinigung abgeschlossen!" -ForegroundColor Cyan
Write-Host "`n=== ZUSAMMENFASSUNG ===" -ForegroundColor Yellow
Write-Host "✓ Registry-Backup: $backupPath" -ForegroundColor Green
Write-Host "✓ Veeam deinstalliert" -ForegroundColor Green
Write-Host "✓ PostgreSQL deinstalliert" -ForegroundColor Green
Write-Host "✓ Ordner gelöscht" -ForegroundColor Green
Write-Host "✓ Registry bereinigt" -ForegroundColor Green

Write-Host "`nEmpfohlene nächste Schritte:" -ForegroundColor Cyan
Write-Host "1. Computer NEU STARTEN" -ForegroundColor Yellow
Write-Host "2. Nach Neustart: Veeam frisch installieren" -ForegroundColor Yellow
Write-Host "3. Bei Installation 'Neue Datenbank installieren' wählen" -ForegroundColor Yellow

# Nachfrage für Neustart
$restart = Read-Host "`nJetzt neu starten? (ja/nein)"
if ($restart -eq "ja") {
    Restart-Computer -Force
}
