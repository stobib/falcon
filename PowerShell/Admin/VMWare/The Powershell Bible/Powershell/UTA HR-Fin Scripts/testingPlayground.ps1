#Add-PSSnapin VMware.VimAutomation.Core
#Connect-VIServer -server vc-manager-ardc.shared.utsystem.edu 


#$esxcli = Get-EsxCli -VMHost vmware-32.support.shared.utsystem.edu


$date = "march"
$Computer = "fantastic"
$Destination = "graveyard"

$details = @{            
                Date             = $date              
                ComputerName     = $Computer                 
                Destination      = $Destination 
}                           


$results += New-Object PSObject -Property $details  

$results | export-csv -Path c:\example\so.csv -NoTypeInformation

#$esxcli = get-vmhost -name vmware-32.support.shared.utsystem.edu | %{(Get-View $_.ID).Config.Product}


#$FullName = $esxcli.FullName

#Write-Host "This is FullName:" $FullName

#| Get-View |select @{E={$_.Config.Product.FullName}}


#Write-Host  $hostbuild


#$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString

<#

#Build dynamic variable
$numofFreePortsWEB = "0"

$userSelectZone = "WEB"

$dynamicUserZone = Get-Variable "numofFreePorts$userselectZone"


if ($dynamicUserZone.value -gt 0 ){
    Write-Host "I'm a boss!"
}

#>



#$portgroup = "dvpg_0265_Nike"
#$vswitch = "aecdevvs01"

#$portgroup = Get-VirtualPortGroup -VirtualSwitch $vswitch -Name $portgroup
#$portgroup | Format-List *

#$vm = Get-VM -Name WXEROXtest10010
#$vm |select Path

#$vm =  "WSCTPG000055969"
#Get-VM -Name $vm

#$cdDrive = Get-CDDrive -VM $vm

#$args5 = "Post Provision Scripts.iso"

#$args4 = "DAL_NFS_EMC_SAS_NREPL_ISO_003"

#$test="[$args4]/$args5"

#$test

#Set-CDDrive -CD $cdDrive -IsoPath $test -StartConnected:$true -Connected:$true -Confirm:$false


#Set-CDDrive -CD $cdDrive -IsoPath "[$args4]/$args5" -StartConnected:$true -Connected:$true -Confirm:$false

#Set-CDDrive -CD $cdDrive -IsoPath "[$args[4]]/$args[5]" -StartConnected:$true -Connected:$true -Confirm:$false

#Set-CDDrive -CD $cdDrive -IsoPath "[DAL_NFS_EMC_SAS_NREPL_ISO_003]/Post Provision Scripts.iso" -StartConnected:$true -Connected:$true -Confirm:$false

#Disconnect-VIServer $args[0] -confirm:$false

#-->
#$args[0] = "0.27,1.66,4.6,5.57"
#$args[1] = "GigabitEthernet0"

#$val = $args[0].split(",")
#$len = $val.length

#$final_string = ""

#for($i=0; $i  -le $len - 1 ; $i++)
#{
#$add_string = "allocate-interface " + $args[1] + "/" + $val[$i] + "`n"
#$final_string = $final_string + $add_string
#}

#$final_string
##


#[string]$Computer = $env:computername
#if ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer -ea 0).OSArchitecture -eq '64-bit') {            
#    $architecture = "64-Bit"            
#   } else  {            
#    $architecture = "32-Bit"            
#   }    
#$architecture 

#param([string]$installmeth,[string]$userInput)

#$stringArray=$userInput.split(",")

#$stringArray[1]