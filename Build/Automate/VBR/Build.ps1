if (Test-Path C:\PSFunctions.ps1) {
	. "C:\PSFunctions.ps1"
} else {
	Write-Host "PSFunctions.ps1 not found. Please copy all PowerShell files from B:\Automate to C:\ and rerun Build.ps1"
	Read-Host "Press <Enter> to exit"
	exit
}

# Start VBR build configuration process
if (Test-Path "B:\Automate\automate.ini") {
	Write-BuildLog "Determining automate.ini settings."
		$timezone = "New Zealand Standard Time"
	$timezone = ((Select-String -SimpleMatch "TZ=" -Path "B:\Automate\automate.ini").line).substring(3)
	Write-BuildLog "  Set timezone to $timezone."
	tzutil /s "$timezone"
	$AdminPWD = "VMware1!"
	$AdminPWD = ((Select-String -SimpleMatch "Adminpwd=" -Path "B:\Automate\automate.ini").line).substring(9)
} else {
	Write-BuidLog "Unable to find B:\Automate\automate.ini. Where did it go?"
}

If ((([System.Environment]::OSVersion.Version.Major *10) +[System.Environment]::OSVersion.Version.Minor) -ge 62) {
	Write-BuildLog "Disabling autorun of ServerManager at logon."
	Start-Process schtasks -ArgumentList ' /Change /TN "\Microsoft\Windows\Server Manager\ServerManager" /DISABLE'  -Wait -Verb RunAs
	Write-BuildLog "Disabling screen saver"
	set-ItemProperty -path 'HKCU:\Control Panel\Desktop' -name ScreenSaveActive -value 0
	Write-BuildLog "Disable IE11 run once start up"
	#$null = New-Item -Path C:\temp -ItemType Directory -Force -Confirm:$false
	New-Item 'HKLM:\Software\Policies\Microsoft\Internet Explorer\'
	New-Item 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main'
	set-ItemProperty -path 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Main' -name DisableFirstRunCustomize -value 1
	set-ItemProperty -path 'HKLM:\Software\Microsoft\Internet Explorer\Main' -name RunOnceComplete -value 1
	set-ItemProperty -path 'HKLM:\Software\Microsoft\Internet Explorer\Main' -name RunOnceHasShown -value 1

}

Write-BuildLog "Clear System eventlog, errors to here are spurious"
Clear-EventLog -LogName System -confirm:$False

Write-BuildLog "Installing 7-zip."
try {
	Start-Process msiexec -ArgumentList '/qb /i B:\Automate\_Common\7z920-x64.msi' -Wait 
}
catch {
	Write-BuildLog "7-zip installation failed."
}

Write-BuildLog ""

#Write-BuildLog "Change default local administrator password"
net user administrator $AdminPWD
B:\automate\_Common\Autologon svc_veeam lab $AdminPWD
Write-BuildLog ""

Write-BuildLog "Cleanup Desktop shortcuts."

Remove-Item "C:\Users\Public\Desktop\*.lnk"

Write-BuildLog "Disable Internet Explorer Enhanced Security to allow access to Web Client"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

# -----------------------------------------------------------------------------
# make sure the temp dir is around for the log files
$null = New-Item -Path C:\temp -ItemType Directory -Force -Confirm:$false

if (Test-Path "B:\VeeamBR\Redistr\x64\SQLSysClrTypes.msi") {
		Write-BuildLog "Installing Microsoft System 2012 CLR Types  (SQLSysClrTypes.msi)"
		#Start-Process msiexec -ArgumentList '/qb /l*v c:\temp\install_SQLSysClrTypes.txt /i B:\VeeamBR\Redistr\x64\SQLSysClrTypes.msi' -Wait 
		Start-Process msiexec -ArgumentList '/qb /i B:\VeeamBR\Redistr\x64\SQLSysClrTypes.msi' -Wait 
		Write-BuildLog "Installing Microsoft SQL Server 2012 Shared Management Objects"
		#Start-Process msiexec -ArgumentList '/qb /l*v c:\temp\install_SharedManagementObjects.txt /i B:\VeeamBR\Redistr\x64\SharedManagementObjects.msi' -Wait
		Start-Process msiexec -ArgumentList '/qb /i B:\VeeamBR\Redistr\x64\SharedManagementObjects.msi' -Wait
	} Else {
		Write-BuildLog "SQLSysClrTypes Install found, not installing"
		Write-BuildLog "VEEAM 8.x prerequisites not found. Please verify that all contents of Veeam Backup And Replication ISO are copied into the correct folder on the Build share."
		Read-Host "Press <ENTER> to exit"
		exit
	}

