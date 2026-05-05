# Function to display error and exit
function Write-ErrorExit {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
    exit 1
}

# 1. Path Input with ~ expansion support
$localPath = Read-Host "Local file/folder path (e.g. C:\Files or ~/Documents)"

# PowerShell natively handles ~ as the user's home directory
$localPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($localPath)

if (-not (Test-Path $localPath)) {
    Write-ErrorExit "Path '$localPath' does not exist."
}

# 2. Remote Server Details
$remoteServer = Read-Host "Target Server (IP/Hostname)"
if ([string]::IsNullOrWhiteSpace($remoteServer)) { Write-ErrorExit "Server cannot be empty." }

$sshPort = Read-Host "SSH Port [22]"
if ([string]::IsNullOrWhiteSpace($sshPort)) { $sshPort = 22 }

$remotePath = Read-Host "Remote Destination Path"
if ([string]::IsNullOrWhiteSpace($remotePath)) { Write-ErrorExit "Destination cannot be empty." }

# 3. Connection Validation
Write-Host "Testing connection to $remoteServer on port $sshPort..." -ForegroundColor Cyan
# Test-NetConnection is a quick way to check if the port is even open before trying SSH
$portCheck = Test-NetConnection -ComputerName $remoteServer -Port $sshPort -WarningAction SilentlyContinue
if (-not $portCheck.TcpTestSucceeded) {
    Write-ErrorExit "Port $sshPort is closed on $remoteServer. Check firewall/SSH service."
}

# 4. Transfer Execution
Write-Host "Starting transfer..." -ForegroundColor Yellow

# Check if it's a directory
$isFolder = (Get-Item $localPath) -is [System.IO.DirectoryInfo]

# Windows doesn't have 'rsync' natively, so we use 'scp'
# Note: Windows scp uses uppercase -P for port, just like Linux
$scpArgs = @()
if ($isFolder) { $scpArgs += "-r" }
$scpArgs += "-P", $sshPort
$scpArgs += $localPath
$scpArgs += "${remoteServer}:${remotePath}"

# Execute SCP
& scp @scpArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✔ Transfer completed successfully." -ForegroundColor Green
} else {
    Write-ErrorExit "Transfer failed with exit code $LASTEXITCODE."
}

