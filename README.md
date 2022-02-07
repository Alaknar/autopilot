# Custom modification
The idea was to move the actual repetition process over to a scheduled task. Instead of deploying this as an application we instead deploy a script which creates this script as a file and a custom scheduled task, then reboot the computer.

The custom scheduled task will start at startup and run every 5 minutes for an hour. Every time it runs it will trigger this script, which then calls the Intune built-in scheduled task `\Microsoft\Windows\Workplace Join\Automatic-Device-Join`. Once events 306 or 335 are detected, the custom scheduled task is disabled.

This was made for reasons unique to our environment but maybe someone else finds them useful. 

The original (no longer applicable) instruction below.

Link to the original repo [HERE](https://github.com/steve-prentice/autopilot).

> # WaitForUserDeviceRegistration
> Pauses device ESP for up to 60 minutes for machine to register with AzureAD.
> Add the WaitForUserDeviceRegistration.intunewin app to Intune and specify the following command line:
> 
> powershell.exe -noprofile -executionpolicy bypass -file .\WaitForUserDeviceRegistration.ps1
> 
> To "uninstall" the app, the following can be used (for example, to get the app to re-install):
> 
> cmd.exe /c del %ProgramData%\DeviceRegistration\WaitForUserDeviceRegistration.ps1.tag
> 
> Specify the platforms and minimum OS version that you want to support.
> 
> For a detection rule, specify the path and file and "File or folder exists" detection method:
> 
> %ProgramData%\DeviceRegistration\WaitForUserDeviceRegistration
> WaitForUserDeviceRegistration.ps1.tag
> 
> Deploy the app as a required app to an appropriate set of devices.
