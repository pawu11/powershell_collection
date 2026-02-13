# PowerShell System Diagnostic und Repair Tool für Windows 11
# Als Administrator ausführen!

# Farbige Ausgabe Funktionen
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Clear-Host
Write-ColorOutput Green "=================================================="
Write-ColorOutput Green "    Windows 11 Diagnostic und Repair Tool"
Write-ColorOutput Green "=================================================="
Write-Output ""

# Prüfen ob Skript als Administrator ausgeführt wird
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-ColorOutput Red "WARNUNG: Dieses Skript wird nicht als Administrator ausgeführt!"
    Write-ColorOutput Red "Einige Funktionen werden nicht verfügbar sein."
    Write-ColorOutput Yellow "Bitte als Administrator neu starten für volle Funktionalität."
    Write-Output ""
}

# Systeminformationen sammeln
Write-ColorOutput Cyan "=== Systeminformationen werden gesammelt ==="
Write-Output ""

# PC Name und Domain
$computerInfo = Get-ComputerInfo
$pcName = $computerInfo.CsName
$domain = $computerInfo.CsDomain
$domainJoined = if ($computerInfo.CsPartOfDomain) { "Ja" } else { "Nein" }

Write-ColorOutput Yellow "PC Name: $pcName"
Write-ColorOutput Yellow "Domain Mitglied: $domainJoined"
if ($domainJoined -eq "Ja") { Write-ColorOutput Yellow "Domain: $domain" }

# Netzwerkinformationen
$networkAdapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
foreach ($adapter in $networkAdapters) {
    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex
    $ipAddress = ($ipConfig.IPv4Address | Select-Object -First 1).IPAddress
    $gateway = ($ipConfig.IPv4DefaultGateway | Select-Object -First 1).NextHop
    $dnsServers = ($ipConfig.DNSServer | Where-Object {$_.AddressFamily -eq 2}).ServerAddresses -join ", "
    $dhcpEnabled = if ($ipConfig.DHCP) { "Ja" } else { "Nein" }
    
    Write-ColorOutput Yellow "Adapter: $($adapter.Name)"
    Write-ColorOutput Yellow "  IP Adresse: $ipAddress"
    Write-ColorOutput Yellow "  DHCP: $dhcpEnabled"
    Write-ColorOutput Yellow "  DNS Server: $dnsServers"
    Write-ColorOutput Yellow "  Gateway: $gateway"
}

# Systemauslastung
$cpu = Get-Counter '\Processor(_Total)\% Processor Time'
$cpuLast = [math]::Round($cpu.CounterSamples.CookedValue, 2)
$ram = Get-Counter '\Memory\Available MBytes'
$ramAvailable = [math]::Round($ram.CounterSamples.CookedValue / 1024, 2)
$totalRam = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$ramUsage = [math]::Round((($totalRam - $ramAvailable) / $totalRam) * 100, 2)

Write-ColorOutput Yellow "CPU Auslastung: $cpuLast%"
Write-ColorOutput Yellow "RAM Auslastung: $ramUsage% (Verfügbar: $ramAvailable GB von $totalRam GB)"

# Festplatteninformationen
$disks = Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Name -eq "C"}
foreach ($disk in $disks) {
    $freeSpace = [math]::Round($disk.Free / 1GB, 2)
    $usedSpace = [math]::Round(($disk.Used / 1GB), 2)
    $totalSpace = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $percentFree = [math]::Round(($freeSpace / $totalSpace) * 100, 2)
    
    Write-ColorOutput Yellow "Laufwerk C:"
    Write-ColorOutput Yellow "  Gesamt: $totalSpace GB"
    Write-ColorOutput Yellow "  Belegt: $usedSpace GB"
    Write-ColorOutput Yellow "  Frei: $freeSpace GB ($percentFree% frei)"
}

# Sicherheitssoftware
$antivirus = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntivirusProduct 2>$null
if ($antivirus) {
    $avStatus = @()
    foreach ($av in $antivirus) {
        $status = switch ($av.productState) {
            {$_ -band 0x1000} { "Aktiv" }
            {$_ -band 0x2000} { "Deaktiviert" }
            default { "Unbekannt" }
        }
        $avStatus += "$($av.displayName) ($status)"
    }
    Write-ColorOutput Yellow "Virenscanner: $($avStatus -join ', ')"
} else {
    Write-ColorOutput Red "Virenscanner: Keine Informationen verfügbar"
}

