@echo off
echo *************************
echo *
echo **
echo * Connect to build share
net use B: \\192.168.199.7\Build >> c:\buildlog.txt
type b:\automate\version.txt  >> c:\buildlog.txt
regedit -s b:\Automate\_Common\ExecuPol.reg
regedit -s b:\Automate\_Common\NoSCRNSave.reg
regedit -s B:\Automate\_Common\ExplorerView.reg
regedit -s b:\Automate\_Common\IExplorer.reg
regedit -s b:\Automate\_Common\Nested.reg
copy b:\automate\_Common\wasp.dll c:\windows\system32
copy B:\Automate\PSFunctions.ps1 C:\
copy B:\Automate\VBR\Build.ps1 c:\

rem echo * Activate Windows >> c:\buildlog.txt
rem cscript //B "%windir%\system32\slmgr.vbs" /ato
echo **
echo * Setup persistent route to other subnet for SRM and View
echo * Setup persistent route to other subnet for SRM and View  >> c:\buildLog.txt
route add 192.168.201.0 mask 255.255.255.0 192.168.199.254 -p
echo **
echo * Install reqired Windows compnents
echo * Install reqired Windows compnents  >> c:\buildLog.txt
Start /wait pkgmgr /l:C:\IIS_Install_Log.txt /iu:NetFx3;IIS-WebServerRole;IIS-WebServer;IIS-ApplicationDevelopment;IIS-ASP;IIS-ISAPIFilter;ADFS-WebAgentToken;IIS-ASPNET;IIS-Security;IIS-BasicAuthentication;IIS-DigestAuthentication;IIS-RequestFiltering;IIS-WindowsAuthentication;IIS-WebServerManagementTools;IIS-ManagementConsole;IIS-NetFxExtensibility;IIS-ISAPIExtensions
echo **

echo * Starting PowerShell script for Build
echo * Starting PowerShell script for Build >> C:\buildlog.txt
powershell c:\Build.ps1
