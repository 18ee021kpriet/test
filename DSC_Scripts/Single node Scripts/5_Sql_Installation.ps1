$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='DhivyaTest'
			
	    }
        
	)
}

Configuration SQLServerConfiguration {
    #need to install PSDesiredStateConfiguration using bellow cmd for first time
    #Install-Module -Name PSDesiredStateConfiguration 
    # need to run the below cmd in host and nodes for downloading from online
    #Find-DscResource xRemoteFile | Install-Module -Force -Verbose 
    # need to run the below cmd to install sqlsever module
    #Install-Module -Name SqlServerDsc -Force

    

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SqlServerDsc
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Node $AllNodes.NodeName
	{
	    xRemoteFile DownloadSQL
        {
        URI = "https://archive.org/download/en_sql_server_2017_developer_x64_dvd_11296168/en_sql_server_2017_developer_x64_dvd_11296168.iso"
        DestinationPath = "C:\en_sql_server_2017_developer_x64_dvd_11296168.iso"
        }
        
        #The command below mounts the image and copies the contents to C:\SQLServer
        Script Prerequisites
        {
            SetScript = { 
                
			    $ImagePath = 'C:\en_sql_server_2017_developer_x64_dvd_11296168.iso'

                New-Item -Path C:\SQLServer -ItemType Directory
                Copy-Item -Path (Join-Path -Path (Get-PSDrive -Name ((Mount-DiskImage -ImagePath $ImagePath -PassThru) | Get-Volume).DriveLetter).Root -ChildPath '*') -Destination C:\SQLServer\ -Recurse
                Dismount-DiskImage -ImagePath $ImagePath

                # By combining Get-PackageProvider with its ForceBootstrap parameter, the package provider will either be retrieved if it is already installed or force Package Management to automatically install it.
	            Get-PackageProvider -Name NuGet -ForceBootstrap

            }
             TestScript = {
                return $false
            }

            GetScript = {
            }

            #DependsOn = "[Script]Update_Billing_Database"
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
        }
    }
}
SQLServerConfiguration -ConfigurationData $config_data
#Start-DscConfiguration -Path SQLServerConfiguration -Wait -Force -Verbose

#reference link 
# https://joeydavis.me/sql-server-installation-with-powershell/