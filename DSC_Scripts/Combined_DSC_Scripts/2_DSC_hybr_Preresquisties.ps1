$config_data = @{
	AllNodes = @(
	    @{   # target machine 1
			NodeName = 'AnadhDevopsVM'
			#UserName = 'Administrator'
			#Password = 'Kottai2050$'
        
			
			WindowsFeatures = @(
              @{
			    Name = "FileAndStorage-Services"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Storage-Services"
				Ensure = "Present"
				IncludeAllSubFeature = $false

			  },
			  @{
			    Name = "Web-WebServer"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Common-Http"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Default-Doc"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Dir-Browsing"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Errors"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Static-Content"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-DAV-Publishing"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Health"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Logging"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name =  "Web-Request-Monitor"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Performance"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Stat-Compression"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Security"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name =  "Web-Filtering"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Cert-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Url-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Windows-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-App-Dev"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Net-Ext"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Net-Ext45"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Asp-Net45"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-CGI"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-ISAPI-Ext"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-ISAPI-Filter"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Mgmt-Console"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "NET-Framework-Features"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "NET-Framework-Core"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Redirect"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  }

			  
			)  
	    } <# #remove comments if you to add another node#,
		@{
			# target machine 2 
			
            NodeName ='KarthikDevops'
		    #UserName = 'Administrator'
			#Password = 'Kottai2050$'
			
			WindowsFeatures = @(
              @{
			    Name = "FileAndStorage-Services"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Storage-Services"
				Ensure = "Present"
				IncludeAllSubFeature = $false

			  },
			  @{
			    Name = "Web-WebServer"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Common-Http"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Default-Doc"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Dir-Browsing"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Errors"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Static-Content"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-DAV-Publishing"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Health"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Logging"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name =  "Web-Request-Monitor"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Performance"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Stat-Compression"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Security"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name =  "Web-Filtering"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Cert-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Url-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Windows-Auth"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-App-Dev"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Net-Ext"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Net-Ext45"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Asp-Net45"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-CGI"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-ISAPI-Ext"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-ISAPI-Filter"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Mgmt-Console"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "NET-Framework-Features"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "NET-Framework-Core"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  },
			  @{
			    Name = "Web-Http-Redirect"
				Ensure = "Present"
				IncludeAllSubFeature = $false
			  }

			  
			)  
		} #>
	)
}

Configuration InstallWindowsFeatures
{
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node $AllNodes.NodeName
    {        
      # Loop through the defined features
        ForEach($Feature in $Node.WindowsFeatures)
        {
          # Define component
            WindowsFeature $Feature.Name
            {
              Name = $Feature.Name
              Ensure = $Feature.Ensure
			  IncludeAllSubFeature =$Feature.IncludeAllSubFeature
            }
        }
    }
}

InstallWindowsFeatures -ConfigurationData $config_data
#Start-DscConfiguration -Path InstallWindowsFeatures -Wait -Force -Verbose