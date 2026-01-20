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
$logFile = "$PSScriptRoot\Log\autoRipper-HandBrake.txt"
$logFileFailure = "$PSScriptRoot\Log\autoRipper-HandBrake-Failure.txt"

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
# Start Script
# ---------------------------------------------------------------------

Write-Log "The handbrake script has started"

# Create output folder if it doesn't exist
if (!(Test-Path "$mp4Destination")) {
    New-Item -ItemType Directory -Path "$mp4Destination"
}

# Get all video files (mp4, mkv, avi)
$files = Get-ChildItem -Path "$mkvDestination" -Include *.mp4, *.mkv, *.avi -Recurse
Write-Log "File count for $mkvDestination = $($files.Count)"

foreach ($file in $files) {
    Write-Log "Processing: $($file.Name)"

	# Define the output path properly
    $outputFile = Join-Path $mp4Destination ($file.BaseName + ".mp4")
    
    Write-Log "Processing: $($file.Name) -> $outputFile"
	
    # HandBrakeCLI Arguments
    & $handbrakeExe -i "$($file.FullName)" -o "$outputFile" --preset-import-file "D:\GitHubRepos\AutoRip\autoDVDRipper-Windows\presets.json" --preset "Plex Preset"
    }

Write-Log "All files encoded!"


# ---------------------------------------------------------------------
# Validation and File Clean-up
# ---------------------------------------------------------------------

Write-Log "Starting script for File Validation."

# File Count between MKV and MP4
# Check that both folders were made before counting
if ((Test-Path $mkvDestination) -and (Test-Path $mp4Destination)) {

    # Get file counts
    $mkvCount = (Get-ChildItem -Path $mkvDestination -File).Count
    $mp4Count = (Get-ChildItem -Path $mp4Destination -File).Count

    # Output the results
    Write-Log "mkv A: $mkvCount files in: $mkvDestination"
    Write-Log "mp4 B: $mp4Count files in: $mp4Destination"

    # Check count matches
    if ($mkvCount -eq $mp4Count) {
        Write-Log "Counts match. Deleting source folder: $mkvDestination"
        Remove-Item -Path $mkvDestination -Recurse -Force
        Write-Log "Cleanup complete."
    } else {
        $Difference = [Math]::Abs($mkvCount - $mp4Count)
        FailureLog "Warning: File counts do NOT match! Difference: $Difference"
        exit
    }

} else {
    FailureLog "One or both folder paths do not exist. Please check your paths. `n Expected Target was $mp4Destination"
    exit
}    

Write-Log "Starting script to move possible Extras"

# Find The Largest File
$largestFile = Get-ChildItem -Path $mp4Destination -File | 
               Sort-Object -Property Length | 
               Select-Object -Last 1   

# Create a collection of anything that isn't TLF
$notLargestFile = Get-ChildItem -Path $mp4Destination -File | 
               Sort-Object -Property Length | 
               Select-Object -SkipLast 1            

# Check if a file was actually found
if ($largestFile) {
    $sizeMB = [Math]::Round($largestFile.Length / 1MB, 2)
    
    Write-Log "The largest file is: $($largestFile.FullName)"
    Write-Log "Size: $sizeMB MB"
} else {
    FailureLog "No files found in $mp4Destination."
    exit
}

# Check for an Extras folders and make one if it doesn't exist
$extrasFolder = Join-Path -Path $mp4Destination -ChildPath "Extras"
if (!(Test-Path $extrasFolder)) {
    Write-Log "Creating Extras Folder"
    New-Item -Path $extrasFolder -ItemType Directory -Force
}

# Anything not TLF gets moved into the Extras folder
if ($notLargestFile) {
    $notLargestFile | Move-Item -Destination $extrasFolder
    Write-Log "Moved $($notLargestFile.Count) files to $extrasFolder."
} else {
    Write-Log "No files found to move (or only one file exists)."
    Write-Warning "No files found to move (or only one file exists)."
}