# Firewall Status
$firewall = Get-NetFirewallProfile -All
$firewallStatus = @()
foreach ($profile in $firewall) {
    $status = if ($profile.Enabled) { "Aktiv" } else { "Inaktiv" }
    $firewallStatus += "$($profile.Name): $status"
}
Write-ColorOutput Yellow "Firewall: $($firewallStatus -join ', ')"

# Netzwerktests
Write-Output ""
Write-ColorOutput Cyan "=== Netzwerktests werden durchgeführt ==="

# Ping Gateway
if ($gateway) {
    $pingGateway = Test-Connection -ComputerName $gateway -Count 2 -Quiet
    $gatewayResult = if ($pingGateway) { "Erfolgreich" } else { "Fehlgeschlagen" }
    $gatewayColor = if ($pingGateway) { "Green" } else { "Red" }
    Write-ColorOutput $gatewayColor "Ping Gateway ($gateway): $gatewayResult"
}

# Ping Google DNS
$pingGoogleDns = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
$googleDnsResult = if ($pingGoogleDns) { "Erfolgreich" } else { "Fehlgeschlagen" }
$googleDnsColor = if ($pingGoogleDns) { "Green" } else { "Red" }
Write-ColorOutput $googleDnsColor "Ping 8.8.8.8: $googleDnsResult"

# Ping Google.de
$pingGoogleDe = Test-Connection -ComputerName "www.google.de" -Count 2 -Quiet
$googleDeResult = if ($pingGoogleDe) { "Erfolgreich" } else { "Fehlgeschlagen" }
$googleDeColor = if ($pingGoogleDe) { "Green" } else { "Red" }
Write-ColorOutput $googleDeColor "Ping www.google.de: $googleDeResult"

# Letzter Reboot
$lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptime = (Get-Date) - $lastBoot
$uptimeDays = [math]::Round($uptime.TotalDays, 1)
Write-ColorOutput Yellow "Letzter Reboot: $lastBoot (vor $uptimeDays Tagen)"

# Reparatur-Optionen
Write-Output ""
Write-ColorOutput Cyan "=== Reparatur-Optionen ==="
Write-Output ""

function Show-Menu {
    Write-ColorOutput Yellow "Welche Tests/Reparaturen möchten Sie durchführen?"
    Write-Output "1. SFC /Scannow (Systemdateien prüfen)"
    Write-Output "2. DISM RestoreHealth (Windows Image reparieren)"
    Write-Output "3. CHKDSK C: (Festplattenprüfung - benötigt Neustart)"
    Write-Output "4. IP-Konfiguration zurücksetzen (netsh)"
    Write-Output "5. Windows Update manuell suchen"
    Write-Output "6. Systemwiederherstellungspunkt erstellen"
    Write-Output "7. Alle ausgewählten Tests durchführen"
    Write-Output "8. Beenden"
    Write-Output ""
}

$selectedOptions = @()

do {
    Show-Menu
    $choice = Read-Host "Bitte wählen Sie eine Option (1-8)"
    
    switch ($choice) {
        "1" { 
            $selectedOptions += "SFC"
            Write-ColorOutput Green "SFC /Scannow wurde zur Warteschlange hinzugefügt"
        }
        "2" { 
            $selectedOptions += "DISM"
            Write-ColorOutput Green "DISM RestoreHealth wurde zur Warteschlange hinzugefügt"
        }
        "3" { 
            $selectedOptions += "CHKDSK"
            Write-ColorOutput Green "CHKDSK wurde zur Warteschlange hinzugefügt (wird nach Neustart ausgeführt)"
        }
        "4" { 
            $selectedOptions += "NETSH"
            Write-ColorOutput Green "IP-Reset wurde zur Warteschlange hinzugefügt"
        }
        "5" { 
            $selectedOptions += "UPDATE"
            Write-ColorOutput Green "Windows Update Suche wurde zur Warteschlange hinzugefügt"
        }
        "6" { 
            $selectedOptions += "RESTORE"
            Write-ColorOutput Green "Systemwiederherstellungspunkt wurde zur Warteschlange hinzugefügt"
        }
        "7" { 
            $selectedOptions = @("SFC","DISM","CHKDSK","NETSH","UPDATE","RESTORE")
            Write-ColorOutput Green "Alle Tests wurden zur Warteschlange hinzugefügt"
            break
        }
        "8" { 
            Write-ColorOutput Yellow "Programm wird beendet..."
            exit
        }
        default { Write-ColorOutput Red "Ungültige Auswahl!" }
    }
    
    if ($choice -ne "8" -and $choice -ne "7") {
        $continue = Read-Host "Weitere Option hinzufügen? (j/n)"
        if ($continue -ne "j") { break }
    }
} while ($choice -ne "7")

