if (Test-Path C:\PSFunctions.ps1) {
	. "C:\PSFunctions.ps1"
} else {
	Write-Host "PSFunctions.ps1 not found. Please copy all PowerShell files from B:\Automate to C:\ and rerun Build.ps1"
	Read-Host "Press <Enter> to exit"
	exit
}

# Start V1 configuration process
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

Write-BuildLog "Change default local administrator password"
net user administrator $AdminPWD
#B:\automate\_Common\Autologon administrator v1 $AdminPWD
B:\automate\_Common\Autologon svc_veeam lab $AdminPWD
Write-BuildLog ""

Write-BuildLog "Cleanup and creating Desktop shortcuts."

Remove-Item "C:\Users\Public\Desktop\*.lnk"

#copy b:\Automate\vc\Shortcuts.vbs c:\Shortcuts.vbs
#wscript c:\Shortcuts.vbs
copy b:\Automate\*.ps1 c:\

Write-BuildLog "Disable Internet Explorer Enhanced Security to allow access to Web Client"
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

Write-BuildLog "Still working on the VeeamOne install script"
Write-BuildLog "As of now you will have to do the VeeamOne install by hand"
	
Write-BuildLog "Installing VMware tools, build complete after reboot."
if (Test-Path B:\VMTools\setup64.exe) {
	#Read-Host "End of install checkpoint, before VMTools"
	Start-Process B:\VMTools\setup64.exe -ArgumentList '/s /v "/qn"' -verb RunAs -Wait
}

Read-Host "Computer will restart when VMware Tools is installed"

exit

# http://helpcenter.veeam.com/one/80/deployment/system_requirements_typical_installation.html
# http://forums.veeam.com/veeam-one-f28/veeam-one-scripted-install-t27129.html
# Microsoft SQL Server Reporting Services 2012
# http://helpcenter.veeam.com/one/80/deployment/veeam_one_service_account.html
#
# If the SQL database is installed remotely, with the SQL Server and Veeam ONE components residing in the same workgroup,
# SQL Server authentication will be required.
	
#The following components are included in the Veeam ONE setup package and can be installed automatically:
#1.	Microsoft .NET Framework 4 or later
#2.	Microsoft Visual C++ 2010 Service Pack 1 Redistributable Package
#3.	Microsoft Internet Information Services (IIS) 7.0 or later
#4.	Microsoft PowerShell 2.0 (required for Windows Server 2008)
#5.	Microsoft PowerShell 3.0 (required for SCVMM 2012 or SCVMM 2012 R2 Admin UI)
#6.	Microsoft SQL Native Client 2012
#7.	Microsoft SQL Server System CLR Types
#8.	Microsoft SQL Server 2012 Management Objects
#9.	Microsoft Report Viewer Redistributable 2012
#10.	WAS Configuration APIs

# http://helpcenter.veeam.com/one/80/deployment/creating_database_with_sql_script.html
# B:\Build\Veeam1\Addins\SQLScript
# Keep the database on the DC machine
#sqlcmd -S DC\SQLEXPRESS -d VeeamOne -E -i “E:\Addins\SQLScript\VeeamOne.sql”

# Create a SQL Server account with the DB Owner permissions, or grant DB Owner permissions
# to an existing SQL Server account. The account will be used by Veeam ONE components to access the SQL Server database

#Veeam ONE Monitor Client
#msiexec /qn /l*v c:\VeeamOne\MonClnlog.txt /i c:\VeeamOne\cd\Monitor\veeam_monitor_cln_x86.msi REBOOT=ReallySuppress INSTALLDIR="C:\Program Files\Veeam\Veeam ONE\Veeam ONE Monitor Server"

#Veeam ONE Server:
#msiexec /qn /l*v c:\VeeamOne\MonSrvlog.txt /i c:\VeeamOne\cd\Monitor\veeam_monitor_srv_x64.msi ADDLOCAL=ALL VM_ONE_WIZARD=1 VM_MN_SERVICEACCOUNT=DOMAIN\USER VM_MN_SERVICEPASSWORD=PASSWORD VM_MN_SQL_SERVER=HOSTNAME\INSTANCE NAME VM_MN_SQL_DATABASE=VeeamOne VM_MN_SQL_AUTHENTICATION=0 VM_VC_SELECTED_TYPE=0 VM_VC_HOST=vCenter_Server VM_VC_PORT=443 VM_VC_HOST_USER=DOMAIN\USER VM_VC_HOST_PWD=PASSWORD EDITLICFILEPATH=c:\VeeamOne\license.lic REBOOT=ReallySuppress VM_HV_TYPE=0 INSTALLDIR="C:\Program Files\Veeam\Veeam ONE\Veeam ONE Monitor Server" VM_BACKUP_ADD_LATER=0

#For Veeam ONE Reporter component just use these lines in the code above:
#msiexec /qn /l*v c:\VeeamOne\RepSRVlog.txt /i c:\VeeamOne\cd\Reporter\VeeamONEReporterSvc_x64.msi
#
#To install Veeam ONE Reporter and Business View web sites use these lines:
#
#msiexec /qn /l*v c:\VeeamOne\RepWEBlog.txt /i c:\VeeamOne\cd\Reporter\VeeamONEReporterWeb_x64.msi ADDLOCAL=ALL VM_RP_SERVICEACCOUNT=DOMAIN\USER VM_RP_SERVICEPASSWORD=PASSWORD VM_RP_SQL_SERVER=serverHOSTNAME\INSTANCE NAME VM_RP_SQL_DATABASE=VeeamOne VM_RP_SQL_AUTHENTICATION=0 REBOOT=ReallySuppress PF_VEEAMONE="C:\Program Files\Veeam\Veeam ONE\Veeam ONE Reporter Web"
#msiexec /qn /l*v c:\VeeamOne\BVlog.txt /i c:\VeeamOne\cd\BusinessView\BV_x64.msi ADDLOCAL=ALL BV_SERVICE_USER=DOMAIN\USER BV_SERVICE_PASSWORD=PASSWORD BV_SQLINSTANCENAME=HOSTNAME\INSTANCE NAME BV_SQLSERVER_DATABASE=VeeamOne BV_SQLSERVER_AUTHENTICATION=0 REBOOT=ReallySuppress INSTALLDIR="C:\Program Files\Veeam\Veeam ONE\Veeam ONE Business View"
