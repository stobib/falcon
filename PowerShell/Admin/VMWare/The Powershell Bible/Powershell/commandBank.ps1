Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server 172.26.116.82 -Protocol https -User sa_dev_tidal -Password Aec@dallas

$l=Get-VM -Name V-T-L-RHEL-5-64-NULL $l|select Folder