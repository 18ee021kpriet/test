$config_data = @{
	AllNodes = @(
	    @{
			NodeName ='AnadhDevopsVM'
			
	    }
        
	)
}

Configuration SetupSqlServer
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

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
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
    }
}

SetupSqlServer -ConfigurationData $config_data 
#Start-DscConfiguration -Path SetupSqlServer -Wait -Force -Verbose