# Configuration
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
$logFile = "$env:USERPROFILE\Documents\DVD_Monitor_Log_dvdDetect.txt"

# Create Function to output Logging to file
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host "$timestamp - $message"
}

# ---------------------------------------------------------------------
# Scripting Setup
# ---------------------------------------------------------------------
# State Tracking
$isMediaPresent = $false


# ---------------------------------------------------------------------
# Start Script
# ---------------------------------------------------------------------
Write-Log "--- Polling Monitor Started for $($params.driveLetter) ---"

# Check specified drive every 5 seconds
while ($true) {
    try {
        # Fixed: Using sub-expression for the drive letter in the query
        $drive = Get-CimInstance -Query "SELECT * FROM Win32_LogicalDisk WHERE DeviceID = '$($params.driveLetter)'"
		
        if ($null -ne $drive.VolumeName) {
		
            if (-not $isMediaPresent) {
                $discName = $drive.VolumeName
                $params.discName = $drive.VolumeName
                Write-Log "Disc detected in $($params.driveLetter) ($discName)"

                # Build mkvDestination and add to params
                $mkvDestination = Join-Path $params.mkvFileDir $discName
				$params.mkvDestination = $mkvDestination
				
				#Build mp4Destination and add to params
				$mp4Destination = Join-Path $params.mp4FileDir $discName
				$params.mp4Destination = $mp4Destination
                
                # Notification logic
                [System.Console]::Beep(1000, 200)
                [System.Console]::Beep(1200, 200)
                Add-Type -AssemblyName System.Windows.Forms
                $notification = New-Object System.Windows.Forms.NotifyIcon
                $notification.Icon = [System.Drawing.SystemIcons]::Information
                $notification.BalloonTipTitle = "DVD Detected"
                $notification.BalloonTipText = "Calling MakeMKV Script to save to $mkvDestination"
                $notification.Visible = $true
                $notification.ShowBalloonTip(5000)
                
                
                # Parameters check for debugging
                paramsCheck
											        
				# State Check for Media
				$isMediaPresent = $true 

                # Trigger MKV Script
                Write-Log "Starting script for MakeMKV."
                & "D:\GitHubRepos\AutoRip\autoDVDRipper-Windows\autoRipper-makeMKV.ps1" @params
				
				# Trigger MKV Script
                Write-Log "Starting script for Handbrake."
                & "D:\GitHubRepos\AutoRip\autoDVDRipper-Windows\autoRipper-handbrake.ps1" @params

                # Eject Disc after Rip				
                $shell = New-Object -ComObject Shell.Application
                $ejectDrive = $shell.Namespace(17).ParseName($params.driveLetter)
                $ejectDrive.InvokeVerb("Eject")

                # Cleanup notification icon
                $notification.Dispose()
            }
        }
        else {
            if ($isMediaPresent) {
                Write-Log "Disc removed from $($params.driveLetter)."
                $isMediaPresent = $false 

                # Remove params so it's clean for the next disc
                $params.Remove("mkvDestination")
                $params.Remove("mp4Destination")
                $params.Remove("discName")
            }
        }
    }
    catch {
        Write-Log "Error checking drive: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 5
}