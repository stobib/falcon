﻿Clear-Host;Clear-History
$Global:Validate=$null
$Global:Domain=("utshare.local")
$Global:DomainUser=(($env:USERNAME+"@"+$Domain).ToLower())
$Global:DnsServer=("dca01."+$Domain)
$ScriptPath=$MyInvocation.MyCommand.Definition
$ScriptName=$MyInvocation.MyCommand.Name
Set-Location ($ScriptPath.Replace($ScriptName,""))
Set-Variable -Name DateTime -Value (Get-Date)
Set-Variable -Name SecureCredentials -Value $null
Set-Variable -Name vSphere -Value ("vcmgr01a.inf."+$Domain)
Set-Variable -Name LogFile -Value ($ScriptName.Replace("ps1","log"))
Set-Variable -Name LogFile -Value ($env:USERPROFILE+"\Desktop\"+$LogFile)
Set-Variable -Name SendTo -Value ("GRP-SIS_SysAdmin@utsystem.edu")
Set-Variable -Name MailServer -Value ("mail.utshare.utsystem.edu")
Set-Variable -Name EndTime -Value $null
Set-Variable -Name Sender -Value $null
Function LoadModules(){
   ReportStartOfActivity "Searching for $ProductShortName module components..."
   $Loaded=Get-Module -Name $ModuleList -ErrorAction Ignore|% {$_.Name}
   $Registered=Get-Module -Name $ModuleList -ListAvailable -ErrorAction Ignore|% {$_.Name}
   $NotLoaded=$Registered|? {$Loaded -notcontains $_}
   ReportFinishedActivity
   Foreach($Module In $Registered){
      If($Loaded -notcontains $Module){
		 ReportStartOfActivity "Loading module $Module"
		 Import-Module $Module
		 ReportFinishedActivity
      }
   }
}
Function Protect-String{[CmdletBinding()]param([String][Parameter(Mandatory=$true)]$String,[String][Parameter(Mandatory=$true)]$Key)
    Begin{}
    Process{      
        If(([System.Text.Encoding]::Unicode).GetByteCount($Key)*8-notin128,192,256){
            Throw "Given encryption key has an invalid length.  The specified key must have a length of 128, 192, or 256 bits."
        }
        $SecureKey=ConvertTo-SecureString -String $Key -AsPlainText -Force
        Return ConvertTo-SecureString $String -AsPlainText -Force|ConvertFrom-SecureString -SecureKey $SecureKey
    }
    End{}
}
Function ReportStartOfActivity($Activity){
   $Script:CurrentActivity=$Activity
   Write-Progress -Activity $LoadingActivity -CurrentOperation $Script:CurrentActivity -PercentComplete $Script:PercentComplete
}
Function ReportFinishedActivity(){
   $Script:CompletedActivities++
   $Script:PercentComplete=(100.0/$TotalActivities)*$Script:CompletedActivities
   $Script:PercentComplete=[Math]::Min(99,$PercentComplete)
   Write-Progress -Activity $LoadingActivity -CurrentOperation $Script:CurrentActivity -PercentComplete $Script:PercentComplete
}
Function ResolveIPAddress{Param([String][Parameter(Mandatory=$true)]$IP="",[Parameter(Mandatory=$true)]$NetBIOS="",$Environment="")
    $ErrorActionPreference='ContinueSilently'
    Try{
        If($IP-eq"0.0.0.0"){
            $FQDN=($NetBIOS+"."+$Environment+"."+$Domain)
            $AddressList=([System.Net.Dns]::GetHostByName($FQDN).AddressList)
            $IP=$AddressList.IPAddressToString
            $1st=($IP.Split(".")[0]);$2nd=($IP.Split(".")[1]);$3rd=($IP.Split(".")[2]);$4th=($IP.Split(".")[3])
            $ZoneName=($3rd+"."+$2nd+"."+$1st+".in-addr.arpa")
            Add-DnsServerResourceRecordPtr -Name ($4th) -ZoneName $ZoneName -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
            Return $AddressList
        }Else{
            $FQDN=[System.Net.Dns]::GetHostByAddress($IP).HostName
            Return ($FQDN.ToLower())
        }
    }Catch{
        $1st=($IP.Split(".")[0]);$2nd=($IP.Split(".")[1]);$3rd=($IP.Split(".")[2]);$4th=($IP.Split(".")[3])
        $env=VerifyEnvironment -3rdOctate '$3rd'
        $FQDN=($NetBIOS+"."+$env+"."+$Domain).ToLower()
        If($_.Exception.Message-eq'Exception calling "GetHostByAddress" with "1" argument(s): "The requested name is valid, but no data of the requested type was found"'){
            Add-DnsServerResourceRecordPtr -Name ($4th) -ZoneName ($3rd+"."+$2nd+"."+$1st+".in-addr.arpa") -AllowUpdateAny -TimeToLive 01:00:00 -AgeRecord -PtrDomainName $FQDN
        }ElseIf($_.Exception.Message-eq'Exception calling "GetHostByName" with "1" argument(s): "No such host is known"'){
            Add-DnsServerResourceRecordA -Name $NetBIOS -ZoneName ($env+"."+$Domain).ToLower() -AllowUpdateAny -IPv4Address $IP -TimeToLive 01:00:00 -CreatePtr
        }Else{
            Write-Host $_.Exception.Message -ForegroundColor Green
        }
    }
}
Function SetCredentials{[CmdletBinding()]Param([String][Parameter(Mandatory=$true)]$SecureUser="",[String][Parameter(Mandatory=$true)]$Domain="")
    Set-Variable -Name WorkingPath -Value ($($env:USERProfile)+"\AppData\Local\Credentials\"+$($Domain))
    Set-Variable -Name SecureFile -Value ("$WorkingPath\"+$($SecureUser.Split("@")[0])+".pwd")
    If(Test-Path -Path $SecureFile){
        Set-Variable -Name Extensions -Value @("pwd","key")
        Set-Variable -Name KeyDate -Value $null
        Set-Variable -Name PwdDate -Value $null
        ForEach($FileType In $Extensions){
            $Results=Get-ChildItem -Path $WorkingPath
            $Extension=$($Results.Name).Split(".")[1]
            If($Extension-eq$FileType){
                $PwdDate=$($Results.CreationTime)[1]
                If($KeyDate.Date-ne$PwdDate.Date){
                    Set-Variable -Name SecureString -Value 0
                }Else{
                    $SecureString=Get-Content -Path $SecureFile|ConvertTo-SecureString -SecureKey $SecureKey -ErrorAction Stop
                    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
                    $Validate=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                }
            }Else{
                $KeyDate=$($Results.CreationTime)[0]
                $KeyName=$($Results.Name).Split(".")[0]
                If(([System.Text.Encoding]::Unicode).GetByteCount($KeyName)*8-notin"128,192,256"){
                    $EncryptionKeyFile="$WorkingPath\$KeyName.$Extension"
                    $SecureKey=ConvertTo-SecureString -String $KeyName -AsPlainText -Force
                    $PrivateKey=Get-Content -Path $EncryptionKeyFile|ConvertTo-SecureString -SecureKey $SecureKey
                    $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivateKey)
                    $UnEncrypted=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                }
            }
        }
    }Else{
        $SecureString=Read-Host -Prompt "Enter your [$SecureUser] credentials" -AsSecureString
        $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $Encrypted=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        Set-Variable -Name "EncryptionKeyFile" -Value ""
        Set-Variable -Name "Characters" -Value ""
        Set-Variable -Name "PrivateKey" -Value ""
        Set-Variable -Name "SecureKey" -Value ""
        [String]$Key=0
        [Int]$Min=8
        [Int]$Max=1024
        $Prompt="Enter the length you want to use for the security key: [8, 12, or 16]"
        If($Prompt.Length-eq0){$Prompt=8}
        [Int]$RandomKey=Read-Host -Prompt $Prompt
        If(Test-Path $WorkingPath){
            $Results=Get-ChildItem -Path $WorkingPath -File
            ForEach($File In $Results){
                $FileName=$($File.Name).Split(".")[0]
                If($FileName.length-eq$RandomKey){
                    $KeyFile="$($File.Name)"
                    $Key=$($KeyFile).Split(".")[0]
                    If(([System.Text.Encoding]::Unicode).GetByteCount($Key)*8-notin"128,192,256"){
                        $EncryptionKeyFile="$WorkingPath\$KeyFile"
                        $SecureKey=ConvertTo-SecureString -String $Key -AsPlainText -Force
                        $PrivateKey=Get-Content -Path $EncryptionKeyFile|ConvertTo-SecureString -SecureKey $SecureKey
                        $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivateKey)
                        $UnEncrypted=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                        Break
                    }
                }
            }
        }Else{
            $Dir=MkDir $WorkingPath
        }
        If($PrivateKey.length-lt1){
            Do{
                Switch($RandomKey){
                    {($_-eq8)}{
                        $Key=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        Break
                    }
                    {($_-eq12)}{
                        $Key=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        Break
                    }
                    {($_-eq16)}{
                        $Key=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        $Key+=-join((48..57)|Get-Random -Count 4|%{[char]$_})
                        Break
                    }
                    {($Key.length-lt$RandomKey)}{
                        $RandomKey+=1
                        Break
                    }
                    {($Key.length-gt$RandomKey)}{
                        $RandomKey-=1
                        Break
                    }
                    Default{
                        $RandomKey=16
                        Break
                    }
                }
            }Until(($Key.length-eq8)-or($Key.length-eq12)-or($Key.length-eq16))
            $i=0
            Do{
                $i++
                If(Test-Path -Path $SecureFile){
                    $SecureFile="$WorkingPath\Encrypted$i.pwd"
                }
            }While((Test-Path -Path $SecureFile)-eq$true)
            $Prompt="Enter the amount of characters you want to use for the encryption key: [min $Min, max $Max]"
            Do{
                [Int]$Characters=Read-Host -Prompt $Prompt
                If(($Characters-ge$Min)-and($Characters-le$Max)){
                }Else{
                    $Prompt="Please enter a value between the minimum '$Min' and maximum '$Max' range"
                }
            }Until(($Characters-ge$Min)-and($Characters-le$Max))
            For($i=0;$i-le$Characters;$i++){
                Switch($i){
                    {($_-gt0)-and($_-le$Characters)}{$Set=-join((65..90)+(97..122)|Get-Random -Count 1|%{[Char]$_});Break}
                    Default{$PrivateKey="";$Set="";Break}
                }
                $PrivateKey+=$Set
            }
            Set-Variable -Name "EncryptionKeyFile" -Value "$WorkingPath\$Key.key"
            Protect-String $PrivateKey $Key|Out-File -Filepath $EncryptionKeyFile
            $Validate=Unprotect-String $PrivateKey $Key
            If($Validate-ne$false){
                $SecureKey=ConvertTo-SecureString -String $Key -AsPlainText -Force
            }Else{
                $SecureString=Read-Host -Prompt "Enter your [$SecureUser] credentials" -AsSecureString
            }
            $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            $EncryptedString=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            $EncryptedString|ConvertTo-SecureString -AsPlainText -Force|ConvertFrom-SecureString -SecureKey $SecureKey|Out-File -FilePath $SecureFile
        }
        Try{
            $SecureString=Get-Content -Path $SecureFile|ConvertTo-SecureString -SecureKey $SecureKey -ErrorAction Stop
            $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            $Validate=[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            If($EncryptedString-ceq$Validate){}
        }Catch [Exception]{
            $Message="Error: [Validation]: $($_.Exception.Message)";Write-Host $Message -ForegroundColor Yellow -BackgroundColor DarkRed
            $EncryptedString=$null;$BSTR=$null
        }
    }
    $EncryptedString=$null;$BSTR=$null
    $Script:SecureCredentials=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $SecureUser,$SecureString
    Return $Validate
}
Function Unprotect-String{[CmdletBinding()]param([String][Parameter(Mandatory=$true)]$String,[String][Parameter(Mandatory=$true)]$Key)
    Begin{}
    Process{
        If(([System.Text.Encoding]::Unicode).GetByteCount($Key)*8-notin128,192,256){
            Throw "Given encryption key has an invalid length.  The specified key must have a length of 128, 192, or 256 bits."
            Return $false
        }
        $SecureKey=ConvertTo-SecureString -String $Key -AsPlainText -Force
        $PrivateKey=Get-Content -Path $EncryptionKeyFile|ConvertTo-SecureString -SecureKey $SecureKey
        $BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PrivateKey)
        Return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    End{}
}
Function VerifyEnvironment{Param([String][Parameter(Mandatory=$true)]$3rdOctate="")
    $SubDomain=$null
    Switch($3rdOctate){
        {($_-ge4-and$_-le7)-or($_-ge20-and$_-le23)-or($_-ge36-and$_-le39)-or($_-ge52-and$_-le55)-or($_-ge68-and$_-le712)-or($_-ge84-and$_-le87)}{$SubDomain="prd";Break}
        {($_-eq10)-or($_-eq26)-or($_-eq42)-or($_-eq58)-or($_-eq74)-or($_-eq90)}{$SubDomain="trn";Break}
        {($_-eq11)-or($_-eq27)-or($_-eq43)-or($_-eq59)-or($_-eq75)-or($_-eq91)}{$SubDomain="sbx";Break}
        {($_-eq12)-or($_-eq28)-or($_-eq44)-or($_-eq60)-or($_-eq76)-or($_-eq92)}{$SubDomain="tst";Break}
        {($_-eq13)-or($_-eq29)-or($_-eq45)-or($_-eq61)-or($_-eq77)-or($_-eq93)}{$SubDomain="dev";Break}
        {($_-eq14)-or($_-eq30)-or($_-eq46)-or($_-eq62)-or($_-eq78)-or($_-eq94)}{$SubDomain="dmo";Break}
        {($_-eq8)-or($_-eq24)-or($_-eq40)-or($_-eq56)-or($_-eq72)-or($_-eq88)}{$SubDomain="uat";Break}
        {($_-eq9)-or($_-eq25)-or($_-eq41)-or($_-eq57)-or($_-eq73)-or($_-eq89)}{$SubDomain="fly";Break}
        {($_-eq64)-or($_-eq65)}{$SubDomain="bkp";Break}
        {($_-eq18)-or($_-eq19)}{$SubDomain="vdi";Break}
        {($_-eq0)-or($_-eq1)}{$SubDomain="inf";Break}
        {($_-eq2)}{$SubDomain="mgt";Break}
        Default{$SubDomain="all";Break}
    }Return $SubDomain
}
Switch($DomainUser){
    {($_-like"sy10*")-or($_-like"sy60*")}{Break}
    Default{$DomainUser=(("sy1000829946@"+$Domain).ToLower());Break}
}
$Validate=SetCredentials -SecureUser $DomainUser -Domain ($Domain).Split(".")[0]
If($SecureCredentials-eq$null){$SecureCredentials=get-credential};$Validate=$null

#Load PowerCli Context
$Script:PromptForCEIP=$false
$ModuleList=@(
    "VMware.VimAutomation.Core",
    "VMware.VimAutomation.Vds",
    "VMware.VimAutomation.Cloud",
    "VMware.VimAutomation.PCloud",
    "VMware.VimAutomation.Cis.Core",
    "VMware.VimAutomation.Storage",
    "VMware.VimAutomation.HorizonView",
    "VMware.VimAutomation.HA",
    "VMware.VimAutomation.vROps",
    "VMware.VumAutomation",
    "VMware.DeployAutomation",
    "VMware.ImageBuilder",
    "VMware.VimAutomation.License"
)
$ProductName="PowerCli"
$ProductShortName="PowerCli"
$LoadingActivity="Loading $ProductName"
$Script:CompletedActivities=0
$Script:PercentComplete=0
$Script:CurrentActivity=""
$Script:totalActivities=$ModuleList.Count+1
LoadModules
$PowerCliFriendlyVersion=[VMware.VimAutomation.Sdk.Util10.ProductInfo]::PowerCliFriendlyVersion
$Host.ui.RawUI.WindowTitle=$PowerCliFriendlyVersion
Try{
	$configuration=Get-PowerCliConfiguration -Scope Session
	If($PromptForCEIP-and$configuration.ParticipateInCEIP-eq$null-and[VMware.VimAutomation.Sdk.Util10Ps.CommonUtil]::InInteractiveMode($Host.UI)){
		$caption="Participate in VMware Customer Experience Improvement Program (CEIP)"
		$message=`
			"VMware's Customer Experience Improvement Program (`"CEIP`") provides VMware with information "+
			"that enables VMware to improve its Products and services, to fix problems, and to advise you "+
			"on how best to deploy and use our Products.  As part of the CEIP, VMware collects technical information "+
			"about your organization’s use of VMware Products and services on a regular basis in association "+
			"with your organization’s VMware license key(s).  This information does not personally identify "+
			"any individual."+
			"`n`nFor more details: press Ctrl+C to exit this prompt and type `"help about_ceip`" to see the related help article."+
			"`n`nYou can join or leave the program at any time by executing: Set-PowerCliConfiguration -Scope User -ParticipateInCEIP `$true or `$false."
		$AcceptLabel="&Join"
		$choices=(
			(New-Object -TypeName "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $AcceptLabel,"Participate in the CEIP"),
			(New-Object -TypeName "System.Management.Automation.Host.ChoiceDescription" -ArgumentList "&Leave","Don't participate")
		)
		$userChoiceIndex = $Host.UI.PromptForChoice($caption, $message, $choices, 0)
		$participate = $choices[$userChoiceIndex].Label -eq $AcceptLabel
		If($participate){
            [VMware.VimAutomation.Sdk.Interop.V1.CoreServiceFactory]::CoreService.CeipService.JoinCeipProgram();
        }Else{
            Set-PowerCliConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false | Out-Null
        }
    }
}Catch{}
Write-Progress -Activity $LoadingActivity -Completed

#Connect vSphere
$Validate=Connect-VIServer -Server $vSphere -credential $SecureCredentials;Clear
If($Validate-ne$null){
    If(!(Test-Path -Path ($env:USERPROFILE+"\Desktop\ServerList.txt"))){
        (Get-VM).Name|Sort|Out-File ($env:USERPROFILE+"\Desktop\ServerList.txt")
    }
    If(Test-Path -Path $LogFile){Remove-Item $LogFile -ErrorAction SilentlyContinue}
    #Health Check
    Foreach($Server In [System.IO.File]::ReadLines($env:USERPROFILE+"\Desktop\ServerList.txt")){
        $Bypass=$true
        $NetBIOS=$null
        $VMStatus=$null
        $HostName=$null
        $SubDomain="inf"
        $IPAddress=$null
        $ServerName=$null
        $FolderName=$null
        $DateTime=Get-Date
        $PowerState="PoweredOff"
        $IPAddressToString=$null
        If($Server-like"*.*"){
            $Server=(($Server).Split(("."))[0])
        }
        $Sender=($Server+"@utsystem.edu")
        $VMStatus=Get-VM|Where-Object{$_.Name-like($Server+"*")}|Select *
        If($VMStatus-ne$null){
            $Hostname=$VMStatus.Name
            $PowerState=$VMStatus.PowerState
            $FolderName=($VMStatus.Folder).Name
            If($FolderName-eq"UTD IaaS (Root)"){
                $Reason=("host VM is not being managed by our team")
            }Else{
                If(($PowerState-eq"PoweredOn")-and($PowerState-ne$null)){
                    If($Hostname-like"*.*"){
                        $NetBIOS=($Hostname.Split(".")[0])
                        $SubDomain=($Hostname.Split(".")[1])
                    }Else{
                        $NetBIOS=$Hostname
                    }
                    $ErrorActionPreference='Continue'
                    Try{
                        $IPAddressToString=([System.Net.Dns]::GetHostByName($NetBIOS).AddressList).IPAddressToString
                    }Catch{
                        $IPAddressToString=(ResolveIPAddress -IP "0.0.0.0" -NetBIOS $NetBIOS -Environment $SubDomain).IPAddressToString
                    }
                    If($IPAddressToString-ne$null){
                        ForEach($IP In $IPAddressToString){
                            If(($IP-ne$null)-and($IP.Split(".")[0]-eq"10")-and{($IP.Split(".")[1]-eq"118")-or($IP.Split(".")[1]-eq"126")}){
                                $ServerName=ResolveIPAddress -IP $IP -NetBIOS $NetBIOS -Environment $SubDomain
                                If($ServerName-ne$null){
                                    $Bypass=$false
                                }Else{
                                    $Bypass=$true
                                }
                            }Else{
                                $Reason=("host VM has an invalid IP Address: ["+$IP+"]")
                            }
                        }
                    }Else{
                        $Reason=("host VM isn't registered in DNS")
                    }
                }Else{
                    $Reason=("host VM is currently powered off")
                }
            }
        }
        Write-Host ("Currently working on hostname(VM): '"+$Hostname+"' and is currently: "+$PowerState)
        If(($PowerState-eq"PoweredOn")-and($Bypass-eq$false)){
            ("Currently working on hostname(VM): ["+$Hostname+"] and is currently: powered on.")|Out-File $LogFile -Append
            If(Test-Connection -ComputerName $ServerName -Count 3 -BufferSize 256 -ThrottleLimit 32){
                (“`tTesting connection to $ServerName is successful”)|Out-File $LogFile -Append
#                Send-MailMessage -From "<$($Sender)>" -To "GRP-SIS_SysAdmin <$($SendTo)>" -Subject ($ServerName+" is responding") -Body ($ServerName+" is responding again.") -SmtpServer $MailServer
            }Else{
                $EndTime=Get-Date
                "Connection Failed `t`t"+$DateTime.DateTime+"`t`t"+($EndTime–$DateTime).TotalSeconds+" seconds"|Out-File $LogFile -Append
#                Send-MailMessage -From "<$($Sender)>" -To "GRP-SIS_SysAdmin <$($SendTo)>" -Subject ($ServerName+" not responding") -Body ($ServerName+" not responding, waiting 10 seconds and will try again.") -SmtpServer $MailServer
                "Waiting 10 seconds"
                Start-Sleep 10
                If(!(Test-Connection -ComputerName $ServerName -Count 3 -BufferSize 256 -ThrottleLimit 32)){
                    $EndTime=Get-Date
                    "Connection Failed `t`t"+$DateTime.DateTime+"`t`t"+($EndTime–$DateTime).TotalSeconds+" seconds"|Out-File $LogFile -Append
#                    (Get-VM -Name $Hostname).ExtensionData.ResetVM() 
#                    Send-MailMessage -From "<$($Sender)>" -To "GRP-SIS_SysAdmin <$($SendTo)>" -Subject ("Server: '"+$ServerName+"' crashed!") -Body ($ServerName+" must have crashed and was reset.") -SmtpServer $MailServer
                    Start-Sleep 30
                }Else{
                    $EndTime=Get-Date
                    “Successful `t`t"+$DateTime.DateTime+"`t`t"+($EndTime–$DateTime).TotalSeconds+" seconds"|Out-File $LogFile -Append
#                    Send-MailMessage -From "<$($Sender)>" -To "GRP-SIS_SysAdmin <$($SendTo)>" -Subject ($ServerName+" is responding") -Body ($ServerName+" is responding again and was not reset.") -SmtpServer $MailServer
                }
            }
        }Else{
            ("Bypassing ["+$Server+"] because "+$Reason+".")|Out-File $LogFile -Append
        }
        ("----------------------------------------------------------------------------------------------------")|Out-File $LogFile -Append
    }
}
Rename-Item -Path ($env:USERPROFILE+"\Desktop\ServerList.txt") -NewName "ProcessedList.txt" -Force
Set-Location ($env:SystemRoot+"\System32")