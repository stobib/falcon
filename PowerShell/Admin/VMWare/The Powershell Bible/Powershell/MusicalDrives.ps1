#Gets all drives other than the C drive
$drives = Get-WmiObject win32_volume | where {$_.driveletter -notlike "c:"}

#Moves specific drive letters to the end of the alphabet
ForEach ($D in $drives) {
    $label = $D.label

    #IMPORTANT!!!! RENAME "Post Provision S"(below) TO WHATEVER THE NAME OF THE MOUNTED ISO IS!!!!
    if ($label -like "Post Provision S") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="Z:"}
    }
    if ($label -like "data") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="Y:"}
    }
    if ($label -like "logs") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="X:"}
    }
    if ($label -like "temp") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="W:"}
    }
    if ($label -like "backup") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="V:"}
    }
    if ($label -like "System Recovery") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="U:"}
    } 
}
#Sets Delay for 
Start-Sleep -Second 10

#Gets all drives other than the C drive (with refreshed names)
$drives = Get-WmiObject win32_volume | where {$_.driveletter -notlike "c:"}

#Moves specific drive letters to the end of the alphabet
ForEach ($D in $drives) {
    $label = $D.label

    #IMPORTANT!!!! RENAME "Post Provision S"(below) TO WHATEVER THE NAME OF THE MOUNTED ISO IS!!!!
    if ($label -like "Post Provision S") {
    echo "Execute CD-Rom Final Move"
    Set-WmiInstance -inputObject $D -arguments @{driveletter="D:"}
    }
    if ($label -like "data") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="E:"}
    }
    if ($label -like "logs") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="F:"}
    }
    if ($label -like "temp") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="G:"}
    }
    if ($label -like "backup") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="H:"}
    }
    if ($label -like "System Recovery") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="I:"}
    } 
}