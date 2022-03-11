
$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='DhivyaTest'
			
	    },
        @{
            NodeName ='enter the 2nd target nodename'
        }
        
	)
}
      

Configuration UpdateDBVconnect { 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{       
        Script UpdateVConnectDB
        {
            SetScript = { 
                
				$serverName = $env:COMPUTERNAME;
				cd /
				cd C:\hybrinstall\33312\VConnect\VConnect_Tools
				$VconnectPass = ./VConnect.exe HashPass Kottai2050$
				$pass = $VconnectPass[9]
				Start-Sleep -Seconds 10
				#2 "CAAAANWExV+kaZZ4FbT+6RLUE1RvxEhy59uJSnU0TRY1KbxUB3Tp8PnfOXA="" - different for different hashpassword
				$file = 'C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config'
				$regex = '(?<=<add key="Password" value=")[^"]*'
				(Get-Content $file) -replace $regex, "$pass" | Set-Content $file
				Start-Sleep -Seconds 10
				# (Get-Content C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config).replace('<add key="Password" value="CAAAANWExV+kaZZ4FbT+6RLUE1RvxEhy59uJSnU0TRY1KbxUB3Tp8PnfOXA=" />', "<add key=`"Password`" value= `"$($pass)`" />") | Set-Content C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config
				#3
				./VConnect.exe UpdateDatabaseSettings $serverName vconnect sa Kottai2050$ /isUseIntegratedSecurity:false /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				./VConnect.exe UpdateDatabaseSettings $serverName vconnect sa Kottai2050$ /isUseIntegratedSecurity:false /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				#4 WIN-G0FP1SQCPCI-MachineName different for different machines or vm administrator-username of vm
				./VConnect.exe UpdatePowerShellSettings $serverName 5985 false .\administrator Kottai2050$ /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				#5
				cmd /c "winrm set winrm/config/client @{TrustedHosts =`"IP_Address`"}"

            }
             TestScript = {
                return $false
            }

            GetScript = {
            }

            #DependsOn = "[Script]Update_Billing_Database"
        }
    }
}
UpdateDBVconnect -ConfigurationData $config_data
#Start-DscConfiguration -Path UpdateDBVconnect -Wait -Force -Verbose