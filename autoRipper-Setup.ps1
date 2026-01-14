#Standard parameters to define through the process
$params = @{
    driveLetter    = "J:"
    makeMKVExe     = "D:\MakeMKV2\makemkvcon64.exe"
    handbrakeExe   = "D:\Handbrake\HandBrakeCLI.exe"
    mkvFileDir     = "P:\!unEncoded"
    mp4FileDir     = "P:\Movies"
}

# ---------------------------------------------------------------------
# Debug Functions
# ---------------------------------------------------------------------
# This function will output all current variables listed in the params array
function DataChecker {
    # Quickly add the current file's name to the params array
    $callerPath = $MyInvocation.ScriptName
    $params.fileName = Split-Path -Leaf $callerPath

    # Output current params array
    Write-Host "Starting Script: $($MyInvocation.MyCommand.Name)"
    Write-Host "Current Parameters:"
    $params | Out-String | Write-Host

    # File name is only needed during request so this removes it
    $params.Remove("fileName")
}

DataChecker

# ---------------------------------------------------------------------
# Validation Functions
# ---------------------------------------------------------------------
# Validate that the executables exist
function ExeCheck {
    foreach ($path in @($makeMKVExe, $handbrakeExe)) {
        if (-not (Test-Path $path)) {
            Write-Log "Required executable not found: $path"
            exit 1
        }
    }
}

ExeCheck

<# # ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# Set Logfile Location
$logDir = "$env:USERPROFILE\Documents\"

$callerPath = $MyInvocation.ScriptName
$fileName = Split-Path -Leaf $callerPath
$logLocation = Join-Path $logDir $fileName

Get-Item $logLocation | Rename-Item -NewName { $_.BaseName + ".log" }

if (-not (Test-Path -Path $logLocation)) {
    Write-Log "Creating missing directory: $mkvDestination"
    New-Item -ItemType Directory -Path $mkvDestination | Out-Null
}

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
} #>