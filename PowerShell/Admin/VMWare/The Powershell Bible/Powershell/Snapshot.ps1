Add-PSSnapin VMWare.VIMAutomation.Core
Connect-VIServer -server 172.26.116.82 -user sa_dev_tidal -password Aec@dallas

$vmname = "WXEROXTEST000022-MJS"
$action = "CR_SNAPSHOT"

function DeleteAecSnap {
    $list = Get-snapshot -VM $vmname | select name 
    if ($list -ne $null) {
        foreach ($l in $list) {
        $name = $l.name
        $delText = "Delete Snapshot: " + $name 
        $vmtext = "VM: " + $vmname
        echo $delText
        echo $vmText
            if ($name -match $vmname) {
                Get-Snapshot -vm $vmname -name $name | Remove-Snapshot -confirm:$false
            }
        }
    }
}
    

if ($action -like "RM_SNAPSHOT") {
    DeleteAecSnap
    }

If ($action -like "CR_SNAPSHOT") {
    $currDate = Get-Date
    DeleteAecSnap
    $newSnapName = $vmname + "_" + $currDate.Month + "-" + $currDate.Day + "-" + $currDate.Year + "_" + $currDate.Hour + ":" + $currDate.Minute + ":" +  $currDate.Second
    new-snapshot -vm $vmname -name $newSnapName 
    $crText = "Create Snapshot: " + $newSnapName
    $vmtext = "VM: " + $vmname
    echo $crtext
    }

DisConnect-VIServer -Confirm:$false