# Ausführung der ausgewählten Optionen
Write-Output ""
Write-ColorOutput Cyan "=== Ausführung der ausgewählten Reparaturen ==="
Write-Output ""

foreach ($option in $selectedOptions | Select-Object -Unique) {
    switch ($option) {
        "SFC" {
            Write-ColorOutput Yellow "Führe SFC /Scannow aus..."
            sfc /scannow
            Write-Output ""
        }
        "DISM" {
            Write-ColorOutput Yellow "Führe DISM RestoreHealth aus..."
            if ($isAdmin) {
                DISM /Online /Cleanup-Image /RestoreHealth
            } else {
                Write-ColorOutput Red "DISM benötigt Administratorrechte! Überspringe..."
            }
            Write-Output ""
        }
        "CHKDSK" {
            Write-ColorOutput Yellow "CHKDSK wird für den nächsten Neustart geplant..."
            if ($isAdmin) {
                chkdsk C: /f /r
                Write-ColorOutput Yellow "CHKDSK wird beim nächsten Systemneustart ausgeführt."
            } else {
                Write-ColorOutput Red "CHKDSK benötigt Administratorrechte! Überspringe..."
            }
            Write-Output ""
        }
        "NETSH" {
            Write-ColorOutput Yellow "Setze IP-Konfiguration zurück..."
            if ($isAdmin) {
                netsh int ip reset
                netsh winsock reset
                ipconfig /release
                ipconfig /renew
                ipconfig /flushdns
                Write-ColorOutput Green "Netzwerkkonfiguration wurde zurückgesetzt."
            } else {
                Write-ColorOutput Red "NETSH benötigt Administratorrechte! Überspringe..."
            }
            Write-Output ""
        }
        "UPDATE" {
            Write-ColorOutput Yellow "Öffne Windows Update Einstellungen..."
            Start-Process ms-settings:windowsupdate
            Write-Output ""
        }
        "RESTORE" {
            Write-ColorOutput Yellow "Erstelle Systemwiederherstellungspunkt..."
            if ($isAdmin) {
                Checkpoint-Computer -Description "Vor Windows Reparatur" -RestorePointType MODIFY_SETTINGS
                Write-ColorOutput Green "Wiederherstellungspunkt wurde erstellt."
            } else {
                Write-ColorOutput Red "Wiederherstellungspunkt benötigt Administratorrechte! Überspringe..."
            }
            Write-Output ""
        }
    }
}

# Abschluss
Write-Output ""
Write-ColorOutput Green "=================================================="
Write-ColorOutput Green "    Diagnose und Reparatur abgeschlossen!"
Write-ColorOutput Green "=================================================="

# Empfehlungen basierend auf Ergebnissen
Write-Output ""
Write-ColorOutput Cyan "=== Empfehlungen ==="

if ($percentFree -lt 10) {
    Write-ColorOutput Red "WARNUNG: Wenig Speicherplatz auf C:! Bitte bereinigen."
}

if ($uptime.TotalDays -gt 30) {
    Write-ColorOutput Yellow "Empfehlung: System neustarten (letzter Reboot vor $uptimeDays Tagen)"
}

if (-not $pingGoogleDns -or -not $pingGoogleDe) {
    Write-ColorOutput Red "Internetverbindungsprobleme erkannt! Bitte Netzwerk überprüfen."
}

Write-Output ""
Read-Host "Drücken Sie eine beliebige Taste zum Beenden"
