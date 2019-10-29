
$vm = Get-VM -Name "WXEROXtest10010"

$cdDrive = Get-CDDrive -VM $vm

Set-CDDrive -CD $cdDrive -IsoPath "[DAL_NFS_EMC_SAS_NREPL_ISO_003]/Test567890123456789.iso" -StartConnected:$true -Connected:$true -Confirm:$false


