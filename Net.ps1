# Function to get Public IP
function Get-PublicIP {
    Write-Host "`nChecking Public IP... " -NoNewline
    try {
        # Using Invoke-RestMethod with a 2-second timeout
        $publicIp = Invoke-RestMethod -Uri "https://ifconfig.me" -TimeoutSec 2
        Write-Host ($publicIp -trim)
    }
    catch {
        Write-Host "Offline/Timed Out" -ForegroundColor Red
    }
}

# Function to get IP addresses for all network interfaces
function Get-IPAddresses {
    Write-Host "`n### Local Interfaces and Addresses ###"

    # Get all active, non-loopback interfaces
    $interfaces = Get-NetIPAddress | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
                  Group-Object InterfaceAlias

    # Create a custom table for clean output
    $results = foreach ($iface in $interfaces) {
        [PSCustomObject]@{
            Interface = $iface.Name
            IPv4      = ($iface.Group | Where-Object AddressFamily -eq 'IPv4').IPAddress -join ', '
            IPv6      = ($iface.Group | Where-Object AddressFamily -eq 'IPv6').IPAddress -join ', '
        }
    }

    $results | Format-Table -AutoSize
}

# Function to get listening ports with Process Names
function Get-ListeningPorts {
    Write-Host "`n### Listening Ports & Services ###"

    # Get-NetTCPConnection is the equivalent of 'ss' or 'netstat'
    # We join it with Get-Process to get the name, similar to 'sudo ss -p'
    Get-NetTCPConnection -State Listen | Select-Object `
        LocalAddress,
        LocalPort,
        @{Name="ProcessName"; Expression={(Get-Process -Id $_.OwningProcess).Name}} |
        Sort-Object LocalPort |
        Format-Table -AutoSize
}

# Main execution
Write-Host "=== Network Diagnostic Summary ===" -ForegroundColor Cyan
Get-IPAddresses
Get-PublicIP
Get-ListeningPorts
Write-Host "`n==================================" -ForegroundColor Cyan
