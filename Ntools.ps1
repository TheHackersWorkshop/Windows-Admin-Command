# 1. Smarter Admin Elevation
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Admin privileges required. Re-launching..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath` strips`"" -Verb RunAs
    exit
}

# Logging Setup
$LOG_DIR = "C:\NetLogs"
if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR | Out-Null }
$DATE = Get-Date -Format "yyyy-MM-dd_HHmm"
$LOG_FILE = Join-Path $LOG_DIR "nettools_$DATE.log"

# Function to log both to screen and file
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $TimestampedMessage = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $Message -ForegroundColor $Color
    $TimestampedMessage | Out-File -FilePath $LOG_FILE -Append
}

function Show-Menu {
    Clear-Host
    Write-Host "=== Network Tools Dashboard (Windows Edition) ===" -ForegroundColor Cyan
    Write-Host "1) Ping Host          5) Reverse DNS        9) Run DNS-Tool.ps1"
    Write-Host "2) Traceroute         6) Port Scan (TCP)   10) Public IP Info"
    Write-Host "3) Whois Lookup       7) Active Conns      0) Exit"
    Write-Host "4) DNS Lookup         8) Interface IPs"
    Write-Host "--------------------------------------------------------"
    Write-Host "Log: $LOG_FILE" -ForegroundColor Gray
}

# --- Tool Functions ---

function Run-PortScan {
    $target = Read-Host "Target IP/Domain"
    $portsInput = Read-Host "Port Range (e.g., 80,443 or 70..80)"

    # PowerShell trick: 70..80 creates an array of numbers automatically
    $ports = if ($portsInput -match '\.\.') {
        $start, $end = $portsInput -split '\.\.'; $start..$end
    } else {
        $portsInput -split ','
    }

    Write-Log "`n--- Port Scan: $target ($portsInput) ---" "Yellow"
    foreach ($p in $ports) {
        # Test-NetConnection is the 'nc' (netcat) of Windows
        $res = Test-NetConnection -ComputerName $target -Port $p -WarningAction SilentlyContinue
        $status = if ($res.TcpTestSucceeded) { "OPEN" } else { "CLOSED/FILTERED" }
        Write-Log "Port $p : $status" (if ($res.TcpTestSucceeded) { "Green" } else { "Red" })
    }
}

function Run-Whois {
    $domain = Read-Host "Domain"
    Write-Log "`n--- Whois: $domain ---" "Yellow"
    # Windows doesn't have a native whois, so we use a web API to keep it zero-install
    try {
        $info = Invoke-RestMethod "https://rdap.org/domain/$domain"
        $info | ConvertTo-Json -Depth 4 | Out-File -FilePath $LOG_FILE -Append
        Write-Host "Whois data saved to log. (Displayed raw RDAP data)"
        $info.entities | Select-Object handle, roles
    } catch {
        Write-Log "Whois lookup failed for $domain" "Red"
    }
}

# Main Loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Select Option"
    switch ($choice) {
        "1" { $h = Read-Host "Host"; Test-Connection -ComputerName $h -Count 4 | Out-File -FilePath $LOG_FILE -Append; Test-Connection -ComputerName $h -Count 4 }
        "2" { $h = Read-Host "Target"; Write-Log "Tracing $h..."; Test-Connection -ComputerName $h -TraceRoute | Out-File -FilePath $LOG_FILE -Append; Test-Connection -ComputerName $h -TraceRoute }
        "3" { Run-Whois }
        "4" { $d = Read-Host "Domain"; Resolve-DnsName -Name $d | tee -FilePath $LOG_FILE -Append }
        "5" { $ip = Read-Host "IP"; Resolve-DnsName -Name $ip | tee -FilePath $LOG_FILE -Append }
        "6" { Run-PortScan }
        "7" { Get-NetTCPConnection -State Listen | Out-File -FilePath $LOG_FILE -Append; Get-NetTCPConnection -State Listen }
        "8" { Get-NetIPAddress -AddressFamily IPv4 | Select-Object InterfaceAlias, IPAddress | tee -FilePath $LOG_FILE -Append }
        "9" { if (Test-Path "./DNS-Tool.ps1") { & "./DNS-Tool.ps1" } else { Write-Log "DNS-Tool.ps1 not found!" "Red" } }
        "10" { Write-Log "Fetching Geo-IP Info..."; Invoke-RestMethod "https://ipapi.co/json" | tee -FilePath $LOG_FILE -Append }
        "0" { exit }
        Default { Write-Host "Invalid choice." -ForegroundColor Red }
    }
    Read-Host "`nPress [Enter] to continue..."
}

