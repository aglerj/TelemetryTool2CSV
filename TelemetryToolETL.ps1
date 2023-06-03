<#
_________        ___.                   _____         __     ___________    .__                         __                 
\_   ___ \___.__.\_ |__   ___________  /  _  \_______|  | __ \__    ___/___ |  |   ____   _____   _____/  |________ ___.__.
/    \  \<   |  | | __ \_/ __ \_  __ \/  /_\  \_  __ \  |/ /   |    |_/ __ \|  | _/ __ \ /     \_/ __ \   __\_  __ <   |  |
\     \___\___  | | \_\ \  ___/|  | \/    |    \  | \/    <    |    |\  ___/|  |_\  ___/|  Y Y  \  ___/|  |  |  | \/\___  |
 \______  / ____| |___  /\___  >__|  \____|__  /__|  |__|_ \   |____| \___  >____/\___  >__|_|  /\___  >__|  |__|   / ____|
        \/\/          \/     \/              \/           \/              \/          \/      \/     \/             \/     


#############################################################################################################################
#
#  
# Updates:
# 6/2/2023 - Joe Agler - Adjusted to send to SIEM via syslog and create required folders automatically.
#
#  
# Modified and improved based on CyberArk's Telemetry tool, and jcreameriii's script -
# https://github.com/jcreameriii/TelemetryTool2CSV
# https://cyberark-customers.force.com/s/article/Better-Together-CyberArk-Telemetry-and-Business-Intelligence
#
#############################################################################################################################
#>

# Configuration Parameters
$jsonpath = "C:\Program Files\CyberArk\CyberArk Telemetry\Output"
$path = "C:\Program Files\CyberArk\CyberArk Telemetry\ETL\CSV"

#Check if the $path folder exists. Create folder if it doesn't.
If(!(test-path -PathType container $path))
{
      New-Item -ItemType Directory -Path $path
}

#Check if the $jsonpath folder exists. Create folder if it doesn't.
If(!(test-path -PathType container $jsonpath))
{
      New-Item -ItemType Directory -Path $jsonpath
}


#Syslog configs
$Hostname = "$env:COMPUTERNAME"
$domain = "$env:USERDOMAIN"
$Version = "1.0"
$Date = Get-Date
$DateTime = $Date.ToString("yyyy-MM-ddTHH:mm:ssZ")

#Update to use your Syslog VIP IP here
$Syslogserver="192.168.65.200"

#Update to use your syslog port
$port = "9997"

# Find latest JSON Telemetry File & Load it for processing
$findjson = Get-ChildItem -Path $jsonpath -Recurse -Filter "*telemetryData*" | select Name | Sort Name -Descending
$jsonfilename = $findjson | Select-Object -Index 0
$jsonfilename = ($jsonfilename | Format-Wide | Out-String).Trim()
$json = Get-Content -Raw -Path $jsonpath/$jsonfilename
# Get Date & Set Date Variable
$datetemp = $json | ConvertFrom-Json | select -expand General | select -expand ExecutedAtUTC
$date = $datetemp.substring(0,10)
####

#Monitor Type to help parsing in SIEM
$MonitorType = "TelemetryPlatforms"


