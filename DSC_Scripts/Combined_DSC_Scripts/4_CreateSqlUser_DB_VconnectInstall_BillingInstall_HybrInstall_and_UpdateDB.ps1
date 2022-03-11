$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='AnadhDevopsVM'
			
	    },
        @{
            NodeName ='enter the 2nd target nodename'
        }
        
	)
}

Configuration CreateSqlUser_DB_VconnectInstall_BillingInstall_HybrInstall_and_UpdateDB
{
    param
    (        
        #[Parameter(Mandatory = $true)]
        #[string]$dbServerName,
        
        #[Parameter(Mandatory = $true)]
        #[string]$dbServerName,
        
        [Parameter(Mandatory = $true)]
        [string]$dbServerUserName,
        #dbServerUserName = sa
        
        [Parameter(Mandatory = $true)]
        [string]$dbServerPassword,
        #dbServerPassword = Kottai2050$
        
        [Parameter(Mandatory = $true)]
        [string]$vconnectDatabaseName,
        #$vconnectDatabaseName=vconnect

        #[Parameter(Mandatory = $true)]
        #[bool]$setupBillingAndDacm,

        #[Parameter(Mandatory =$false)]
        #[string]$billingDbName,

        #[Parameter(Mandatory =$false)]
        #[string]$dacmDbName,

        [Parameter(Mandatory = $true)]
        [string]$billingDatabaseName,
        #$billingDatabaseName = billing

        [Parameter(Mandatory = $true)]
        [string]$hybrDatabaseName,
        #$hybrDatabaseName = hybr

        [Parameter(Mandatory =$false)]
        [string]$sqlPort
    )

    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
    {
        $extractedPath
        $thumbprint
        
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
        }        
        
        Script Setup_SqlServer
        {
            SetScript = {  
        
                $dbServerName=$env:COMPUTERNAME

                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                
                if ($using:dbServerName -eq $using:dbServerName)
                {
                    Set-Service -Name SQLSERVERAGENT -StartupType Automatic
                    Restart-Service -Force MSSQLSERVER
                    Restart-Service -Force SQLSERVERAGENT
                    
                    do 
                    {   
                        sleep 5
                        $sqlSvc = Get-Service -Name MSSQLSERVER
                        $sqlAgentSvc = Get-Service -Name SQLSERVERAGENT
                    } until (($sqlSvc.Status -eq 'Running') -and ($sqlAgentSvc.Status -eq 'Running'))
                    
                    Import-Module SQLPS

                    # Set Port
                    $machine = new-object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' $using:dbServerName
                    $instance = $machine.ServerInstances[ 'MSSQLSERVER' ];
                    $ipAll = $instance.ServerProtocols['Tcp'].IPAddresses['IPAll'];
                    $ipAll.IPAddressProperties['TcpPort'].Value = $using:sqlPort;
                    $instance.ServerProtocols['Tcp'].Alter();
                    Restart-Service -Force MSSQLSERVER
                    write-verbose "SQL port set"

                    do 
                    {   
                        sleep 5
                        $svc = Get-Service -Name MSSQLSERVER
                    } until ($svc.Status -eq 'Running')
                    
                    $srv = New-Object Microsoft.SqlServer.Management.Smo.Server("(local)")

                    # Enable Mixed Mode 
                    $srv.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
                    $srv.Alter()
                    Restart-Service -Force MSSQLSERVER
                    write-verbose "Enabled Mixed mode"

                    do 
                    {   
                        sleep 5
                        $svc = Get-Service -Name MSSQLSERVER
                    } until ($svc.Status -eq 'Running')

                    $user = $srv.Logins | ? {$_.Name -eq $using:dbServerUserName}
                    if ($user -ne $null)
                    {   
                        $user.ChangePassword($dbServerPassword)
                        $user.PasswordPolicyEnforced = 1;
                        $user.Enable()
                        $user.Alter();
                        $user.Refresh();
                        Write-verbose "Modified password"
                    }
                    else 
                    {
                        # Create SQL Login
                        write-verbose "Creating SQL Login User: $using:dbServerUserName"
                        $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $srv, $using:dbServerUserName
                        $login.LoginType = 'SqlLogin'
                        $login.PasswordExpirationEnabled = $false
                        $login.Create($using:dbServerPassword)
                        $srv.Roles["sysadmin"].AddMember($using:dbServerUserName)
                        Write-verbose "Created SQL login"
                    }
                }

                # allow TCP Port in Firewall
                netsh advfirewall firewall add rule name="SQL Inbound Rule" dir=in action=allow protocol=TCP localport=$using:sqlPort
            }

            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                try {
                    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                    $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)    
                    $db = $srv.Databases | ? {$_.Name -eq $using:vconnectDatabaseName}
                    return -not(-not $db)
                }
                catch
                {
                    return $false
                }
            }

            GetScript = {
            }
            #DependsOn = "[Script]Configure_VConnect"
        }   

        Script Setup_VConnectDatabase
        {
            SetScript = {     
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                                
                $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
                
                # Create VConnect Database
                $db = New-Object Microsoft.SqlServer.Management.Smo.Database($srv, $using:vconnectDatabaseName)
                $db.Create()
                Write-verbose "Created new database $using:vconnectDatabaseName"
            }

            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                try {
                    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                    $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)    
                    $db = $srv.Databases | ? {$_.Name -eq $using:vconnectDatabaseName}
                    return -not(-not $db)
                }
                catch
                {
                    return $false
                }
            }

            GetScript = {
            }
            DependsOn = "[Script]Setup_SqlServer"
        }   
        Script Setup_BillingDatabase
        {
            SetScript = {     
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                                
                $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
                
                # Create VConnect Database
                $db = New-Object Microsoft.SqlServer.Management.Smo.Database($srv, $using:billingDatabaseName)
                $db.Create()
                Write-verbose "Created new database $using:billingDatabaseName"
            }

            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                try {
                    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                    $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)    
                    $db = $srv.Databases | ? {$_.Name -eq $using:billingDatabaseName}
                    return -not(-not $db)
                }
                catch
                {
                    return $false
                }
            }

            GetScript = {
            }
            DependsOn = "[Script]Setup_SqlServer"
        }


        Script Setup_HybrDatabase
        {
            SetScript = {     
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                                
                $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
                
                # Create VConnect Database
                $db = New-Object Microsoft.SqlServer.Management.Smo.Database($srv, $using:hybrDatabaseName)
                $db.Create()
                Write-verbose "Created new database $using:hybrDatabaseName"
            }

            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Common')
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
                try {
                    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection($using:dbServerName, $using:dbServerUserName, $using:dbServerPassword)
                    $srv = new-object Microsoft.SqlServer.Management.Smo.Server($conn)    
                    $db = $srv.Databases | ? {$_.Name -eq $using:hybrDatabaseName}
                    return -not(-not $db)
                }
                catch
                {
                    return $false
                }
            }

            GetScript = {
            }
            DependsOn = "[Script]Setup_SqlServer"
        }
        
        #vconnect
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

        Script UpdateVConnectDB
        {
            SetScript = { 
                
				$serverName = $env:COMPUTERNAME;
				cd /
				cd C:\hybrinstall\33312\VConnect\VConnect_Tools
				$VconnectPass = ./VConnect.exe HashPass Kottai2050$
				$pass = $VconnectPass[9]
				Start-Sleep -Seconds 10
				#2 "CAAAANWExV+kaZZ4FbT+6RLUE1RvxEhy59uJSnU0TRY1KbxUB3Tp8PnfOXA="" - different for different hashpassword
				$file = 'C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config'
				$regex = '(?<=<add key="Password" value=")[^"]*'
				(Get-Content $file) -replace $regex, "$pass" | Set-Content $file
				Start-Sleep -Seconds 10
				# (Get-Content C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config).replace('<add key="Password" value="CAAAANWExV+kaZZ4FbT+6RLUE1RvxEhy59uJSnU0TRY1KbxUB3Tp8PnfOXA=" />', "<add key=`"Password`" value= `"$($pass)`" />") | Set-Content C:\inetpub\MgmtSvc-CloudAssert-Vconnect\Web.config
				#3
				./VConnect.exe UpdateDatabaseSettings $serverName vconnect sa Kottai2050$ /isUseIntegratedSecurity:false /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				./VConnect.exe UpdateDatabaseSettings $serverName vconnect sa Kottai2050$ /isUseIntegratedSecurity:false /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				#4 WIN-G0FP1SQCPCI-MachineName different for different machines or vm administrator-username of vm
				./VConnect.exe UpdatePowerShellSettings $serverName 5985 false .\administrator Kottai2050$ /VConnectApiEndpoint:http://localhost:31101 /VConnectApiUserName:cloudassertadminuser /VConnectApiPassword:Kottai2050$
				Start-Sleep -Seconds 20
				#5
				cmd /c "winrm set winrm/config/client @{TrustedHosts =`"IP_Address`"}"

            }
             TestScript = {
                return $false
            }

            GetScript = {
            }

            DependsOn = "[Script]Setup_VConnectDatabase"
        }
         

        #billing 
        Script Remove_Billing_msi
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

        Script UpdateBilling
        {
            SetScript = { 
				#Redirecting to installer folder
				#$serverName= $env:COMPUTERNAME;
				
				cd /
				cd C:\hybrinstall\Billing_2109.1.6\Billing\Tool
				#1
				./Billing.exe UpdateDatabase /ApiEndpoint:http://localhost:30045 /Username:cloudassert /Password:Kottai2050$
				#2 open API – C:\inetpub\MgmtSvc-CloudAssertBilling\Web.Config
				#.\Billing.exe UpdateDatabase /ApiEndpoint:http://localhost:30045 /Username:cloudassertadminuser /Password:Kottai2050$
            }
             TestScript = {
                return $false
            }

            GetScript = {
            }

            DependsOn = "[Script]Setup_BillingDatabase"
        }

        #hybr
        Script Install_hybr
        {
            SetScript = { 
                $dbServerName=$env:COMPUTERNAME
                $dbServerInstance=$env:COMPUTERNAME
				#$dbServerUserName="sa"
				#$dbServerPassword="Kottai2050$"
				#$hybrDatabaseName="hybr"
				$AAD_CLIENT_ID="480506cd-cccb-4969-b4f5-5399bca7c633"
				$AAD_CLIENT_SECRET="+D1ZbEtP2FmX7eC8omxsC0gcFeOGmC82/FcwfIxWpfg="
				$SubDomainName="Demo"
				$Orgname="Demo"
				$AdminUserMail="cloudadmin@cloudiorg.onmicrosoft.com"
				$Issuer_URL="https://sts.windows.net/74ebaa91-4689-4532-89de-1098b3a042f2/"
				$HybrApiKey="cloudassert"
				$HybrApiSecret="Kottai2050$"
				$BuildDropPath="C:\hybrinstall\202110810.9"
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Install-Module -Name SqlServer -AllowClobber  -Verbose
                #$apiInstallerBuildPath = $BuildDropPath + "\Trisul.Setup.msi"
                #$billingToolBuildPath = $BuildDropPath + "\CAHybr\*"
                $apiInstallerBuildPath = "C:\hybrinstall\202110810.9\Trisul.Setup.msi"
                $billingToolBuildPath = "C:\hybrinstall\202110810.9\CAHybr\*"
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
                
                function Generate-IniFile
                {
                    $iniData = @"
                    [Properties]
                    INSTALLFOLDER=C:\inetpub\CAHybr\
                    UTILITYFOLDER=C:\inetpub\CAHybr\Scripts\DeployScripts\OrgAdminCli\
                    VCONNECT_TOOL_PATH=
                
                    [AuthProvider]
                    ORG_AUTH_TYPE=AAD
                    AAD_CLIENT_ID=$AAD_CLIENT_ID
                    AAD_CLIENT_SECRET=$AAD_CLIENT_SECRET
                    ADFS_AUTHORITY=
                    ADFS_METADATA_ADDRESS=
                    ADFS_CLIENT_ID=
                    ADFS_CLIENT_SECRET=
                
                    [DBConfig]
                    DATABASE_SERVER=$dbServerName
                    RUNTIME_DATABASE_USERNAME=$using:dbServerUserName
                    RUNTIME_DATABASE_PASSWORD=$using:dbServerPassword
                    RUNTIME_DATABASE_NAME=$using:hybrDatabaseName
                    IS_AZURE_DB=0
                    SUB_DOMAIN_NAME=$SubDomainName
                    SHOULD_SETUP_ADMIN_ORG_ACCOUNT=1
                
                    [AdminOrg]
                    ADMIN_ORG_AUTH_TYPE=AAD
                    ORG_STORAGE_CONNECTION=DefaultEndpointsProtocol=https;AccountName=[REPLACE_ACCOUNT_NAME];AccountKey=[REPLACE_ACCOUNT_KEY];EndpointSuffix=core.windows.net
                    ADMIN_USER_MAIL=$AdminUserMail
                    ORG_NAME=$Orgname
                    ISSUER_URL=$Issuer_URL
                
                    [IISConfig]
                
                    [ServiceConfig]
                    SHOULD_CONFIGURE_VCONNECT=1
                    IS_VCONNECT_ONLY_FOR_WORKFLOW=0
                    VCONNECT_ENDPOINT=http://localhost:31101
                    VCONNECT_API_KEY=cloudassertadminuser
                    VCONNECT_API_SECRET=Kottai2050$
                    VCONNECT_STORAGE_QUEUE=
                    SHOULD_CONFIGURE_BILLING=1
                    BILLING_ENDPOINT=http://localhost:30045
                    BILLING_API_KEY=cloudassert
                    BILLING_API_SECRET=Kottai2050$
                    BILLING_STORAGE_QUEUE=
                    SHOULD_ENABLE_CLOUD_SERVICES=1
                    SHOULD_CONFIGURE_SERVICE_CATALOG=1
                    SERVICE_CATALOG_DB_CONNECTIONSTRING=Data Source=$dbServerName;Initial Catalog=$using:hybrDatabaseName;User ID=$using:dbServerUserName;Password=$using:dbServerPassword;
                    HYBR_ENDPOINT=
                    HYBR_API_KEY=$HybrApiKey
                    HYBR_API_SECRET=$HybrApiSecret
                
                    [RMS]
                    RMS_CONFIGURE_DB=1
                    RMS_DATABASE_SERVER=$dbServerName
                    RMS_DATABASE_USERNAME=$using:dbServerUserName
                    RMS_DATABASE_PASSWORD=$using:dbServerPassword
                    RMS_DB_STORE_NAME=$RMSStoreDB
                    RMS_DB_RM_NAME=$RMSResoruceManagerDB
                    RMS_DB_TRACKING_NAME=$RMSTrackingDB
                
                    [SMTP]
                    SMTP_SERVER_NAME=$SMTPServername
                    SMTP_PORT=$SMTPPortNo
                    SMTP_USER_NAME=$SMTPUserName
                    SMTP_PASSWORD=$STMPPassword
                    SMTP_FROM=$SMTPFrom
                    SMTP_IS_USE_SSL=True
                
                    [IMAP]
                    IMAP_SERVER_NAME=
                    IMAP_PORT=
                    IMAP_USER_NAME=
                    IMAP_PASSWORD=
                    IMAP_IS_USE_SSL=True
"@
                    $iniData | Out-File C:\hybrinstall\202110810.9\Initialize.ini
                }
                
                
                #Stop-Process -Name CloudAssert.WAP.Billing.AgentService -Force
                #Uninstall-Software "Cloud Assert Usage and Billing - Agent Service"
                #Uninstall-Software "Cloud Assert Usage and Billing - API Service"
                #Uninstall-Software "Cloud Assert Usage and Billing - WAP Tenant Extension"
                #Uninstall-Software "Cloud Assert Usage and Billing - WAP Admin Extension"
                
                Generate-IniFile
                
                Install-Software $apiInstallerBuildPath INIT_INI_FILE_PATH=C:\hybrinstall\202110810.9\Initialize.ini
                #Install-Software $agentInstallerBuildPath INIT_INI_FILE_PATH=$BuildDropPath\Initialize.ini
                #Install-Software $adminExtensionInstallerBuildPath
                #Install-Software $tenantExtensionInstallerBuildPath
            }
            TestScript = {
                return $false
            }

            GetScript = {
            }
        }
        
        <#
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

            DependsOn = "[Script]Setup_HybrDatabase"
        } #>

    }
}

CreateSqlUser_DB_VconnectInstall_BillingInstall_HybrInstall_and_UpdateDB -ConfigurationData $config_data 
#Start-DscConfiguration -Path CreateSqlUser_DB_VconnectInstall_BillingInstall_HybrInstall_and_UpdateDB -Wait -Force -Verbose