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


Configuration UpdateDBBilling { 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{       
        Script UpdateBilling
        {
            SetScript = { 
				#Redirecting to installer folder
				#$serverName= $env:COMPUTERNAME;
				
				cd /
				cd C:\hybrinstall\Billing_2109.1.6\Billing\Tool
				#1
				./Billing.exe UpdateDatabase /ApiEndpoint:http://localhost:30045 /Username:cloudassert /Password:Kottai2050$
				#2 open API – C:\inetpub\MgmtSvc-CloudAssertBilling\Web.Config
				#.\Billing.exe UpdateDatabase /ApiEndpoint:http://localhost:30045 /Username:cloudassertadminuser /Password:Kottai2050$
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
UpdateDBBilling -ConfigurationData $config_data
#Start-DscConfiguration -Path UpdateDBBilling -Wait -Force -Verbose
