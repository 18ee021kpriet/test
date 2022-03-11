
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

Configuration UpdateAllDB { 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{       
        Script UpdateAllDB
        {
            SetScript = { 
				$ServerName = $env:COMPUTERNAME
				
				
				$DatabaseNames = @("vconnect","billing","hybr")
				
				
				$VconnectQuery = @("update AppSettings set value='http://localhost:31101' where [Key]='VConnectApiUrl'",
				
					"update AppSettings set value='cloudassertadminuser' where [Key]='VConnectApiUserName'",
				
					"update AppSettings set value='Kottai2050$' where [Key]='VConnectApiPassword'",
				
					"update AppSettings set value='http://localhost:30045' where [Key]='BillingApiEndpoint'",
				
					"update AppSettings set value='http://localhost:31101' where [Key]='VConnectApiEndpoint'",
				
					"update AppSettings set value='https:\\demo.admin.hybr.com' where [Key]='HybrApiEndpoint'",
				
					"update AppSettings set value='cloudassert' where [Key]='BillingApiKey'",
				
					"update AppSettings set value='cloudassert' where [Key]='HybrApiUsername'",
				
					"update AppSettings set value='Kottai2050$' where [Key]='HybrApiPassword'",
				
					"update AppSettings set value='Kottai2050$' where [Key]='VConnectApiSecret'" )
				
				
				#Action of connecting to the Database and executing the query and returning results if there were any.
				
				$conn = New-Object System.Data.SqlClient.SQLConnection
				
				
				
				foreach ($Database in $DatabaseNames) {
				
				$connString = "Server=$ServerName;Database=$Database;User ID='sa';Password=Kottai2050$"
				
				$conn.ConnectionString = $connString
				
				$conn.Open()
				
				foreach ($Query in $VconnectQuery) {
				
					$cmd = New-Object system.Data.SqlClient.SqlCommand($Query, $conn)
				
					$cmd.CommandTimeout = $QueryTimeout
				
					$ds = New-Object system.Data.DataSet
				
					$da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
				
					[void]$da.fill($ds)
				
				}
				
				$conn.Close()
				
				$ds.Tables
				}
				Write-Output "success"
				


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
UpdateAllDB -ConfigurationData $config_data
##Start-DscConfiguration -Path UpdateAllDB -Wait -Force -Verbose