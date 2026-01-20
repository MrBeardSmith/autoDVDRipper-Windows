#Standard parameters to define through the process
$params = @{
    driveLetter    = "J:"
    makeMKVExe     = "D:\MakeMKV2\makemkvcon64.exe"
    handbrakeExe   = "D:\Handbrake\HandBrakeCLI.exe"
    mkvFileDir     = "P:\!unEncoded"
    mp4FileDir     = "P:\!encodedHolding"
    #encodePreset   = "$PSScriptRoot\presets.json"
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

<# 

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

#>


<# 

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# --TODO-- change Write-Log to accept a parameter about severity so it can handle all message types accordingly
# --TODO-- set up a statement to get current file name so this can be called anywhere

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

#>