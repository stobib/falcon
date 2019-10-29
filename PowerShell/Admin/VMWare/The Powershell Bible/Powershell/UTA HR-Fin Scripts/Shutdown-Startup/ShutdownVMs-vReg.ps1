<#
#################################################################################
# Power off VMs (poweroffvms.ps1)
#
# Version 1.1 - 22nd November 2012
# Removed loop for checking on connected hypervisors
#
# .SYNOPSIS
#
# This script does have a 'partner' script that powers the VMs back on.
#
# Created By: Graham F French 2012 (@NakedCloudGuy) 
# Taken from script by Mike Preston, 2012 - With a whole lot of help from Eric Wright 
#                                  (@discoposse)
#
# Variables:  $mysecret - a secret word to actually make the script run, stops the script from running when double click DISASTER
#             $ShutdownTier1Filename - A numbered filename which allows tiered shutdowns within the vCenter
#			  $waitshutdown - Sleep between each iteration of a loop, in seconds.
#			  $scriptDir - Front part of the relative script path.
#
# Usage: ./poweroffvms.ps1 "keyword"
#        Intended to be ran in the command section of the APC Powerchute Network
#        Shutdown program before the shutdown sequence has started.
#
#################################################################################

  ******************************
  ** Holding Area for Scripts **
  ******************************
  
  
  ** This function will simulate the 'Pause' feature of CMD.exe. **
  
Function Pause ($Message = "Press any key to continue...")
{
	Write-Host -NoNewline $Message
	$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	Write-Host ""
}

Pause 
write-Host 
write-Host "Now continuing" 
write-Host

	** End **
#>


$keyword = "shutdown"

# Sets up the expectation of a secret keyword to be added when running the script. Stops accidents when double clicking!!
#param($keyword)

# Adds the base cmdlets if needed
$SnapinLoaded = get-pssnapin | Where-Object {$_.name -like "*VMware*"}
if (!$SnapinLoaded) {
	Add-PSSnapin VMware.VimAutomation.Core
}

# Show input box popup and return the value entered by the user.
function Read-InputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText)
{
    Add-Type -AssemblyName Microsoft.VisualBasic
    return [Microsoft.VisualBasic.Interaction]::InputBox($Message, $WindowTitle, $DefaultText)
}

#Check to see if there are any hypervisor hosts connected

#Function to Check Connectivity with VIServer
Function CheckVIConnectivity{
#If connected, show which ones
	if ($defaultVIServers) {
	# Asks the user if they want to continue or exit. 
	AreYouSure	
	}
	Else{
	#If not connected to any hosts, connect to a VCenter
	Write-Host "Prompting for user input"
    $userVIServer = Read-InputBoxDialog -Message "Please enter a valid VCenter Server Hostname or IP" -WindowTitle "VCenter Hostname"
    Connect-VIServer -Server $userVIServer
	Write-Host "Now Connected." -ForegroundColor Red

	}
}

#some variables
#Shutdown Tiers Filenames
$ShutdownTier1Filename = ".\ShutdownTier1VMs.csv"
$ShutdownTier2Filename = ".\ShutdownTier2VMs.csv"
$ShutdownTier3Filename = ".\ShutdownTier3VMs.csv"
$ShutdownTier4Filename = ".\ShutdownTier4VMs.csv"
$ShutdownTier5Filename = ".\ShutdownTier5VMs.csv"
$ShutdownTier6Filename = ".\ShutdownTier6VMs.csv"
$ShutdownTier7Filename = ".\ShutdownTier7VMs.csv"
$ShutdownTier8Filename = ".\ShutdownTier8VMs.csv"
$ShutdownTier9Filename = ".\ShutdownTier9VMs.csv"

#Others
$mysecret = "shutdown"

#Wait time between loops of shutting down VMs, in seconds.
$waitshutdown = 0

#Variable to stitch the relative file path together
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

#Variable for Logfile
$date = get-date -format yyyy_MM_dd-HH-mm-ss 
$LogFileName = "LogFileOutput-$date.txt"
$LogFileOutput = (join-Path $scriptDir ./logs/$LogFileName)

# This is the keyword checker
if ($keyword -ne $mysecret) 
{
    Write-Host "You haven't passed the proper detonation sequence...ABORTING THE SCRIPT" -ForegroundColor red
 	exit
}

#Function to write to screen and log file
Function WriteLog ($LogText) {

#Write to screen first
Write-Host "$LogText"

#Then write the same text to the log file, including the date stamp to the start of the entry in the logfile
$tempDate = get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "$tempDate $LogText" | Out-File $LogFileOutput -append 
}

WriteLog ("**********************************************")
WriteLog ("Power off VMs PowerShell")
WriteLog ("Logging output from ShutdownVMs.PS1")
WriteLog ("**********************************************")
WriteLog
WriteLog