# Create Platform Details CSV, including checking to see if file exists already
$csv = "PlatformDetails"
$platformdetails = $json | ConvertFrom-Json | select -expand Platforms | select -expand PlatformsDetails
$platformdetails | Add-Member -MemberType NoteProperty "Date" -Value $date
# check to see if file exists
$findfile = Get-ChildItem -Path $path -Recurse -Filter "$date-$csv.csv" | select Name | Sort Name -Descending
$platformdetailsfile = $findfile | Select-Object -Index 0
$platformdetailsfile = ($platformdetailsfile | Format-Wide | Out-String).Trim()
if ( "$date-$csv.csv" -eq $platformdetailsfile)
{
    "ERROR: Duplicate $csv details output found. This process has already ran for this date. Please confirm you have a newer JSON file and run again." >> $jsonpath/$date.log
}
else
{
    #$platformdetails | select Date,PolicyID,PlatformBaseID,PlatformBaseType,PlatformBaseProtocol,CompliantAccounts,TotalAccounts,IsActive | Sort PolicyID | Export-Csv -NoTypeInformation -Path "$path/$date-$csv.csv"
    $platformdetails = $platformdetails | select Date,PolicyID,PlatformBaseID,PlatformBaseType,PlatformBaseProtocol,CompliantAccounts,TotalAccounts,IsActive

    ForEach($name in $platformdetails) {
    $platformdetailsDate = $name.Date
    $platformdetailsPolicyID = $name.PolicyID
    $platformdetailsPlatformBaseID = $name.PlatformBaseID
    $platformdetailsPlatformBaseType = $name.PlatformBaseType
    $platformdetailsPlatformBaseProtocol = $name.PlatformBaseProtocol
    $platformdetailsCompliantAccounts = $name.CompliantAccounts
    $platformdetailsTotalAccounts = $name.TotalAccounts
    $platformdetailsIsActive = $name.IsActive

    #Send via syslog to SIEM
    $syslogoutput = "$DateTime CEF:0|CyberArk Telemetry|$MonitorType|$Version|$platformdetailsPolicyID|$platformdetailsPlatformBaseID|$platformdetailsPlatformBaseType|$platformdetailsPlatformBaseProtocol|$platformdetailsCompliantAccounts|$platformdetailsTotalAccounts|$platformdetailsIsActive|$platformdetailsDate"

    $syslogoutputclean = $syslogoutput -replace "`n|`r"
    $syslogoutputclean | ConvertTo-Json
    
    $UDPClient = New-Object System.Net.Sockets.UdpClient
    $UDPClient.Connect($Syslogserver, $port)
    $encoding = [system.text.encoding]::ASCII
    $byteSyslogMessage = $encoding.getbytes(''+$syslogoutputclean+'')
    $UDPClient.send($byteSyslogMessage, $byteSyslogMessage.length)

    }
}

#Monitor Type to help parsing in SIEM
$MonitorType = "TelemetryComponents"


#Create Components Object
$csv = "Components"
$components = $json | ConvertFrom-Json | select -expand Components | select -expand ComponentTypes
$components | Add-Member -MemberType NoteProperty "Date" -Value $date
# check to see if file exists
$findfile = Get-ChildItem -Path $path -Recurse -Filter "$date-$csv.csv" | select Name | Sort Name -Descending
$componentsfile = $findfile | Select-Object -Index 0
$componentsfile = ($componentsfile | Format-Wide | Out-String).Trim()
if ( "$date-$csv.csv" -eq $componentsfile)
{
    "ERROR: Duplicate $csv output found. This process has already ran for this date. Please confirm you have a newer JSON file and run again." >> $jsonpath/$date.log
}
else
{
    #$components | select Date,ComponentType,Version,Deployed,Licensed | Export-Csv -NoTypeInformation -Path "$path/$date-$csv.csv"
    $components = $components | select Date,ComponentType,Version,Deployed,Licensed

    ForEach($name in $components) {
    $componentsDate = $name.Date
    $componentsComponentType = $name.ComponentType
    $componentsVersion = $name.Version
    $componentsDeployed = $name.Deployed
    $componentsLicensed = $name.Licensed


    #Send via syslog to SIEM
    $syslogoutput = "$DateTime CEF:0|CyberArk Telemetry|$MonitorType|$Version|$componentsComponentType|$componentsVersion|$componentsDeployed|$componentsLicensed|$componentsDate"

    $syslogoutputclean = $syslogoutput -replace "`n|`r"
    $syslogoutputclean | ConvertTo-Json
    
    $UDPClient = New-Object System.Net.Sockets.UdpClient
    $UDPClient.Connect($Syslogserver, $port)
    $encoding = [system.text.encoding]::ASCII
    $byteSyslogMessage = $encoding.getbytes(''+$syslogoutputclean+'')
    $UDPClient.send($byteSyslogMessage, $byteSyslogMessage.length)

    }


}

