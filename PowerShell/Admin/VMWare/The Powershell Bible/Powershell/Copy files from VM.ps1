#Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server devdalvc00.dev.cloudcore.local -Protocol https -User sa_dev_tidal -Password Aec@dallas

$vm = Get-VM -Name "LT201301031338"

Copy-VMGuestFile -Source /root/Introscope9.1.2.0/wily/UninstallerData/ -Destination C:\VMtemp\uninstall\ -VM $vm -GuestToLocal -GuestUser root -GuestPassword novell123
