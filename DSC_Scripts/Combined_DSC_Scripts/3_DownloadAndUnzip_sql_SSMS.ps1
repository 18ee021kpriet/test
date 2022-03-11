$config_data = @{
	AllNodes = @(
	    @{
			NodeName = 'AnadhDevopsVM'
			#enter the node name
			#UserName = 'Administrator'
			#optional
			#Password = 'Kottai2050$'
			#optional
			 
	    },
        @{
            NodeName ='KarthikDevops'
        }
        
	)
}

Configuration DownloadAndUnzip_sql_SSMS 
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Find-DscResource xRemoteFile | Install-Module -Force -Verbose 
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
       
    Node $AllNodes.NodeName
    {        
        
        #3

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

        Script Remove_old_Vconnect_msi
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
        URI = " https://blobstoragehybr.blob.core.windows.net/vconnectci/BillingInstallers/Billing_2109.1.6.zip"
        DestinationPath = "C:\hybrinstall\Billing_2109.1.6.zip"
        }


        archive unzipBilling
        {
        Path = "C:\hybrinstall\Billing_2109.1.6.zip"
        Destination = "C:\hybrinstall\Billing_2109.1.6"
        Ensure = 'Present'
        #DependsOn = "[File]DownloadBilling"
	    }

         Script Remove_old_Billing_Service_msi
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
        #4
        xRemoteFile SQL
        {
        URI = "https://archive.org/download/en_sql_server_2017_developer_x64_dvd_11296168/en_sql_server_2017_developer_x64_dvd_11296168.iso"
        DestinationPath = "C:\en_sql_server_2017_developer_x64_dvd_11296168.iso"
        }
        
        #The command below mounts the image and copies the contents to C:\SQLServer
        Script DisMountSQL
        {
            SetScript = { 
                
			    $ImagePath = 'C:\en_sql_server_2017_developer_x64_dvd_11296168.iso'

                New-Item -Path C:\SQLServer -ItemType Directory
                Start-Sleep -Seconds 10
                Copy-Item -Path (Join-Path -Path (Get-PSDrive -Name ((Mount-DiskImage -ImagePath $ImagePath -PassThru) | Get-Volume).DriveLetter).Root -ChildPath '*') -Destination C:\SQLServer\ -Recurse
                Start-Sleep -Seconds 60
                Dismount-DiskImage -ImagePath $ImagePath
                Start-Sleep -Seconds 60

                # By combining Get-PackageProvider with its ForceBootstrap parameter, the package provider will either be retrieved if it is already installed or force Package Management to automatically install it.
	            Get-PackageProvider -Name NuGet -ForceBootstrap

            }
             TestScript = {
                return $false
            }

            GetScript = {
            }

            DependsOn = "[xRemoteFile]SQL"
        }
    
        

        WindowsFeature 'NetFramework45' 
        {
        Name   = 'NET-Framework-45-Core'
        Ensure = 'Present'
        }

        SqlSetup 'InstallDefaultInstance'
        {
        InstanceName        = 'MSSQLSERVER'
        Features            = 'SQLENGINE'
        SourcePath          = 'C:\SQLServer'
        SQLSysAdminAccounts = @('Administrators')
        DependsOn           = '[WindowsFeature]NetFramework45'
        #DependsOn           = "[Script]DisMountSQL"

        }
		#5
        xRemoteFile DownloadSSMS 
        {
        URI = "https://aka.ms/ssmsfullsetup"
        DestinationPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft SQL Server 2019\SSMS-Setup-ENU.exe"
        
        } 

        # To get the ProductId, just install SSMS on any machine, and then run this
        #Get-WmiObject Win32_Product | Sort Name | Format-Table IdentifyingNumber, Version, PackageName, Name

        # It will return something like this
        # {A401EAB9-4FC7-4F0C-8D79-9575E4910FDE} 15.0.18390.0    sql_ssms.msi                                                   SQL Server Management Studio
        Package InstallSSMS
       {
        Name = "SQL Server Management Studio"
        Path ="C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft SQL Server 2019\SSMS-Setup-ENU.exe"
        ProductId = "AECA7DB1-802A-4A1E-A19A-A1529EEF433C"
        Arguments = "/install /passive /norestart"
        #[Credential = [PSCredential]]
        DependsOn = "[xRemoteFile]DownloadSSMS"
        Ensure = "present"
        #LogPath = "c:\logs\"
        #PsDscRunAsCredential = "Administrator"
        
       }
       #6
    }
}

DownloadAndUnzip_sql_SSMS -ConfigurationData $config_data
#Start-DscConfiguration -Path DownloadAndUnzip_sql_SSMS -Wait -Force -Verbose
#need to restart the node before running next scripts.
#open the SSMS and connect using windows Authentication then run the next Script.