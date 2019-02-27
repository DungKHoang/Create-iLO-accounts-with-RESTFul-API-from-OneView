# Create iLO accounts from OneView

The script creates iLO accounts from OneView leveraging the single-sign-on experiencc and RESTful API

## Prerequisites
The  script requires":
   * the latest OneView PowerShell library : https://github.com/HewlettPackard/POSH-HPOneView/releases
   * HPiloREST cmdlets found on PowerShell gallery. 

## Environment

Your OneView environment should be at least at 4.00 level.
The script works only against iLO4 v2.x and iLO5 ( for Gen 10)
The privileges for iLO accounts are admin privileges but you can turn on/off privileges by modifying values in the script

```
# iLO4 privs
$RemoteConsolePriv          = $true
$iLOConfigPriv              = $true
$UserConfigPriv             = $true
$VirtualMediaPriv           = $true
$VirtualPowerAndResetPriv   = $true
# Addtional privs with iLO5
$LoginPriv                  = $true
$HostBIOSConfigPriv         = $true
$HostNICConfigPriv          = $true
$HostStorageConfigPriv      = $true
$SystemRecoveryConfigPriv   = $false

```

Finally , the script generates a CSV file that can be imported to iLO Amplifier


## Syntax

### To create iloAccounts

```
    .\Create-iLOaccounts.ps1 -OVApplianceIP <OV-IP-Address> -OVAdminName <Admin-name> -OVAdminPassword <password> -iLOusername <name> -iLOPassword <password>

```