Write-BuildLog "Installing VeeamBackupCatalog"
$Arguments = '/qb /i B:\VeeamBR\Catalog\VeeamBackupCatalog64.msi VBRC_SERVICE_USER="LAB\svc_veeam" VBRC_SERVICE_PASSWORD="VMware1!" VBRC_SERVICE_PORT="9393"'
Start-Process msiexec -ArgumentList $Arguments -Wait

Write-BuildLog "Installing VeeamBackup"
# Remote database install
$Arguments = '/qb /l*v c:\temp\veeam_BU.txt /i B:\VeeamBR\Backup\BU_x64.msi ACCEPTEULA=YES INSTALLDIR="C:\Program Files\Veeam" PF_AD_NFSDATASTORE="C:\ProgramData\Veeam\Backup\NfsDatastore" VBR_SERVICE_PORT="9392" VBR_AUTO_UPGRADE="YES" VBR_SERVICE_USER="LAB\svc_veeam" VBR_SERVICE_PASSWORD="VMware1!" VBR_SQLSERVER_SERVER="DC\SQLEXPRESS" VBR_SQLSERVER_DATABASE="VeeamBackup" VBR_SQLSERVER_USERNAME="svc_veeam" VBR_SQLSERVER_PASSWORD="VMware1!" VBR_SQLSERVER_AUTHENTICATION=1'
Start-Process msiexec -ArgumentList $Arguments -Wait

# adding a test at some point
# should check "C:\Program Files\Veeam\Backup\Veeam.Backup.Manager.exe" 

if (Test-Path "B:\VeeamBR\Plugins\BP_Hp3PAR_x64.msi") {
		Write-BuildLog "Installing Plugin BP_Hp3PAR"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Plugins\BP_Hp3PAR_x64.msi' -Wait
		Write-BuildLog "Installing Plugin BP_HpP4k"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Plugins\BP_HpP4k_x64.msi' -Wait
		Write-BuildLog "Installing Plugin BP_NetApp"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Plugins\BP_NetApp_x64.msi' -Wait
		Write-BuildLog "Installing Explorer VeeamExplorerForActiveDirectory.msi"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Explorers\VeeamExplorerForActiveDirectory.msi' -Wait
		Write-BuildLog "Installing Explorer VeeamExplorerForExchange"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Explorers\VeeamExplorerForExchange.msi' -Wait
		Write-BuildLog "Installing Explorer VeeamExplorerForSharePoint"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Explorers\VeeamExplorerForSharePoint.msi' -Wait
		Write-BuildLog "Installing Explorer VeeamExplorerForSQL"
		Start-Process msiexec -ArgumentList '/qb /i  B:\VeeamBR\Explorers\VeeamExplorerForSQL.msi' -Wait
		Write-BuildLog "Installing Veeam Backup PowerShell Snap-In BPS"
		Start-Process msiexec -ArgumentList '/qb /i B:\VeeamBR\Backup\BPS_x64.msi' -Wait
		Write-BuildLog "Adding some Desktop Shortcuts"
		Start-Process wscript -ArgumentList 'b:\Automate\VBR\Shortcuts.vbs' -Wait
	} Else {
		Write-BuildLog "Veeam Plugins and Explorers not found"
		Write-BuildLog "VEEAM 8.x prerequisites not found. Please verify that all contents of Veeam Backup And Replication ISO are copied into the correct folder on the Build share."
		Read-Host "Press <ENTER> to exit"
		exit
	}

# -----------------------------------------------------------------------------	
Write-BuildLog "Installing VMware tools, build complete after reboot."
if (Test-Path B:\VMTools\setup64.exe) {
	#Read-Host "End of install checkpoint, before VMTools"
	Start-Process B:\VMTools\setup64.exe -ArgumentList '/s /v "/qn"' -verb RunAs -Wait
}

Read-Host "Computer will restart when VMware Tools is installed"
exit
