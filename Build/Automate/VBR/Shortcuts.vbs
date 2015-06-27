set WshShell = WScript.CreateObject("WScript.Shell")

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam ActiveDirectory Explorer.lnk")
oShortCutLink.TargetPath = "C:\Program Files\Veeam\ActiveDirectoryExplorer\Veeam.ActiveDirectory.Explorer.exe"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam SQL Explorer.lnk")
oShortCutLink.TargetPath = "C:\Program Files\Veeam\SQLExplorer\Veeam.SQL.Explorer.exe"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam Backup Extractor.lnk")
oShortCutLink.TargetPath = "C:\Program Files\Veeam\Backup\Veeam.Backup.Extractor.exe"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam Backup FileRestore.lnk")
oShortCutLink.TargetPath = "C:\Program Files\Veeam\Backup\Veeam.Backup.FileRestore.exe"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam Backup Extractor.lnk")
oShortCutLink.TargetPath = "C:\Program Files\Veeam\Backup\Veeam.Backup.Extractor.exe"
oShortCutLink.Save

set oShortCutLink = WshShell.CreateShortcut("C:\Users\Public\Desktop\Veeam Powershell Tool.lnk")
oShortCutLink.TargetPath = "%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe"
oShortCutLink.Arguments = " c:\C:\Program Files\Veeam\Backup\Initialize-VeeamToolkit.ps1"
oShortCutLink.Save
