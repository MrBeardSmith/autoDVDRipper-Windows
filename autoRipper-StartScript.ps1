# 1. Load your external function into the current session
. "$PSScriptRoot\autoRipper-Setup.ps1"

# 1.a Log current parameters
DataChecker

# ---------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------
# Set Logfile Location
$logFile = "$PSScriptRoot\autoRipper-StartScript.txt"

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

# ---------------------------------------------------------------------
# Disc Check and final Param 
# ---------------------------------------------------------------------
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
                # Beep when disc is detected
                [System.Console]::Beep(1000, 200)
                [System.Console]::Beep(1200, 200)
                Add-Type -AssemblyName System.Windows.Forms
                $notification = New-Object System.Windows.Forms.NotifyIcon
                $notification.Icon = [System.Drawing.SystemIcons]::Information
                $notification.BalloonTipTitle = "DVD Detected"
                $notification.BalloonTipText = "Calling MakeMKV Script to save to $mkvDestination"
                $notification.Visible = $true
                $notification.ShowBalloonTip(5000)
					        
				# State Check for Media
                # Now that a disc is detected, flip this flag to true
				$isMediaPresent = $true 

# ---------------------------------------------------------------------
# MakeMKV
# ---------------------------------------------------------------------
                Write-Log "Starting script for MakeMKV."

                # Trigger MKV Script 
                # This script needs everything to wait so it is not ran as a job
                & "$PSScriptRoot\autoRipper-makeMKV.ps1" @params
				
# ---------------------------------------------------------------------
# HandBrake
# ---------------------------------------------------------------------
                Write-Log "Starting script for Handbrake."

                # Create Handbrake Script pathing. Not sure why I can't use directly in job but /shrug
                $handBPath = Join-Path -Path $PSScriptRoot -ChildPath "autoRipper-handbrake.ps1"

             	# Create Handbrake Job
                # This script can run async so execute as a job
                $Job = Start-ThreadJob -ScriptBlock {

                    # Call handbrake.ps1 script to execute
                    & @using:handBPath -ArgumentList @using:params
                
                }

# ---------------------------------------------------------------------
# File Validation and Folder Sorting
# ---------------------------------------------------------------------
                Write-Log "Starting script for File Validation."

                # Create Handbrake Script pathing. Not sure why I can't use directly in job but /shrug
                $fileValPath = Join-Path -Path $PSScriptRoot -ChildPath "autoRipper-cleanUp.ps1"

             	# Create Handbrake Job
                # This script can run async so execute as a job
                $Job = Start-ThreadJob -ScriptBlock {

                    # Call handbrake.ps1 script to execute
                    & @using:fileValPath -ArgumentList @using:params
                
                }

# ---------------------------------------------------------------------
# Eject Disc
# ---------------------------------------------------------------------

                # Eject Disc after Rip	
                Start-Sleep -Seconds 2			
                $shell = New-Object -ComObject Shell.Application
                $ejectDrive = $shell.Namespace(17).ParseName($params.driveLetter)
                $ejectDrive.InvokeVerb("Eject")

                # Cleanup notification icon
                $notification.Dispose()
            }
        }

# ---------------------------------------------------------------------
# After Disc Eject, clean-up
# ---------------------------------------------------------------------

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

# ---------------------------------------------------------------------
# Error Catch
# ---------------------------------------------------------------------

    catch {
        Write-Log "Error checking drive: $($_.Exception.Message)"
    }


# ---------------------------------------------------------------------
# Loop and Clea-up
# ---------------------------------------------------------------------
    Start-Sleep -Seconds 10

    # Check if any HandBJobs are 'done' then remove them
    $FinishedJobs = Get-Job | Where-Object { $_.State -in 'Completed', 'Failed', 'Stopped' }
    $CurrentJobs = Get-Job | Select-Object ID, Name, State
    
    if ($FinishedJobs) {
        foreach ($Job in $FinishedJobs) {
            $Output = Receive-Job -Job $Job  # Capture output before it's gone!
            Write-Host "Cleaned up Job $($Job.Id). Result: $Output" -ForegroundColor Gray
            Remove-Job -Job $Job
        }
    else {
        $CurrentJobs | Format-Table -AutoSize
    }
}
}