# 1. Automatic Elevation (Self-Elevate)
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating to Administrator for packet capture..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$CAPTURE_DIR = "C:\Logs\Captures"
if (-not (Test-Path $CAPTURE_DIR)) { New-Item -ItemType Directory -Path $CAPTURE_DIR | Out-Null }

function Get-Interfaces {
    Write-Host "`n### Available Interfaces ###" -ForegroundColor Cyan
    Get-NetAdapter | Select-Object InterfaceIndex, Name, Status, LinkSpeed | Format-Table -AutoSize
}

function Start-Capture {
    Get-Interfaces
    $ifaceIndex = Read-Host "Select Interface Index (Enter to cancel)"
    if ([string]::IsNullOrWhiteSpace($ifaceIndex)) { return }

    $filter = Read-Host "Filter (e.g. 'IPv4.Address == 1.1.1.1' or blank)"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $filePath = Join-Path $CAPTURE_DIR "cap_$($timestamp).etl"

    Write-Host "`nStarting capture... (Saving to $filePath)" -ForegroundColor Green

    # Initialize the capture session
    New-NetEventSession -Name "PSScriptCap" -LocalFilePath $filePath -MaxFileSize 256
    Add-NetEventPacketCaptureProvider -SessionName "PSScriptCap"

    Start-NetEventSession -Name "PSScriptCap"

    Write-Host ">>> Press ENTER to STOP CAPTURE <<<" -ForegroundColor Yellow
    Read-Host

    Stop-NetEventSession -Name "PSScriptCap"
    Remove-NetEventSession -Name "PSScriptCap"

    $size = (Get-Item $filePath).Length
    Write-Host "Capture saved. ($size bytes)" -ForegroundColor Green
    Write-Host "Note: Windows saves as .ETL. Use 'Microsoft Message Analyzer' or 'etl2pcapng' to convert to Wireshark format."
}

function Analyze-Captures {
    $files = Get-ChildItem -Path $CAPTURE_DIR -Filter *.etl
    if ($files.Count -eq 0) {
        Write-Host "No capture files found in $CAPTURE_DIR" -ForegroundColor Red
        return
    }

    $files | ForEach-Object { [PSCustomObject]@{ID = $files.IndexOf($_); Name = $_.Name; Size = $_.Length} } | Format-Table
    $choice = Read-Host "Select ID to analyze"

    if ($choice -match '^\d+$' -and $choice -lt $files.Count) {
        $target = $files[$choice].FullName
        Write-Host "Reading packet metadata for $target..." -ForegroundColor Cyan

        # In Windows, we use Get-WinEvent to parse ETL files
        $events = Get-WinEvent -Path $target -Oldest
        $summary = $events | Group-Object ProviderName | Select-Object Name, Count | Sort-Object Count -Descending

        Write-Host "`n### Protocol/Provider Summary ###" -ForegroundColor Yellow
        $summary | Format-Table -AutoSize
    }
}

# Main Loop
while ($true) {
    Write-Host "`n=== WINDOWS PACKET ADMIN TOOL ===" -ForegroundColor Blue
    Write-Host "1. List Interfaces"
    Write-Host "2. Start Capture"
    Write-Host "3. Analyze Captures"
    Write-Host "4. Exit"
    $choice = Read-Host "Choice"

    switch ($choice) {
        "1" { Get-Interfaces }
        "2" { Start-Capture }
        "3" { Analyze-Captures }
        "4" { break }
        Default { Write-Host "Invalid choice." }
    }
}
