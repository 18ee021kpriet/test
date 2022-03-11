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

Configuration VconnectInstall {   

    param ( <#
    #[Parameter(Mandatory=$true)] 
	[string]
	$BuildDropPath="C:\hybrinstall\33312",

	#[Parameter(Mandatory=$True)] 
	#[string] 
	#$dbServerName=$env:COMPUTERNAME,
    #>

	[Parameter(Mandatory=$True)]
	[string]
	$dbServerUserName="sa",

	[Parameter(Mandatory=$True)]
	[string]
	$dbServerPassword="Kottai2050$",

	[Parameter(Mandatory=$True)]
	[string]
	$vconnectDatabaseName="vconnect"
    ) 

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{ 
     Script Install_Vconnect
        {
            SetScript = { 
                
                $dbServerName=$env:COMPUTERNAME 
				#$dbServerUserName="sa"
				#$dbServerPassword="Kottai2050$"
				#$vconnectDatabaseName="vconnect"
				$apiInstallerBuildPath = "C:\hybrinstall\33312\VConnect\CloudAssert.WAP.VConnect.Service.Setup.msi"
				#$adminExtensionInstallerBuildPath = $BuildDropPath + "\CloudAssert.WAP.VConnect.AdminExtension.Setup.msi"
				#$tenantExtensionInstallerBuildPath = $BuildDropPath + "\CloudAssert.WAP.VConnect.TenantExtension.Setup.msi"
				$vconnectToolBuildPath = "C:\hybrinstall\33312\VConnect\*"
				
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
				
				Function Install-Software ($installerPath,  $installerArgs)
				{
					Write-Host "Installing: $installerPath" -ForegroundColor Yellow
					$BaseName = Get-Item $installerPath | Select-Object -ExpandProperty BaseName
					$logFileName = $BaseName + "_Install.txt"
					$logFilePath = "C:\" + $logFileName
					$processArgs = ' /i ' + $installerPath +  ' ' + $installerArgs + " /passive /log $logFilePath"
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
				
				function Generate-IniFile () 
								{
									$iniData = @"
												[PROPERTIES]
												SERVICE_LOGON_TYPE=ServiceAccount
												SERVICE_DOMAIN=
												SERVICE_USERNAME=
												SERVICE_PASSWORD=
												DATABASE_SERVER_SELECT_MODE=CreateNewConfig
												DATABASE_SERVER=$dbServerName
												RUNTIME_DATABASE_NAME=$using:vconnectDatabaseName
												RUNTIME_DATABASE_USERNAME=$using:dbServerUserName
												RUNTIME_DATABASE_PASSWORD=$using:dbServerPassword
												RUNTIME_DB_CONNECTION_STRING=Data Source=$dbServerName;Initial Catalog=$using:vconnectDatabaseName; User Id=$using:dbServerUserName; password=$using:dbServerPassword;
"@
									$iniData | Out-File C:\hybrinstall\33312\VConnect\VConnectInitialize.ini
								}
				
				
				#Uninstall-Software "Cloud Assert VConnect Service"
				#Uninstall-Software "Cloud Assert VConnect AdminExtension"
				#Uninstall-Software "Cloud Assert VConnect Tenant Extension"
				
				Generate-IniFile
				
				Install-Software $apiInstallerBuildPath INIT_INI_FILE_PATH=C:\hybrinstall\33312\VConnect\VConnectInitialize.ini
				#Install-Software $adminExtensionInstallerBuildPath
				#Install-Software $tenantExtensionInstallerBuildPath
				stop-process -Name CloudAssert.WAP.VConnect.AgentService -Force
			}	
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }
    }
}

VconnectInstall -ConfigurationData $config_data
#Start-DscConfiguration -Path VconnectInstall -Wait -Force -Verbose