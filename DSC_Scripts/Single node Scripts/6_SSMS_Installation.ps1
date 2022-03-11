$config_data = @{
	AllNodes = @(
	    @{
		  	NodeName ='DhivyaTest'
			
	    }
        
	)
}


Configuration SSMS {
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node $AllNodes.NodeName
	 {
	    # need to run the below cmd in host and nodes for downloading from online
        #Find-DscResource xRemoteFile | Install-Module -Force -Verbose 

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
        #DependsOn = "[ xRemoteFile]DownloadSSMS"
        Ensure = "present"
        #LogPath = "c:\logs\"
        #PsDscRunAsCredential = "Administrator"
        
      }


    }

}

SSMS -ConfigurationData $config_data
#FileCopy -OutputPath C:\Temp\dsc\FileCopy
#Start-DscConfiguration -Path SSMS -Wait -Force -Verbose
#restart the target node after the script in host terminated
#then open ssms and connect using windows authentication.