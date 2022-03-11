#To make a vm as host machine run the below command in host vm manually and run the below script in powershell ISE in admin mode

Enable-PSRemoting -Force 

winrm e winrm/config/listener 

Set-Item wsman:\localhost\client\trustedhosts * 

Restart-Service WinRM 

#run the above comments in host its mandatory


