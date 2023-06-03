# TelemetryTool2CSV

- Modified and improved based on CyberArk's Telemetry tool, and jcreameriii's TelemetryTool2CSV script - https://github.com/aglerj/TelemetryTool2CSV

Updates:
6/2/2023 - Joe Agler - Adjusted to send to SIEM via syslog and create the required folders automatically if they don't exist. Adjusted the steps wording below. 

Check out my CyberArk related blogs here -  https://medium.com/@aglerj
Looking to buy CyberArk plugins pre-packaged? Check out my site here — https://www.keyvaultsolutions.com

Prerequisites: 
Your SIEM configured to have data input monitoring on a port

Step 1: Download and update the Script
Download the PowerShell script - https://github.com/aglerj/TelemetryTool2CSV. Update the script to utilize your correct SIEM IP and Port.

#Update to use your Syslog VIP IP here
$Syslogserver="192.168.65.200"

#Update to use your syslog port
$port = "9997"

Step 2: Staging the Script
Stage the PowerShell script on the machine that runs your CyberArk Telemetry Tool scheduled task. On that machine, navigate to the default CyberArk Telemetry folder (C:/Program Files/CyberArk/CyberArk Telemetry). Paste the PowerShell script within the ETL folder.

Step 3: Modify the Scheduled Task
Launch task scheduler and edit the CyberArk Telemetry task by right clicking on it and selecting properties. Under the Actions tab, add a new action to launch the PowerShell script.
Program/script: powershell
Add arguments (optional): -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "C:\Program Files\CyberArk\CyberArk Telemetry\ETL\TelemetryToolETL.ps1"
Press OK.

Step 4: Right click on the task and run on-demand.

Step 5: Checking the output
Log into your SIEM. Wait a few minutes for the events to be indexed. Search your related SIEM index, such as index=cyberark .


