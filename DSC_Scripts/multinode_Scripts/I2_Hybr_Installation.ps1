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

Configuration hybrinstall {   
    
    param (

    #[string]$dbServerName=$env:COMPUTERNAME
    [Parameter(Mandatory =$true)]
    [string]$dbServerUserName="sa" ,

    [Parameter(Mandatory =$true)]
    [string]$dbServerPassword="Kottai2050$" ,

    [Parameter(Mandatory =$true)]
    [string]$hybrDatabaseName="hybr"
<#
    [Parameter(Mandatory =$true)]
    [string]$AAD_CLIENT_ID="480506cd-cccb-4969-b4f5-5399bca7c633"

    [Parameter(Mandatory =$true)]
    [string]$AAD_CLIENT_SECRET="+D1ZbEtP2FmX7eC8omxsC0gcFeOGmC82/FcwfIxWpfg="

    [Parameter(Mandatory =$true)]
    [string]$SubDomainName="Demo"
     
    [Parameter(Mandatory =$true)]
    [string]$Orgname="Demo"
    
    [Parameter(Mandatory =$true)]
    [string]$AdminUserMail="cloudadmin@cloudiorg.onmicrosoft.com"

    [Parameter(Mandatory =$true)]
    [string]$Issuer_URL="https://sts.windows.net/74ebaa91-4689-4532-89de-1098b3a042f2/"

    [Parameter(Mandatory =$true)]
    [string]$HybrApiKey="cloudassert",

    [Parameter(Mandatory =$true)]
    [string]$HybrApiSecret="Kottai2050$"
    [Parameter(Mandatory =$true)]
    [string]$BuildDropPath="C:\hybrinstall\202110810.9" #>

    )  
    Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    #Import-DscResource -ModuleName @{ModuleName="xPSDesiredStateConfiguration";ModuleVersion=" 9.1.0"}
    Node $AllNodes.NodeName
	{ 
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
    }
}

hybrinstall -ConfigurationData $config_data
#Start-DscConfiguration -Path hybrinstall -Wait -Force -Verbose



