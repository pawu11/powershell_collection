# Zusätzliche Bereinigung für hartnäckige Reste
Write-Host "Zusätzliche Tiefenreinung..." -ForegroundColor Cyan

# Nach Veeam in der Registry suchen
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
    Where-Object {$_.GetValue("DisplayName") -like "*Veeam*"} | 
    ForEach-Object {
        Write-Host "Gefunden: $($_.GetValue("DisplayName"))"
        $uninstallString = $_.GetValue("UninstallString")
        if ($uninstallString) {
            cmd /c $uninstallString /quiet /norestart
        }
    }