#Monitor Type to help parsing in SIEM
$MonitorType = "TelemetryUsers"

#Create Users Object
$csv = "Users"
$users = $json | ConvertFrom-Json | select -expand Users | select -expand UserTypes
$users | Add-Member -MemberType NoteProperty "Date" -Value $date
$findfile = Get-ChildItem -Path $path -Recurse -Filter "$date-$csv.csv" | select Name | Sort Name -Descending
$usersfile = $findfile | Select-Object -Index 0
$usersfile = ($usersfile | Format-Wide | Out-String).Trim()
if ( "$date-$csv.csv" -eq $usersfile)
{
    "ERROR: Duplicate $csv output found. This process has already ran for this date. Please confirm you have a newer JSON file and run again." >> $jsonpath/$date.log
}
else
{
    #$users | select Date,UserType,LicensedUsers,AllocatedUsers | Export-Csv -NoTypeInformation -Path "$path/$date-$csv.csv"
    $users = $users | select Date,UserType,LicensedUsers,AllocatedUsers


    ForEach($name in $users) {
    $usersDate = $name.Date
    $usersUserType = $name.UserType
    $usersLicensedUsers = $name.LicensedUsers
    $usersAllocatedUsers = $name.AllocatedUsers


    #Send via syslog to SIEM
    $syslogoutput = "$DateTime CEF:0|CyberArk Telemetry|$MonitorType|$Version|$usersUserType|$usersLicensedUsers|$usersAllocatedUsers|$usersDate"

    $syslogoutputclean = $syslogoutput -replace "`n|`r"
    $syslogoutputclean | ConvertTo-Json
    
    $UDPClient = New-Object System.Net.Sockets.UdpClient
    $UDPClient.Connect($Syslogserver, $port)
    $encoding = [system.text.encoding]::ASCII
    $byteSyslogMessage = $encoding.getbytes(''+$syslogoutputclean+'')
    $UDPClient.send($byteSyslogMessage, $byteSyslogMessage.length)

    }
   
}

#Monitor Type to help parsing in SIEM
$MonitorType = "TelemetryAppIDs"

#Create AppIDs Object
$csv = "AppIDs"
$appids = $json | ConvertFrom-Json | select -expand Applications | select -expand ApplicationTypes
$appids | Add-Member -MemberType NoteProperty "Date" -Value $date
$findfile = Get-ChildItem -Path $path -Recurse -Filter "$date-$csv.csv" | select Name | Sort Name -Descending
$appidsfile = $findfile | Select-Object -Index 0
$appidsfile = ($appidsfile | Format-Wide | Out-String).Trim()
if ( "$date-$csv.csv" -eq $appidsfile)
{
    "ERROR: Duplicate $csv output found. This process has already ran for this date. Please confirm you have a newer JSON file and run again." >> $jsonpath/$date.log
}
else
{
    #$appids | select Date,UserType,LicensedUsers,AllocatedUsers | Export-Csv -NoTypeInformation -Path "$path/$date-$csv.csv"
    $appids = $appids | select Date,UserType,LicensedUsers,AllocatedUsers 

    ForEach($name in $appids) {
    $appidsDate = $name.Date
    $appidsUserType = $name.UserType
    $appidsLicensedUsers = $name.LicensedUsers
    $appidsAllocatedUsers = $name.AllocatedUsers


    #Send via syslog to SIEM
    $syslogoutput = "$DateTime CEF:0|CyberArk Telemetry|$MonitorType|$Version|$appidsUserType|$appidsLicensedUsers|$appidsAllocatedUsers|$appidsDate"

    $syslogoutputclean = $syslogoutput -replace "`n|`r"
    $syslogoutputclean | ConvertTo-Json
    
    $UDPClient = New-Object System.Net.Sockets.UdpClient
    $UDPClient.Connect($Syslogserver, $port)
    $encoding = [system.text.encoding]::ASCII
    $byteSyslogMessage = $encoding.getbytes(''+$syslogoutputclean+'')
    $UDPClient.send($byteSyslogMessage, $byteSyslogMessage.length)

    }

}


