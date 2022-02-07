# WaitForUserDeviceRegistration.ps1
#
# Based on Version 1.6.
# Modified version 1.1.
#
# Created: Steve Prentice, 2020
# Modified: Andrzej Zabrzeski, 2022
#
# Used to pause device ESP during Autopilot Hybrid Join to wait for
# the device to sucesfully register into AzureAD before continuing.
#
# Use IntuneWinAppUtil to wrap and deploy as a Windows app (Win32).
# See ReadMe.md for more information.
#
# Tip: Win32 apps only work as tracked apps in device ESP from 1903.
#
# Exits with return code 3010 to indicate a soft reboot is needed,
# which in theory it isn't, but it suited my purposes.

# Create a tag file just so Intune knows this was installed
$logFile = "C:\IGI\Logs\Build\AutoPilot_Checks.log"
If (-Not (Test-Path $logFile)) {
    New-Item -Path $AutoPilotChecks -ItemType File -Force
}
#Set-Content -Path $logFile -Value "Installed"

# Start logging
Start-Transcript $logFile

$filter304 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '304' # Automatic registration failed at join phase
}

$filter306 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '306' # Automatic registration Succeeded
}

$filter334 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '334' # Automatic device join pre-check tasks completed. The device can NOT be joined because a domain controller could not be located.
}

$filter335 = @{
    LogName = 'Microsoft-Windows-User Device Registration/Admin'
    Id      = '335' # Automatic device join pre-check tasks completed. The device is already joined.
}

$filter20225 = @{
    LogName = 'Application'
    Id      = '20225' # A dialled connection to RRAS has sucesfully connected.
}

# Wait for up to 60 minutes, re-checking once a minute...

# Let's get some events...
$events304 = Get-WinEvent -FilterHashtable $filter304   -MaxEvents 1 -EA SilentlyContinue
$events306 = Get-WinEvent -FilterHashtable $filter306   -MaxEvents 1 -EA SilentlyContinue
$events334 = Get-WinEvent -FilterHashtable $filter334   -MaxEvents 1 -EA SilentlyContinue
$events335 = Get-WinEvent -FilterHashtable $filter335   -MaxEvents 1 -EA SilentlyContinue
$events20225 = Get-WinEvent -FilterHashtable $filter20225 -MaxEvents 1 -EA SilentlyContinue

If ($events335) { 
    Write-Host "Event ID 335 found - The device is already joined. Disabling the scheduled task."
    Disable-ScheduledTask "TriggerHybridJoin" 
}

ElseIf ($events306) {
    Write-Host "Event ID 306 found - Automatic registration Succeeded. Disabling the scheduled task."
    Disable-ScheduledTask "TriggerHybridJoin" 
}

ElseIf ($events20225 -And $events334 -And !$events304) {
    Write-Host "RRAS dialled sucesfully. Trying Automatic-Device-Join task to create userCertificate..."
    Start-ScheduledTask "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"
}

Else {
    Write-Host "No events indicating successful device registration with Azure AD."

    If ($events304) {
        Write-Host "Trying Automatic-Device-Join task again..."
        Start-ScheduledTask "\Microsoft\Windows\Workplace Join\Automatic-Device-Join"
    }
}


If ($events306) { 
    Write-Host $events306.Message
    Write-Host "Exiting with return code 3010 to indicate a soft reboot is needed."
    Stop-Transcript
    #Exit 3010
}

If ($events335) { Write-Host $events335.Message }

Write-Host "Script complete, exiting."

Stop-Transcript
