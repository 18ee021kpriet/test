
$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='DhivyaTest'
            #Nodename - name of the 1st target vm 
			
	    },
        @{ 
            NodeName ='KarthikDevops'
            ##Nodename - name of the 2nd target vm , you can add as many nodes you want
        },
        @{
            NodeName ='enter the 3rd target nodename'
        },
        @{
            NodeName ='enter the 4th target nodename'
        },
        @{
            NodeName ='enter the 5th target nodename'
        },
        @{
            NodeName ='enter the 6th target nodename'
        }

        
	)
}       

Configuration PreRequisties_DSC { 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{       
        Script Prerequisites
        {
            SetScript = { 
                
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                Install-Module -Name PSDesiredStateConfiguration
    
                Install-Module -Name SqlServerDsc -Force
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Install-PackageProvider -Name NuGet
			    Find-DscResource xRemoteFile | Install-Module -Force -Verbose 
                Write-Host 'Installed !' -ForegroundColor DarkGreen
                Install-Module -Name xPSDesiredStateConfiguration -RequiredVersion 9.1.0
                Write-Host 'Installed XPS!' -ForegroundColor DarkGreen
                Get-PSRepository
                Register-PSRepository -Default
                
                Install-Module AzureRM 
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

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
PreRequisties_DSC -ConfigurationData $config_data
#Start-DscConfiguration -Path PreRequisties_DSC -Wait -Force -Verbose