#Main Function to shutdown Servers
function ShutdownRoutine($ChosenOption){

#Call function to see if we are connected to any host servers
CheckVIConnectivity

#Get all powered on VM's
$ONvmservers=Get-VM | Where-Object {$_.powerstate -eq �PoweredOn�}

	#And now, let's start powering off some guests....
	#ForEach ( $guest in $inputfile ) 
	foreach ( $guest in $ONvmservers ) {
		# Check to see if the VM exists, if not then put error onto screen
		# and then continue with loop
		$MyVM = Get-VM -Name $guest -ErrorAction SilentlyContinue
		if($MyVM -eq $null){
			WriteLog
			WriteLog '****************************************'
			WriteLog '****************************************'
			WriteLog "$guest Virtual Machine doesn't exist, please check your list of VMs!" -Foregroundcolor Red
			WriteLog '****************************************'
			WriteLog '****************************************'
			WriteLog
		}
		else {

			# Check to see if the VM is powered on
			# If not, it will continue the loop

			$PowerState = get-vm $guest
			$PowerState = $PowerState.PowerState
			#WriteLog "$guest is now $PowerState"
			if ($PowerState -eq "PoweredOn") {
				WriteLog
				WriteLog '****************************************'
				WriteLog '****************************************'
				WriteLog "$guest is switched on." -ForegroundColor Green
				WriteLog
				WriteLog
				WriteLog "Processing $guest ...." -ForegroundColor Green
				WriteLog "Checking for VMware tools install" -Foregroundcolor Green
				WriteLog
				WriteLog
				WriteLog '****************************************'
				WriteLog '****************************************'
				WriteLog

				# Get the version of VMware Tools
				$guestinfo = (Get-VM $guest | Get-View).Guest.ToolsVersion 
				WriteLog "$guest is running VMware Tools Version $guestinfo"
				#Wrap code in try/catch/finally
				try {
					if ($guestinfo -eq 0)
					{
						WriteLog "No VMware tools detected in $guest , hard power this one?" -ForegroundColor Yellow
						#Stop-VM -VM $guest -confirm:$false
					}
					else
					{
						WriteLog "VMware tools detected. Attempting to gracefully shutdown $guest"
						Shutdown-VMGuest -VM $guest -Confirm:$false 
						#$vmshutdown = $guest | shutdown-VMGuest -Confirm:$false -WhatIf

						#Wait for alloted time before another loop. Don't want to create queues in vCenter Server...
						WriteLog "Sleeping for $waitshutdown seconds. This is configurable in this script"
						Start-Sleep -Seconds $waitshutdown
					}
				}
				catch {
					WriteLog
					WriteLog "Error detected with $guest" -ForegroundColor Red
					WriteLog
				}
				finally {

				}
			}
			else {
				WriteLog "$guest Virtual Machine is switched off!"
			}
		}
	}
}


#Main Function to shutdown Servers
function ShutdownPhysicalRoutine($ChosenOption){
	
	# Asks the user if they want to continue or exit. 
	AreYouSure

	#And now, let's start powering off some guests....
	#ForEach ( $guest in $inputfile ) 
	foreach ( $guest in $ChosenOption ) 
	{
		WriteLog
		WriteLog ("Testing to see if connectivity to $guest is pingable")
		WriteLog
		#Send a single ping to Physical Server
		if(Test-Connection -ComputerName $guest -BufferSize 16 -Count 1 -ea 0 -quiet)
		{
		WriteLog
		WriteLog ("$guest is pingable and appears to be online")
		WriteLog
		WriteLog ("Attempting to shutdown $guest")
		# Send command to computer to shutdown - confirm with user before each one!
		Stop-Computer -ComputerName $guest -Confirm -Force
	
		#Wait for alloted time before another loop. 
		WriteLog "Sleeping for $waitshutdown seconds. This is configurable in this script"
		Start-Sleep -Seconds $waitshutdown
		}
		Else
		{
		WriteLog("**Alert**")
		
		
		
		
		
		WriteLog ("$guest appears to be offline and will not be commanded to shutdown!")
		WriteLog
		WriteLog
		} 
	}
}

# Asks the user if they want to continue or exit. 
Function AreYouSure
{
	# Creates a windows dialogue box
	$a = new-object -comobject wscript.shell 
	$intAnswer = $a.popup("Do you want to continue to run this script?",0,"Continue Running Script",4) 
	If ($intAnswer -eq 6) 
	{ 
	    $a.popup("You have chosen to continue running the script! :-)",0,"Continuing Script :-)") 
		#Write decision to the log
		WriteLog
		WriteLog "Admin has chosen to continue running the script! :-)"
		WriteLog
	} 
	else 
	{ 
	    $a.popup("You have chosen to exit the script! :-(",0,"Now Exiting! :-(") 
		#Write decision to the log
		WriteLog
		WriteLog "Admin has chosen to exit the script! :-("
		WriteLog
		exit
	} 
	  
	#Button Types  
	# 
	#Value  Description   
	#0 		Show OK button. 
	#1 		Show OK and Cancel buttons. 
	#2 		Show Abort, Retry, and Ignore buttons. 
	#3 		Show Yes, No, and Cancel buttons. 
	#4 		Show Yes and No buttons. 
	#5		Show Retry and Cancel buttons. 
}



Write-Host
Write-Host
Write-Host
Write-Host '**********************************************************' -ForegroundColor Red
Write-Host '**********************************************************' -ForegroundColor Red
Write-Host
Write-Host 'This script will Shutdown your VMs!!' -ForegroundColor Red
Write-Host
Write-Host 
Write-Host
Write-Host 'Enter any other key to exit!' -ForegroundColor Magenta
Write-Host
Write-Host '**********************************************************' -ForegroundColor Red
Write-Host '**********************************************************' -ForegroundColor Red
Write-Host
Write-Host

#Get input choice from User
$RunType = Read-Host "Enter '1' to shutdown your VM's. What is your number choice??" #-ForegroundColor Blue

Write-Host
Write-Host

if ($RunType -eq "1") {

	#Create the input file, which lists the vm's by stitching together the current directory of the script 
	#and the name of the filename with the list of vm's. Call the shutdownVM's routine with the correct filename
	WriteLog "You have chosen to shutdown VMs"
	#$inputfile = get-content (Join-Path $scriptDir $ShutdownTier1Filename)
    $inputfile = "The list if you had one"
	ShutdownRoutine ($inputfile)
}
else {
	WriteLog
	WriteLog
	WriteLog "You have not chosen to continue running, therefore exiting!" -ForegroundColor Yellow
	WriteLog
	WriteLog
	exit
}
