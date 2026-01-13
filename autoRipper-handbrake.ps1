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

DataChecker

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# Set Logfile Location
$logFile = "$PSScriptRoot\autoRipper-HandBrake.txt"
#$logLoc = "$env:USERPROFILE\Documents\"

# Generic Write-Log Function for all statements
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )

    # Note: Ensure $logFile is defined globally or passed in as well
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $Message"

    # Using -ErrorAction SilentlyContinue in case the file isn't ready
    Add-Content -Path $logFile -Value $line 
    Write-Host $line
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
    & $handbrakeExe -i "$($file.FullName)" -o "$outputFile" --preset-import-file "D:\GitHubRepos\AutoRip\autoDVDRipper-Windows\presets.json" --preset "Plex Preset"
    }

Write-Host "All files processed!"