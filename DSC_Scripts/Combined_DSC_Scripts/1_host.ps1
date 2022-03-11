#To make a vm as host machine run the below command in host vm manually and run the below script in powershell ISE in admin mode

#Enable-PSRemoting -Force 

#winrm e winrm/config/listener 
#Set-Item wsman:\localhost\client\trustedhosts * 

#Restart-Service WinRM 

#run the above comments in host its mandatory

$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='localhost'
            #It must be a localhost (This script must be run in local host) 
			
	    },
        @{
            NodeName = 'enter the target node name'
        }
        # if you want to add nodes you can add by using ,@{NodeName = 'enter the node name'}
        
        
	)
}       

Configuration DSCLocalHostPreRequisties { 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{    
        
        Script Prerequisites
        {
            SetScript = { 
                #Enable-PSRemoting -Force 
                #winrm e winrm/config/listener
                #Set-Item wsman:\localhost\client\trustedhosts * 
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
DSCLocalHostPreRequisties -ConfigurationData $config_data
#run the bellow command to start the Dsc config file.
#Start-DscConfiguration -Path DSCLocalHostPreRequisties -Wait -Force -Verbose

