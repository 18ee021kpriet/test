$config_data = @{
	AllNodes = @(
	    @{
			#NodeName ='WIN-J6E5KEST4F4'
            NodeName ='Dhivyatest2016'

			
	    }
        
	)
}



Configuration DownloadAndUzip {
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{
	    # need to run the below cmd in host and nodes for downloading from online
        #Find-DscResource xRemoteFile | Install-Module -Force -Verbose 

        xRemoteFile DownloadVconnect 
        {
        URI = "https://blobstoragehybr.blob.core.windows.net/vconnectci/33312.zip"
        
        DestinationPath = "C:\hybrinstall\33312.zip"
        }


        archive unzipVconnect
        {
        Path = "C:\hybrinstall\33312.zip"
        Destination = "C:\hybrinstall\33312"
        Ensure = 'Present'
        #DependsOn = "[File]DownloadVconnect"
	    } 

        Script Remove_Vconnect_msi
        {
            SetScript = { 
                 Remove-Item –path 'C:\hybrinstall\33312\VConnect\CloudAssert.WAP.VConnect.Service.Setup.msi'
            }
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }

        xRemoteFile DownloadNewVconnectMsi 
        {
        URI = "https://cadownloads.blob.core.windows.net/release/vconnect/2.2112.1.9/VConnect/CloudAssert.WAP.VConnect.Service.Setup.msi"
        
        DestinationPath = "C:\hybrinstall\33312\VConnect"
        }
            

        xRemoteFile DownloadBilling
        {
        URI = "https://blobstoragehybr.blob.core.windows.net/vconnectci/BillingInstallers/Billing_2109.1.6.zip"
        DestinationPath = "C:\hybrinstall\Billing_2109.1.6.zip"
        }


        archive unzipBilling
        {
        Path = "C:\hybrinstall\Billing_2109.1.6.zip"
        Destination = "C:\hybrinstall\Billing_2109.1.6"
        Ensure = 'Present'
        #DependsOn = "[File]DownloadBilling"
	    }

        Script Remove_Billing_msi
        {
            SetScript = { 
                Remove-Item –path 'C:\hybrinstall\Billing_2109.1.6\Billing\CloudAssert.WAP.Billing.Service.Setup.msi'
                #Remove-Item –path 'C:\hybrinstall\Billing_2109.1.6\Billing\CloudAssert.WAP.Billing.AgentService.Setup.msi'
            }
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }

        xRemoteFile DownloadNewBillingServiceMsi 
        {
        URI = "https://cadownloads.blob.core.windows.net/release/billing/3.2112.1.7/Billing/CloudAssert.WAP.Billing.Service.Setup.msi"
        
        DestinationPath = "C:\hybrinstall\Billing_2109.1.6\Billing"
        }

        <# xRemoteFile DownloadNewBillingAgentMsi 
        {
        URI = "https://cadownloads.blob.core.windows.net/release/billing/3.2112.1.7/Billing/CloudAssert.WAP.Billing.AgentService.Setup.msi"
        
        DestinationPath = "C:\hybrinstall\Billing_2109.1.6\Billing"
        } #>

        xRemoteFile DownloadHybr
        {
        URI = "https://cadownloads.blob.core.windows.net/release/hybr/1.2112.1.14/20220202.13-release.zip"
        DestinationPath = "C:\hybrinstall\202110810.9.zip"
        }


        archive unzipHybr
        {
        Path = "C:\hybrinstall\202110810.9.zip"
        Destination = "C:\hybrinstall\202110810.9"
        Ensure = 'Present'
        #DependsOn = "[File]DownloadHybr"
	    }  
	}
	
}

DownloadAndUzip -ConfigurationData $config_data
#FileCopy -OutputPath C:\Temp\dsc\FileCopy
#Start-DscConfiguration -Path DownloadAndUzip -Wait -Force -Verbose
#reference link = https://www.tutorialspoint.com/how-to-resolve-relative-path-is-not-supported-in-powershell-dsc