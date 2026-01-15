param(
    [string]$driveLetter,       # Expects "J:"    
    [string]$makeMKVExe,   # Expects "D:\MakeMKV2\makemkvcon64.exe"
    [string]$handbrakeExe,   # Expects "D:\Handbrake\HandBrakeCLI.exe"
    [string]$mkvFileDir,     # Expects the mkv parent folder path
    [string]$mp4FileDir,       # Expects the mp4 parent path
    [string]$mp4Destination,   # Expects the mp4 disc folder path
    [string]$mkvDestination,   # Expects the mkv disc folder path
    [string]$discName
)

# 1. Load your external function into the current session
. "$PSScriptRoot\autoRipper-Setup.ps1"

# 1.a Log current parameters
DataChecker

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# Set Logfile Location
$logFile = "$PSScriptRoot\Log\autoRipper-cleanUp.txt"
$logFileFailure = "$PSScriptRoot\Log\autoRipper-cleanUp-Failure.txt"

# Generic Write-Log Function for all statements
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"
    Add-Content -Path $logFile -Value $line 
    Write-Host $line
}


# Failure Log Function for all failures to manually research
function FailureLog {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"
    Add-Content -Path $logFileFailure -Value $line 
    Write-Log $line
    Write-Error $line
}

# ---------------------------------------------------------------------
# File Count between MKV and MP4
# ---------------------------------------------------------------------
# Define your paths
$FolderA = "$mkvDestination"
$FolderB = "$mp4Destination"

# Get file counts (using -File to ignore subfolders)
$CountA = (Get-ChildItem -Path $FolderA -File).Count
$CountB = (Get-ChildItem -Path $FolderB -File).Count

# Output the results
Write-Host "Folder A: $CountA files" -ForegroundColor Cyan
Write-Host "Folder B: $CountB files" -ForegroundColor Cyan

if ($CountA -eq $CountB) {
    Write-Host "Success: File counts match!" -ForegroundColor Green
} else {
    $Difference = [Math]::Abs($CountA - $CountB)
    Write-Host "Warning: File counts do NOT match! Difference: $Difference" -ForegroundColor Red
}