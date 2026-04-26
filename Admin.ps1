#========================================================
# WINDOWS ADMIN COMMAND CENTER - AUDIT GRADE VERSION 1.0
#========================================================
#Requires -Modules ActiveDirectory

$Global:CurrentUser = $null
$Global:CurrentComputer = $null

#--------------------------
# LOGGING SETUP
#--------------------------
$Global:LogPath = Join-Path $env:USERPROFILE "Documents\WinAdminLogs"
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }
$Global:LogFile = Join-Path $Global:LogPath "AdminActions_$(Get-Date -Format yyyyMMdd).log"

function Log-Action {
    param(
        [string]$Action,
        [string]$Status = "INFO"
    )
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Status] $Action"
    $entry | Out-File -FilePath $Global:LogFile -Append
}

#--------------------------
# SAFE GETTERS
#--------------------------
$UserProps = @('Enabled','LockedOut','AccountExpirationDate','LastLogonDate','PasswordLastSet','PasswordNeverExpires','BadLogonCount','EmailAddress','Department','Manager','DistinguishedName','MemberOf')
$CompProps = @('Enabled','OperatingSystem','LastLogonDate','DistinguishedName','IPv4Address')

function Get-ADUserSafe {
    param($u)
    try { Get-ADUser -Identity $u -Properties $UserProps -ErrorAction Stop }
    catch {
        Write-Host "User '$u' not found." -ForegroundColor Red
        Log-Action "FAILED lookup for user '$u'" "ERROR"
        return $null
    }
}

function Get-ADComputerSafe {
    param($c)
    try { Get-ADComputer -Identity $c -Properties $CompProps -ErrorAction Stop }
    catch {
        Write-Host "Computer '$c' not found." -ForegroundColor Red
        Log-Action "FAILED lookup for computer '$c'" "ERROR"
        return $null
    }
}

#--------------------------
# HEADERS
#--------------------------
function Show-UserHeader {
    Write-Host "`n=== USER TARGET INFO ===" -ForegroundColor Cyan
    if ($Global:CurrentUser) {
        $status = if ($Global:CurrentUser.Enabled) { "Enabled" } else { "Disabled" }
        $locked = if ($Global:CurrentUser.LockedOut) { "LOCKED" } else { "Unlocked" }
        Write-Host "User: $($Global:CurrentUser.SamAccountName)"
        Write-Host "OU:   $($Global:CurrentUser.DistinguishedName)"
        Write-Host "Status: $status | Locked: $locked"
    } else { Write-Host "No user selected." -ForegroundColor Yellow }
}

function Show-ComputerHeader {
    Write-Host "`n=== COMPUTER TARGET INFO ===" -ForegroundColor Cyan
    if ($Global:CurrentComputer) {
        $status = if ($Global:CurrentComputer.Enabled) { "Enabled" } else { "Disabled" }
        Write-Host "Computer: $($Global:CurrentComputer.Name)"
        Write-Host "OU:       $($Global:CurrentComputer.DistinguishedName)"
        Write-Host "Status:   $status"
    } else { Write-Host "No computer selected." -ForegroundColor Yellow }
}

#--------------------------
# USER FUNCTIONS
#--------------------------
function Select-User {
    $u = Read-Host "Enter username"
    $user = Get-ADUserSafe $u
    if ($user) {
        $Global:CurrentUser = $user
        Log-Action "Selected user $($user.SamAccountName)"
    }
}

function Clear-User {
    if ($Global:CurrentUser) {
        Log-Action "Cleared user $($Global:CurrentUser.SamAccountName)"
    }
    $Global:CurrentUser = $null
}

