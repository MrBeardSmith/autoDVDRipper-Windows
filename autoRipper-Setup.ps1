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
    $CallerPath = $MyInvocation.ScriptName
    $params.fileName = Split-Path -Leaf $CallerPath

    # Output current params array
    Write-Host "Starting Script: $($MyInvocation.MyCommand.Name)"
    Write-Host "Current Parameters:"
    $params | Out-String | Write-Host

    # File name is only needed during request so this removes it
    $params.Remove("fileName")
}