#Monitor Type to help parsing in SIEM
$MonitorType = "TelemetryAccounts"

#Create Accounts Object
$csv = "Accounts"
$accounts = $json | ConvertFrom-Json | select -expand Accounts
$accounts | Add-Member -MemberType NoteProperty "Date" -Value $date
$findfile = Get-ChildItem -Path $path -Recurse -Filter "$date-$csv.csv" | select Name | Sort Name -Descending
$accountsfile = $findfile | Select-Object -Index 0
$accountsfile = ($accountsfile | Format-Wide | Out-String).Trim()
if ( "$date-$csv.csv" -eq $accountsfile)
{
    "ERROR: Duplicate $csv output found. This process has already ran for this date. Please confirm you have a newer JSON file and run again." >> $jsonpath/$date.log
}
else
{
    #$accounts | select TotalAccounts,TotalCompliantAccounts,DayAccountsSecretShow,WeekAccountsSecretShow,MonthAccountsSecretShow,YearAccountsSecretShow,DayAccountsSecretConnect,WeekAccountsSecretConnect,MonthAccountsSecretConnect,YearAccountsSecretConnect | Export-Csv -NoTypeInformation -Path "$path/$date-$csv.csv"
    $accounts = $accounts | select TotalAccounts,TotalCompliantAccounts,DayAccountsSecretShow,WeekAccountsSecretShow,MonthAccountsSecretShow,YearAccountsSecretShow,DayAccountsSecretConnect,WeekAccountsSecretConnect,MonthAccountsSecretConnect,YearAccountsSecretConnect 

    ForEach($name in $accounts) {
    $accountsTotalAccounts = $name.TotalAccounts
    $accountsTotalCompliantAccounts = $name.TotalCompliantAccounts
    $accountsDayAccountsSecretShow = $name.DayAccountsSecretShow
    $accountsWeekAccountsSecretShow = $name.WeekAccountsSecretShow
    $accountsMonthAccountsSecretShow = $name.MonthAccountsSecretShow
    $accountsYearAccountsSecretShow = $name.YearAccountsSecretShow
    $accountsDayAccountsSecretConnect = $name.DayAccountsSecretConnect
    $accountsWeekAccountsSecretConnect = $name.WeekAccountsSecretConnect
    $accountsMonthAccountsSecretConnect = $name.MonthAccountsSecretConnect
    $accountsYearAccountsSecretConnect = $name.YearAccountsSecretConnect


    #Send via syslog to SIEM
    $syslogoutput = "$DateTime CEF:0|CyberArk Telemetry|$MonitorType|$Version|$accountsTotalAccounts|$accountsTotalCompliantAccounts|$accountsDayAccountsSecretShow|$accountsWeekAccountsSecretShow|$accountsMonthAccountsSecretShow|$accountsYearAccountsSecretShow|$accountsDayAccountsSecretConnect|$accountsWeekAccountsSecretConnect|$accountsMonthAccountsSecretConnect|$accountsYearAccountsSecretConnect"

    $syslogoutputclean = $syslogoutput -replace "`n|`r"
    $syslogoutputclean | ConvertTo-Json
    
    $UDPClient = New-Object System.Net.Sockets.UdpClient
    $UDPClient.Connect($Syslogserver, $port)
    $encoding = [system.text.encoding]::ASCII
    $byteSyslogMessage = $encoding.getbytes(''+$syslogoutputclean+'')
    $UDPClient.send($byteSyslogMessage, $byteSyslogMessage.length)

    }

}