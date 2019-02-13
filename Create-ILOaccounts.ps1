Param ( [string]$OVApplianceIP  ="",
        [string]$OVAdminName    ="Administrator", 
        [string]$OVAdminPassword="password",
        [string]$OneViewModule  = "HPOneView.410",  
        [string]$OVAuthDomain   = "local",

        [string]$iLOuserName    = 'iLO-Amp-user',
        [string]$iLOPassword    = '',

        [string]$iLOServersCSV  = "iLOservers.csv"

)
#$ErrorActionPreference = 'SilentlyContinue'
$DoubleQuote    = '"'
$CRLF           = "`r`n"
$Delimiter      = "\"   # Delimiter for CSV profile file
$SepHash        = ";"   # USe for multiple values fields
$Sep            = ";"
$hash           = '@'
$SepChar        = '|'
$CRLF           = "`r`n"
$OpenDelim      = "{"
$CloseDelim     = "}" 
$CR             = "`n"
$Comma          = ','
$Equal          = '='
$Dot            = '.'
$Underscore     = '_'

$Syn12K                   = 'SY12000' # Synergy enclosure type

Function Prepare-OutFile ([string]$Outfile)
{

    $filename   = $outFile.Split($Delimiter)[-1]
    $ovObject   = $filename.Split($Dot)[0] 
    
    New-Item $OutFile -ItemType file -Force -ErrorAction Stop | Out-Null


    Set-content -path $outFile -Value $HeaderText
}


Function Out-ToScriptFile ([string]$Outfile)
{
    if ($ScriptCode)
    {
        Prepare-OutFile -outfile $OutFile
        
        Add-Content -Path $OutFile -Value $ScriptCode
        

    } else 
    {
        Write-Host -ForegroundColor Yellow " No $ovObject found. Skip generating script..."
    }
}

import-module HPOneView.410
import-module HPRESTCmdlets         # HPRESTcmdlets in on PowerShell gallery
# ----------------------------------------
# Import HPREdFish Cmdlets module
#import-module HPERedFishCmdlets



# ---------------- Connect to OneView appliance
#
write-host -ForegroundColor Cyan "-----------------------------------------------------"
write-host -ForegroundColor Cyan "Connect to the OneView appliance..."
write-host -ForegroundColor Cyan "-----------------------------------------------------"
Connect-HPOVMgmt -appliance $OVApplianceIP -user $OVAdminName -password $OVAdminPassword -LoginAcknowledge:$true -AuthLoginDomain $OVAuthDomain

# ---------------------------
#  Generate Output files

    $timeStamp          = get-date -format MMM-dd-yyyy
    
    $OutFile            = $iLOServersCSV

    $scriptCode             =  New-Object System.Collections.ArrayList
# ---------------------------
# Configure user account

$iLOloginName               = $iLOuserName
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



$ListofServers                          =  Get-HPOVServer 

foreach ($s in $ListofServers)
{
    $name               = $s.name
    $mpInfo             = $s.mphostInfo.mpIpAddresses | where type -ne LinkLocal
    $iloIP              = $mpInfo.address
    $iLOmodel           = $s.mpModel
        $isILO5         = $iLOModel -eq 'ILO5' 

    [void]$scriptCode.Add("$iloIP,$iLOuserName,$iLOPassword")

    $priv = @{}

    $priv.Add('RemoteConsolePriv',$RemoteConsolePriv)
    $priv.Add('iLOConfigPriv',$iLOConfigPriv)
    $priv.Add('VirtualMediaPriv',$VirtualMediaPriv)
    $priv.Add('UserConfigPriv',$UserConfigPriv)
    $priv.Add('VirtualPowerAndResetPriv',$VirtualPowerAndResetPriv)

    if ($isILO5)
    {
        # Only iLO5
        $priv.Add('HostBIOSConfigPriv',$HostBIOSConfigPriv)
        $priv.Add('HostNICConfigPriv',$HostNICConfigPriv)
        $priv.Add('HostStorageConfigPriv',$HostStorageConfigPriv)
        $priv.Add('SystemRecoveryConfigPriv',$SystemRecoveryConfigPriv)
        $priv.Add('LoginPriv',$loginpriv)

        # RedFish
        $hpe = @{}
        $hpe.Add('LoginName',$iLOLoginName)
        $hpe.Add('Privileges',$priv)
        $oem = @{}
        $oem.Add('Hpe',$hpe)

    }
    else 
    {
        $hp = @{}
        $hp.Add('LoginName',$iLOLoginName)
        $hp.Add('Privileges',$priv)
        $oem = @{}
        $oem.Add('Hp',$hp)
    }


    # add username and password for access
    $user = @{}
    $user.Add('UserName',$iLOUserName)
    $user.Add('Password',$iLOPassword)
    $user.Add('Oem',$oem)

    write-host -foreground CYAN "Connect to iLO of server $name.... "

    $iloSession         = $s | Get-HPOVIloSso -IloRestSession

    write-host -ForegroundColor Cyan "-----------------------------------------------------"
    write-host -ForegroundColor Cyan "Creating account $iLOusername on ILO $iLOIP.... "
    write-host -ForegroundColor Cyan "-----------------------------------------------------"

    
    $accData            = Get-HPRESTDataRaw -Href 'rest/v1/AccountService' -Session $ilosession
    if ($isILO5)
    {
        $accUri         = $accData.accounts.'@odata.id'
    }
    else 
    {
        $accURI         = $accData.links.Accounts.href    
    }    

    $ret                = Invoke-HPRESTAction -Href $accURI -Data $user -Session $ilosession

    # $iloSession.rootUri = $iloSession.rootUri -replace 'rest', 'Redfish'
    #$ret = Invoke-HPERedfishAction -Odataid $accUri -Data $user -Session $iloSession -DisableCertificateAuthentication

    
}

$scriptCode = $scriptCode.ToArray() 
Out-ToScriptFile -Outfile $outFile 
write-host "CSV file is created to be imported in iLO Amplifier --> $outFile"
Disconnect-HPOVMgmt



