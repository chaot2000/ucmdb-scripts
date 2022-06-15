########################################################
# Name: verify_ucmdb_3rd_party_files_v1.ps1
# Creator: Sven Jakob             
# CreationDate: 02.05.2021
# LastModified: 27.05.2021                               
# Version: 1.1
# PSVersion tested: 5
#
# Description:
# Verify files for 3rd Party SDK from UCMDB
# in the defined folders.
#
# VMWare file(s):       vim.jar, vim25.jar
# CyberArk file(s):     JavaPasswordSDK.jar
# Oracle file(s):       ojdbc6.jar, orai18n.jar
# SAP files(s):         sapjco3.jar, sapjco3.dll
#
# TODO
# - Schalter für einzelne Prüfungen z.B. soll VM-Ware geprüft werden? 
# 
#
# Change History
# 2022-05-27    SJA     added support for SAP Files
#
#
#
#
########################################################

#
#Variables, only Change here
#

#Logging
$logPath = "e:\logs"
$LogfileName = "verify_3rd_party_files" #Log Name
$LoggingLevel = "3" #LoggingLevel only for Output in Powershell Window, 1=smart, 3=Heavy

# for CyberArk
#$ccp_path = "C:\Program Files (x86)\CyberArk\"
$ccp_file_sdk = "JavaPasswordSDK.jar"

#for Oracle
$ora_file_jdbc6 = "ojdbc6.jar"
$ora_file_jdbc18 = "orai18n.jar"

#for VMWare
$vmware_vim = "vim.jar"
$vmware_vim25 = "vim25.jar"

# for SAÜ
$sap_jco3jar = "sapjco3.jar"
$sap_jco3dll = "sapjco3.dll"


#
# region functions
#

# au2matorLog
function Write-au2matorLog {
    [CmdletBinding()]
    param
    (
        [ValidateSet('DEBUG', 'INFO', 'WARNING', 'ERROR')]
        [string]$Type,
        [string]$Text
    )
       
    # Set logging path
    if (!(Test-Path -Path $logPath)) {
        try {
            $null = New-Item -Path $logPath -ItemType Directory
            Write-Verbose ("Path: ""{0}"" was created." -f $logPath)
        }
        catch {
            Write-Verbose ("Path: ""{0}"" couldn't be created." -f $logPath)
        }
    }
    else {
        Write-Verbose ("Path: ""{0}"" already exists." -f $logPath)
    }
    [string]$logFile = '{0}\{1}_{2}.log' -f $logPath, $(Get-Date -Format 'yyyyMMdd'), $LogfileName
    $logEntry = '{0}: <{1}> <{2}> {3}' -f $(Get-Date -Format dd.MM.yyyy-HH:mm:ss), $Type, $PID, $Text
    
    try { Add-Content -Path $logFile -Value $logEntry }
    catch {
        Start-sleep -Milliseconds 50
        Add-Content -Path $logFile -Value $logEntry
    }
    if ($LoggingLevel -eq "3") { Write-Host $Text }
    
    
}

#endregion Functions
#clearing
$error.Clear()
#SCRIPT

#verify DFP-Path
try {
    #get ucmdb dataflow path
    $ucmdb_dfp = Get-Process -Name "discovery_probe" | Select-Object -Property Path
    $product = Get-Process -Name "discovery_probe" | Select-Object -Property Product
    $ucmdb_dfp = Split-Path -Path $ucmdb_dfp.path -Parent
    $DriveLetter, $rest = $ucmdb_dfp.Split('\')
    $dfp_path = $DriveLetter + '\' + $rest[0] + '\'  + $rest[1]

    If (Test-Path -Path $dfp_path) {
        Write-au2matorLog -Type INFO -Text "DFP-Process Up and Running"
        Write-au2matorLog -Type INFO -Text "DFP-Path: $dfp_path"
    }
}
catch {
    Write-au2matorLog -Type ERROR -Text "DFP-Process not found. Please start the probe and try again. Script ended."
    Write-au2matorLog -Type ERROR -Text "$error[0].CategoryInfo"
    Break
}


#verify CCP-Path

try {
    #get ucmdb dataflow path
    $cybAppProv = Get-Process -Name "AppProvider" | Select-Object -Property Path
    $cybAppProv = Split-Path -Path $cybAppProv.path -Parent
    $DriveLetter, $rest = $cybAppProv.Split('\')
    $cybAppProv_path = $DriveLetter + '\' + $rest[0] + '\'  + $rest[1]

    If (Test-Path -Path $cybAppProv_path) {
        Write-au2matorLog -Type INFO -Text "[OK]  CyberArk Application Password Provider up and running"
        Write-au2matorLog -Type INFO -Text "      AppProvider-Path: $cybAppProv_path"
    }
}
catch {
    Write-au2matorLog -Type WARNING -Text "[NOK] CyberArk Application Password Provider is not running "
    Write-au2matorLog -Type WARNING -Text "$error[0].CategoryInfo"
    Break
}

# If (Test-Path -Path $ccp_path)
#     {
#         Write-au2matorLog -Type INFO -Text "[OK]  CyberArk Application Password Provider is installed in $($ccp_path)."

#     } else {
#         Write-au2matorLog -Type WARNING -Text "[NOK] CyberArk Application Password Provider is not installed."
# #        Write-au2matorLog -Type ERROR -Text "$error[0].CategoryInfo"
#     }

# define ucmdb folders for 3rd party integration files
$path_ucmdb_vmware = "$dfp_path\runtime\probeManager\discoveryResources\vmware"
$path_ucmdb_cyberark = "$dfp_path\lib"
$path_ucmdb_oracle ="$dfp_path\runtime\probeManager\discoveryResources\db\oracle"
$path_ucmdb_sap =  "$dfp_path\content\lib\sap"
$ccp_file_ucmdb = "$path_ucmdb_cyberark\$ccp_file_sdk"


# set CyberArk Application Password Provider  sdk files to be testing
If (Test-Path -Path $ccp_file_ucmdb)
    {
     
        Write-au2matorLog -Type INFO -Text "[OK]  CyberArk Application Password Provider SDK found: $($ccp_file_ucmdb)"

    } else {
        Write-au2matorLog -Type WARNING -Text "[NOK]  CyberArk Application Password Provider not found: $($ccp_file_ucmdb)"
    }

# set files to be testing
$files = @("$path_ucmdb_vmware\$vmware_vim","$path_ucmdb_vmware\$vmware_vim25", "$path_ucmdb_oracle\$ora_file_jdbc6", "$path_ucmdb_oracle\$ora_file_jdbc18", "$path_ucmdb_sap\$sap_jco3jar", "$path_ucmdb_sap\$sap_jco3dll")

foreach ($file in $files) {
    If (Test-Path $file) {
        Write-au2matorLog -Type INFO -Text "[OK]  File found: $($file)"
    }
    else {
        Write-au2matorLog -Type WARNING -Text "[NOK] File not found: $($file)"
    }
            
}