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

# ---------------------------------------------------------------------
# Debug Functions
# ---------------------------------------------------------------------
# Create function to run a Parameters check
function paramsCheck {
    Write-Host "Starting Script: $($MyInvocation.MyCommand.Name)"
    Write-Host "Current Parameters:"
    $PSBoundParameters | Out-String | Write-Host
}

paramsCheck

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# Set Logfile Location
#$logFile = "$env:USERPROFILE\Documents\DVD_Monitor_Log_makeMKV.txt"
$logLoc = "$env:USERPROFILE\Documents\"

# Generic Write-Log Function for all statements
function Write-Log {
	$logName = "makeMKV-Full.txt"
	$logFile = Join-Path $logLoc $logName

    param(
        [string]$Message,
        [string]$Color = 'White'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"

    Add-Content -Path $logFile -Value $line
    Write-Host $line -ForegroundColor $Color
}

# Generic Write-Log Function for all statements
function Error-Log {
	$logName = "makeMKV-Error.txt"
	$logFile = Join-Path $logLoc $logName

    param(
        [string]$Message,
        [string]$Color = 'White'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"

    Add-Content -Path $logFile -Value $line
    Write-Host $line -ForegroundColor $Color
}

# ---------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------
# Create Destination folder if it doesn't exist
if (-not (Test-Path -Path $mkvDestination)) {
    Write-Log "Creating missing directory: $mkvDestination" -color Cyan
    New-Item -ItemType Directory -Path $mkvDestination | Out-Null
}

# Validate that the executables exist
foreach ($path in @($makeMKVExe, $handbrakeExe)) {
    if (-not (Test-Path $path)) {
        Write-Log "Required executable not found: $path" Red
        exit 1
    }
}

# ---------------------------------------------------------------------
# Start Script
# ---------------------------------------------------------------------
Write-Log "Starting MakeMKV script for disc [$discName]" -color Green

# Rip Starting
Write-Log "--- Starting Rip for: $mkvDestination ---" -color Yellow

# 1. Execute MakeMKV using the passed variables
# Syntax: makemkvcon [mode] [source] [title] [destination]
# Call exe, create mkv file, use specified drive, all files on disk, output to destination, high verbose
& $makeMKVExe mkv "dev:$driveLetter" all "$mkvDestination" --robot 

# 2. Rename files upon success
if ($LASTEXITCODE -eq 0) {
    Write-Log "Rip Complete. Starting rename process..." -color Green
    
    # Get all MKV files created in the destination
    $files = Get-ChildItem -Path $mkvDestination -Filter *.mkv
    $count = 1

    foreach ($file in $files) {
        # Format: VolumeName_01.mkv, VolumeName_02.mkv, etc.
        $newName = "{0}_{1:D2}.mkv" -f $discName, $count
        $newPath = Join-Path $mkvDestination $newName
        
        Rename-Item -Path $file.FullName -NewName $newName
        Write-Log "Renamed $($file.Name) to $newName"
        $count++
    }
}

# If MKV Exit code is not a successful run, exit script with error
else {
    Write-Log "--- Rip FAILED with Exit Code $LASTEXITCODE ---" -color Red
	Error-Log "--- Rip FAILED with Exit Code $LASTEXITCODE ---" -color Red
}