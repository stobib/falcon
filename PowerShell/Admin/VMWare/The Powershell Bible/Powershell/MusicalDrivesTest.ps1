$drives = Get-WmiObject win32_volume | where {$_.driveletter -notlike "c:"}


ForEach ($D in $drives) {
    $label = $D.label
    if ($label -like "") {
    Set-WmiInstance -inputObject $D -arguments @{driveletter="J:"}
    }
}

