Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server [serverIP] -Protocol https -User [serverUser] -Password [serverPassword]


#Either enter short form text or a file that you want to send to a virtual machine
#Short form text you'd like to send to a virtual machine
[string]$text = ""

#File(full path) you would like to send to a virtual machine
$fileSource = "C:\Users\Grays\Documents\ACS\AMP 3\AMP 3.0\Powershell"

#Destination Location your file will be saved to on VM
$fileDest="C:\"

#Name of file your text will be saved to on VM(REQUIRED)
$fileName = "copiedText.txt"

#Name of VM to send your text to(REQUIRED)
$vm = "WXEROXtest10001"


if($text){
    #Set temporary directory and temporary file
    $tempDir = "C:\temp\"
    $fileName = $tempDir + $fileName
    Set-Content -path $filename -value $text
    $fileSource = $fileName
    #Sends file to VM Selected
    Copy-VMGuestFile -Source $fileSource -Destination $fileDest -VM $vm -LocalToGuest -GuestUser [GuestUser] -GuestPassword [GuestPassword]
    #Cleans up temporary file
    del $fileSource
    }
elseif($filesource){
    Copy-VMGuestFile -Source $fileSource -Destination $fileDest -VM $vm -LocalToGuest -GuestUser [GuestUser] -GuestPassword [GuestPassword]
    }
else{
    Write-Host "No source input has been given"
    }


#Copy-VMGuestFile -Source $fileSource -Destination $fileDest -VM $vm -LocalToGuest -GuestUser Administrator -GuestPassword Password1

#Script that inserts text into a file
#$script = "$text | out-File -filepath '$fileName'"
#[string]$script = '$text' + ">>" + $fileName
#[string]$script = "Set-content -path " + $filename + " -value " + """$text"""

#Command that runs $script on selected VM
#Invoke-VMScript -VM $vm  -GuestUser Administrator -GuestPassword Password1 -ScriptType Powershell -ScriptText $script 