function Toggle-User {
    if (-not $Global:CurrentUser) { Write-Host "Select a user first"; return }
    $actionWord = if ($Global:CurrentUser.Enabled) { "Disable" } else { "Enable" }

    if ((Read-Host "Confirm $actionWord user? (Y/N)").ToUpper() -eq "Y") {
        try {
            if ($Global:CurrentUser.Enabled) {
                Disable-ADAccount -Identity $Global:CurrentUser.SamAccountName -ErrorAction Stop
            } else {
                Enable-ADAccount -Identity $Global:CurrentUser.SamAccountName -ErrorAction Stop
            }

            $Global:CurrentUser = Get-ADUserSafe $Global:CurrentUser.SamAccountName
            $result = if ($Global:CurrentUser.Enabled) { "Enabled" } else { "Disabled" }

            Log-Action "$result user $($Global:CurrentUser.SamAccountName)" "SUCCESS"
        }
        catch {
            Log-Action "FAILED to $actionWord user $($Global:CurrentUser.SamAccountName): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Move-User {
    if (-not $Global:CurrentUser) { Write-Host "Select a user first"; return }
    $ou = Read-Host "Enter target OU DistinguishedName"

    try {
        Move-ADObject -Identity $Global:CurrentUser.DistinguishedName -TargetPath $ou -ErrorAction Stop
        Log-Action "Moved user $($Global:CurrentUser.SamAccountName) to $ou" "SUCCESS"
    }
    catch {
        Log-Action "FAILED to move user $($Global:CurrentUser.SamAccountName) to $ou: $($_.Exception.Message)" "ERROR"
    }
}

#--------------------------
# COMPUTER FUNCTIONS
#--------------------------
function Select-Computer {
    $c = Read-Host "Enter computer name"
    $comp = Get-ADComputerSafe $c
    if ($comp) {
        $Global:CurrentComputer = $comp
        Log-Action "Selected computer $($comp.Name)"
    }
}

function Clear-Computer {
    if ($Global:CurrentComputer) {
        Log-Action "Cleared computer $($Global:CurrentComputer.Name)"
    }
    $Global:CurrentComputer = $null
}

function Toggle-Computer {
    if (-not $Global:CurrentComputer) { Write-Host "Select a computer first"; return }
    $actionWord = if ($Global:CurrentComputer.Enabled) { "Disable" } else { "Enable" }

    if ((Read-Host "Confirm $actionWord computer? (Y/N)").ToUpper() -eq "Y") {
        try {
            if ($Global:CurrentComputer.Enabled) {
                Disable-ADAccount -Identity $Global:CurrentComputer.Name -ErrorAction Stop
            } else {
                Enable-ADAccount -Identity $Global:CurrentComputer.Name -ErrorAction Stop
            }

            $Global:CurrentComputer = Get-ADComputerSafe $Global:CurrentComputer.Name
            $result = if ($Global:CurrentComputer.Enabled) { "Enabled" } else { "Disabled" }

            Log-Action "$result computer $($Global:CurrentComputer.Name)" "SUCCESS"
        }
        catch {
            Log-Action "FAILED to $actionWord computer $($Global:CurrentComputer.Name): $($_.Exception.Message)" "ERROR"
        }
    }
}

function Move-Computer {
    if (-not $Global:CurrentComputer) { Write-Host "Select a computer first"; return }
    $ou = Read-Host "Enter target OU DistinguishedName"

    try {
        Move-ADObject -Identity $Global:CurrentComputer.DistinguishedName -TargetPath $ou -ErrorAction Stop
        Log-Action "Moved computer $($Global:CurrentComputer.Name) to $ou" "SUCCESS"
    }
    catch {
        Log-Action "FAILED to move computer $($Global:CurrentComputer.Name) to $ou: $($_.Exception.Message)" "ERROR"
    }
}

function Run-GPUpdate {
    if (-not $Global:CurrentComputer) { Write-Host "Select a computer first"; return }
    try {
        Invoke-Command -ComputerName $Global:CurrentComputer.Name { gpupdate /force } -ErrorAction Stop
        Log-Action "GPUpdate executed on $($Global:CurrentComputer.Name)" "SUCCESS"
    }
    catch {
        Log-Action "FAILED GPUpdate on $($Global:CurrentComputer.Name): $($_.Exception.Message)" "ERROR"
    }
}

function Restart-RemoteComputer {
    if (-not $Global:CurrentComputer) { Write-Host "Select a computer first"; return }

    if ((Read-Host "Confirm restart? (Y/N)").ToUpper() -eq "Y") {
        try {
            Restart-Computer -ComputerName $Global:CurrentComputer.Name -Force -ErrorAction Stop
            Log-Action "Restarted computer $($Global:CurrentComputer.Name)" "SUCCESS"
        }
        catch {
            Log-Action "FAILED restart on $($Global:CurrentComputer.Name): $($_.Exception.Message)" "ERROR"
        }
    }
}

#--------------------------
# MAIN LOOP
#--------------------------
while ($true) {
    Clear-Host
    Write-Host "==== WINDOWS ADMIN COMMAND CENTER ====" -ForegroundColor Cyan
    Write-Host "1) USER AD"
    Write-Host "2) COMPUTER AD"
    Write-Host "3) ACTIONS"
    Write-Host "0) Exit"

    switch (Read-Host "Select") {

        "1" {
            while ($true) {
                Show-UserHeader
                Write-Host "1) Select User"
                Write-Host "2) Clear User"
                Write-Host "8) Toggle User"
                Write-Host "12) Move User"
                Write-Host "0) Back"

                switch (Read-Host "Select") {
                    "1" { Select-User }
                    "2" { Clear-User }
                    "8" { Toggle-User }
                    "12" { Move-User }
                    "0" { break }
                }
            }
        }

        "2" {
            while ($true) {
                Show-ComputerHeader
                Write-Host "1) Select Computer"
                Write-Host "2) Clear Computer"
                Write-Host "6) Toggle Computer"
                Write-Host "10) Move Computer"
                Write-Host "0) Back"

                switch (Read-Host "Select") {
                    "1" { Select-Computer }
                    "2" { Clear-Computer }
                    "6" { Toggle-Computer }
                    "10" { Move-Computer }
                    "0" { break }
                }
            }
        }

        "3" {
            while ($true) {
                Write-Host "1) GPUpdate"
                Write-Host "2) Restart"
                Write-Host "0) Back"

                switch (Read-Host "Select") {
                    "1" { Run-GPUpdate }
                    "2" { Restart-RemoteComputer }
                    "0" { break }
                }
            }
        }

        "0" { break }
    }
}
