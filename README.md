# TelemetryTool2SIEM

Modified and improved based on CyberArk's Telemetry tool, and jcreameriii's TelemetryTool2CSV script - https://github.com/aglerj/TelemetryTool2CSV

Purpose:
To use CyberArk's Telemetry tool for On-prem environments only (don't send data to CyberArk), and instead send the data to your SIEM.

Updates:
6/2/2023 - Joe Agler - Adjusted to send to SIEM via syslog and create the required folders automatically if they don't exist. 

- Check out my CyberArk related blogs here -  https://medium.com/@aglerj
- Looking to buy CyberArk plugins pre-packaged? Check out my site here — https://www.keyvaultsolutions.com

Prerequisites:
Your SIEM configured to ingest the syslog data we're sending. For example, listen on port 9997, and send those events into index=cyberark . It depends on how your SIEM environment is configured.

Step 1: Download the CyberArk Telemetry tool 
- Download, extract and run Install the CyberArk Telemetry Tool to the default path on your utility server. When installing, do not provide a CyberArk key etc related to the Telemetry install.

Step 2: Update the config.json file under ConfigFiles
- Adjust the config.json file's outputAdapters section to only have the jsonfileoutputadapter like shown below. Or, download the config.json file from my github repo (https://github.com/aglerj/TelemetryTool2SIEM/blob/main/config.json), and replace the existing one the Telemetry tool creates.

 "outputAdapters":     [
                {
            "name": "JsonFileOutputAdapter",
            "type": "CyberArk.Telemetry.Output.File.JsonFileOutputAdapter, CyberArk.Telemetry.Output.File",
            "enabled": true,
            "adapterSettings": {"outputFilePath": "Output\\telemetryData_#date#.json"}
        } ]

Step 3: Download and update the Script
- Download the PowerShell script - https://github.com/aglerj/TelemetryTool2SIEM/blob/main/TelemetryToolETL.ps1 . Update the script to utilize your correct SIEM IP and Port. Note that this script utilizes UDP.

#Update to use your Syslog VIP IP here
$Syslogserver="192.168.65.200"

#Update to use your syslog port
$port = "9997"

Step 4: Staging the Script
- Stage the updated PowerShell script on the utility server that runs your CyberArk Telemetry Tool scheduled task. On that machine, navigate to the default CyberArk Telemetry folder (C:/Program Files/CyberArk/CyberArk Telemetry). Paste the updated PowerShell script within the ETL folder.

Step 5: Modify the Scheduled Task
- Launch task scheduler and edit the CyberArk Telemetry task by right clicking on it and selecting properties. Under the Actions tab, add a new action to launch the PowerShell script.
Program/script: powershell
Add arguments (optional): -NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File "C:\Program Files\CyberArk\CyberArk Telemetry\ETL\TelemetryToolETL.ps1"
Press OK.

Step 6: Run the Scheduled Task on-demand
 - Right click on the scheduled task and run on-demand. Wait for the scheduled task to finish.  

Step 7: Checking the output
 - Log into your SIEM. Wait a few minutes for the events to be indexed. Search your related SIEM index, such as index=cyberark | search "CyberArk Telemetry".

Example data in your SIEM:
![image](https://github.com/aglerj/TelemetryTool2SIEM/assets/21351031/67efab4f-3a84-46fc-9e37-b82170eb6ed2)


