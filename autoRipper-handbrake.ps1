#param(
#    [string]$handbrakeExe,   # Expects "D:\Handbrake\HandBrakeCLI.exe"
#    [string]$mp4Destination,   # Expects the mp4 disc folder path
#    [string]$mkvDestination,   # Expects the mkv disc folder path
#    [string]$discName
#)

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

Write-Log "The handbrake script has started"

# Create output folder if it doesn't exist
if (!(Test-Path "$mp4Destination")) {
    New-Item -ItemType Directory -Path "$mp4Destination"
}

# Get all video files (mp4, mkv, avi)
$files = Get-ChildItem -Path "$mkvDestination" -Include *.mp4, *.mkv, *.avi -Recurse
Write-Log "File count for $mkvDestination = $($files.Count)"

foreach ($file in $files) {
    Write-Host "Processing: $($file.Name)"

	# Define the output path properly
    $outputFile = Join-Path $mp4Destination ($file.BaseName + ".mp4")
    
    Write-Log "Processing: $($file.Name) -> $outputFile"
	
    # HandBrakeCLI Arguments
    & $handbrakeExe -i "$($file.FullName)" -o "$outputFile" --preset-import-file "D:\Handbrake\Scripts\presets.json" --preset "Plex Preset"
    }

Write-Host "All files processed!"