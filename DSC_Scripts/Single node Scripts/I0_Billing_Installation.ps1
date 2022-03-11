$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='DhivyaTest'
			
	    }
        
        
	)
}
Configuration Billinginstall { 

    Param( <#
    #[Parameter(Mandatory=$true)] 
    [string]
    $BuildDropPath = "C:\hybrinstall\Billing_2109.1.6",

    #[Parameter(Mandatory=$True)] 
    [string] 
    $dbServerName=$env:COMPUTERNAME, #>

    [Parameter(Mandatory=$True)]
    [string]
    $dbServerUserName= "sa",

    [Parameter(Mandatory=$True)]
    [string]
    $dbServerPassword = "Kottai2050$",

    [Parameter(Mandatory=$True)]
    [string]
    $billingDatabaseName = "billing"
    ) 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{   
		Script Remove_old_Billing_AgentService_msi
        {
            SetScript = { 
                
                Remove-Item –path 'C:\hybrinstall\Billing_2109.1.6\Billing\CloudAssert.WAP.Billing.AgentService.Setup.msi'
            }
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }

		xRemoteFile DownloadNewBillingAgentMsi 
        {
        URI = "https://cadownloads.blob.core.windows.net/release/billing/3.2112.1.7/Billing/CloudAssert.WAP.Billing.AgentService.Setup.msi"
        
        DestinationPath = "C:\hybrinstall\Billing_2109.1.6\Billing"
        }
	
        Script Install_Billing_Agent_API
        {
            SetScript = { 
				
				$dbServerName=$env:COMPUTERNAME
				#$dbServerUserName= "sa"
				#$dbServerPassword = "Kottai2050$"
				#$billingDatabaseName = "billing"
                $apiInstallerBuildPath = "C:\hybrinstall\Billing_2109.1.6\Billing\CloudAssert.WAP.Billing.Service.Setup.msi"
				$agentInstallerBuildPath = "C:\hybrinstall\Billing_2109.1.6\Billing\CloudAssert.WAP.Billing.AgentService.Setup.msi"
				$billingToolBuildPath = "C:\hybrinstall\Billing_2109.1.6\Billing\*"
				
				$createDirScript = {
					if(!(Test-Path $args[0]))
					{
						Write-Host 'Creating destination directory..'
						New-Item -ItemType Directory -Force -Path $args[0]
					}
				}
				
				Function Execute-Command ($commandPath, $commandArguments)
				{
					$pinfo = New-Object System.Diagnostics.ProcessStartInfo
					$pinfo.FileName = $commandPath
					$pinfo.RedirectStandardError = $true
					$pinfo.RedirectStandardOutput = $true
					$pinfo.UseShellExecute = $false
					$pinfo.Arguments = $commandArguments
					$p = New-Object System.Diagnostics.Process
					$p.StartInfo = $pinfo
					Write-Host 'Run: '  $pinfo.FileName $pinfo.Arguments
					$p.Start() | Out-Null
					$presult =@{
						stdout = $p.StandardOutput.ReadToEnd()
						stderr = $p.StandardError.ReadToEnd()
						ExitCode = $p.ExitCode  
					}
					$p.WaitForExit()
				
					if ( -not $?) {
							# Re-issue the last error in case of failure. This sets $?.
							# Note that the Global scope must be explicitly selected if the function is inside
							# a module. Selecting it otherwise also does not hurt.
							Write-Error  "ERROR running VConnect tool: $error[0]"
							exit -1
						}
				
					Write-Host ''
				
					if($presult['ExitCode'] -ne 0) {
						$errorMsg = "ERROR from command: " + $presult['stderr'] + $presult['stdout'] + '. ExitCode: ' + $presult['ExitCode'] 
						Write-Error  $errorMsg
						exit -1
					} else {
						Write-Host 'Completed running command Successfully !'  $args[0]  -ForegroundColor DarkGreen
						Write-Host 'ExitCode: ' $presult['ExitCode'] -ForegroundColor DarkGreen
						Write-Host '' -ForegroundColor DarkGreen
						Write-Host 'Output: ' $presult['stdout'] -ForegroundColor DarkGreen
						if(![string]::IsNullOrEmpty($presult['stderr'])){
							Write-Host 'Error: ' $presult['stderr'] -ForegroundColor Yellow
						}
					}
				}
				
				Function Uninstall-Software ($name)
				{
					$product = Get-WmiObject Win32_Product -Filter "Name = '$name'"
					if($product -ne $null) {
						Write-Host "Un-installing $name"
						$product.Uninstall()
						if ( -not $?) {
							Write-Error  "ERROR un-installting: $error[0]"
							exit -1
						}
						Write-Host "Completed Un-install!"
					}
				}
				
				Function Install-Software ($installerPath, $installerArgs)
				{
					Write-Host "Installing: $installerPath" -ForegroundColor Yellow
					$BaseName = Get-Item $installerPath | Select-Object -ExpandProperty BaseName
					$logFileName = $BaseName + "_Install.txt"
					$logFilePath = "C:\" + $logFileName
					$processArgs = ' /i ' + $installerPath + ' ' + $installerArgs + " /passive /log $logFilePath"
					Execute-Command msiexec $processArgs
					Write-Host ''
					Write-Host '----------------------------------------------------'
					Get-Content $logFilePath | Select-Object -last 5
					if (-not $?) {
						Write-Host  "ERROR installing msi: " + $error[0] -ForegroundColor Red
						exit -1
					}
					Write-Host ''
					Write-Host 'Installed !' -ForegroundColor DarkGreen
					Write-Host ''
					Write-Host '----------------------------------------------------'
				}
				
				function Generate-IniFile {
				    $iniData = @"
				[PROPERTIES]
				IIS_SERVICE_LOGON_TYPE=NotServiceAccount
				IIS_SERVICE_DOMAIN= 
				IIS_SERVICE_USERNAME= 
				IIS_SERVICE_PASSWORD= 
				IIS_APPPOOL_IDENITY_TYPE=ApplicationPoolIdentity
				IIS_APPPOOL_IDENITY= 
				SERVICE_LOGON_TYPE=ServiceAccount
				SERVICE_DOMAIN=wapdemo
				SERVICE_USERNAME=cloudassert
				SERVICE_PASSWORD=Kottai2050$
				DATABASE_SERVER=$dbServerName
				CREATE_DATABASE_USERNAME=$using:dbServerUserName
				CREATE_DATABASE_PASSWORD=$using:dbServerPassword
				DBSQLAUTH_USERNAME=$using:dbServerUserName
				DBSQLAUTH_PASSWORD=$using:dbServerPassword
				DBSQLAUTH_PASSWORD_CONFIRM=$using:dbServerPassword
				RUNTIME_DATABASE_NAME=$using:billingDatabaseName
				RUNTIME_DATABASE_USERNAME=$using:dbServerUserName
				RUNTIME_DATABASE_PASSWORD=$using:dbServerPassword
				RUNTIME_DB_CONNECTION_STRING=Data Source=$dbServerName;Initial Catalog=$using:billingDatabaseName;User Id=$using:dbServerUserName;password=$using:dbServerPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
				;RUNTIME_DB_CONNECTION_STRING=Data Source=$dbServerName;Initial Catalog=$using:billingDatabaseName; Integrated Security=True;
				UANDB_API_URL=http://localhost:30045/
				UANDB_API_USERNAME=cloudassert
				UANDB_API_PASSWORD=Kottai2050$
				UANDB_API_PASSWORD_CONFIRM=Kottai2050$
"@
					$iniData | Out-File C:\hybrinstall\Billing_2109.1.6\Billing\Initialize.ini
				}
				
				
				#Stop-Process -Name CloudAssert.WAP.Billing.AgentService -Force
				#Uninstall-Software "Cloud Assert Usage and Billing - Agent Service"
				#Uninstall-Software "Cloud Assert Usage and Billing - API Service"
				#Uninstall-Software "Cloud Assert Usage and Billing - WAP Tenant Extension"
				#Uninstall-Software "Cloud Assert Usage and Billing - WAP Admin Extension"
				
				Generate-IniFile
				
				Install-Software $apiInstallerBuildPath INIT_INI_FILE_PATH=C:\hybrinstall\Billing_2109.1.6\Billing\Initialize.ini
				Install-Software $agentInstallerBuildPath INIT_INI_FILE_PATH=C:\hybrinstall\Billing_2109.1.6\Billing\Initialize.ini
				#Install-Software $adminExtensionInstallerBuildPath
				#Install-Software $tenantExtensionInstallerBuildPath
			}	
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }
    }
}

Billinginstall -ConfigurationData $config_data
#Start-DscConfiguration -Path Billinginstall -Wait -Force -Verbose

