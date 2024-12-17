$UninstallKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
$UninstallSubKeys = Get-ChildItem $UninstallKeys
$UninstallEntries = $UninstallSubKeys | Get-ItemProperty