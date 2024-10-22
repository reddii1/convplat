# Configures the below advanced settings in OMS
# 1. Collect Windows System and Application Event Logs.
# 2. Collect IIS Logs.
# 3. Configures Windows Performance Counters.
# 4. Configures Linux Performance Counters.

# Terraform Replaces Params
$tenant_id = "${tenant_id}"
$subcription_id = "${subcription_id}"
$workspace_resource_group = "${workspace_resource_group}"
$workspace_name = "${workspace_name}"
$automation_account_id = "${automation_account_id}"
$spn_id = "${spn_id}"
$spn_pw = "${spn_pw}"

# Prompt for Terraform
Write-Host "!!! LOGIN TO POWERSHELL SESSION !!!" -ForegroundColor Red

#Install and Import Az Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name Az -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name Az -AllowClobber -Force -Confirm:$false
    Import-Module -Name Az
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""

#Login to Azure
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
$username = $spn_id
$password = ConvertTo-SecureString $spn_pw -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)
Connect-AzAccount -Credential $Credential -Tenant '96f1f6e9-1057-4117-ac28-80cdfe86f8c3' -ServicePrincipal 
Set-AzContext -SubscriptionId "Cloud Services Shared Serv Dev"
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
get-AzContext
Write-Output ""

# Pull in Service Principal Info from KeyVault
# Write-Output "Gathering Service Principal Details from KeyVault..."
# $APP_ID = Get-AzKeyVaultSecret -VaultName "kv-dwp-cds-dev-ss" -Name "prdSsDeploymentSpnAppId"
# $APP_SECRET = Get-AzKeyVaultSecret -VaultName "kv-dwp-cds-dev-ss" -Name "prdSsDeploymentSpnClientSecret"
# $APP_SECRET = ConvertTo-SecureString $APP_SECRET.SecretValueText -AsPlainText -Force
# $CREDENTIAL = New-Object System.Management.Automation.PSCredential ($APP_ID.SecretValueText, $APP_SECRET)

# Login via Service Principal
Write-Output "Logging in via Service Principal..."
Connect-AzAccount -Credential $Credential -Tenant $tenant_id -ServicePrincipal
Write-Output "Successfully Logged in via Service Principal"

#Select SubscriptionId
while ($subcription_id.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $subcription_id = Read-Host "Please input your Subscription Id"
}
Select-AzSubscription -SubscriptionId $subcription_id
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""

# Get OMS Workspace
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting OMS Workspace Object..."
$oms_workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspace_resource_group -Name $workspace_name
Write-Output "Worspace: $($oms_workspace.Name)"
Write-Output "$($oms_workspace.ResourceId)"
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] OMS Workspace obtained for $($oms_workspace.Name)"
Write-Output ""

# Configure Automation Account Logging
# Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Configuring Automation Account..."
# Set-AzDiagnosticSetting -ResourceId $automation_account_id -WorkspaceId $oms_workspace.ResourceId -Enabled 1
# Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Automation Account Configured Successfully."
# Write-Output ""

# Collect Windows System and Application Event Logs
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding System and Application Event Logs to OMS Workspace..."
New-AzOperationalInsightsWindowsEventDataSource -Force -Workspace $oms_workspace -Name "System Logs" `
    -EventLogName "System" -CollectErrors -CollectWarnings -CollectInformation

New-AzOperationalInsightsWindowsEventDataSource -Force -Workspace $oms_workspace -Name "Application Logs" `
    -EventLogName "Application" -CollectErrors -CollectWarnings -CollectInformation
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Windows Event Logs Configured Successfully."
Write-Output ""

# Collect IIS Logs.
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding IIS Logs to OMS Workspace..."
Enable-AzOperationalInsightsIISLogCollection -Workspace $oms_workspace
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] IIS Logs Configured Successfully."
Write-Output ""

# Configures Windows Performance Counters
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding Windows Performance Counters to OMS Workspace..."
New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Avg Disk Sec Reads" -CounterName "Avg. Disk sec/Read" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Avg Disk Sec Writes" -CounterName "Avg. Disk sec/Write" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Queue Length" -CounterName "Current Disk Queue Length" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Read per Second" -CounterName "Disk Reads/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Transfers per Second" -CounterName "Disk Transfers/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Writes per Second" -CounterName "Disk Writes/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Free Space MB" -CounterName "Free Megabytes" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "LogicalDisk" -InstanceName "*" `
    -Name "Disk Free Space Percent" -CounterName "% Free Space" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Memory" `
    -Name "Memory Free MB" -CounterName "Available MBytes" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Memory" `
    -Name "Memory Used Percent" -CounterName "% Committed Bytes In Use" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Memory" `
    -Name "Memory Paging" -CounterName "Pages/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Adapter" -InstanceName "*" `
    -Name "Adapter Bytes Received" -CounterName "Bytes Received/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Adapter" -InstanceName "*" `
    -Name "Adapter Bytes Sent" -CounterName "Bytes Sent/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Adapter" -InstanceName "*" `
    -Name "Adapter Bytes Total" -CounterName "Bytes Total/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Interface" -InstanceName "*" `
    -Name "NIC Bytes Received" -CounterName "Bytes Received/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Interface" -InstanceName "*" `
    -Name "NIC Bytes Sent" -CounterName "Bytes Sent/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Network Interface" -InstanceName "*" `
    -Name "NIC Bytes Total" -CounterName "Bytes Total/sec" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "Processor" -InstanceName "*" `
    -Name "CPU Time Percent" -CounterName "% Processor Time" -IntervalSeconds 60

New-AzOperationalInsightsWindowsPerformanceCounterDataSource -Force  -Workspace $oms_workspace -ObjectName "System" `
    -Name "CPU Queue Length" -CounterName "Processor Queue Length" -IntervalSeconds 60

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Windows Performance Counters Configured Successfully"
Write-Output ""

# Configures Linux Performance Counters
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding Linux Performance Counters to OMS Workspace..."
Enable-AzOperationalInsightsLinuxPerformanceCollection -Workspace $oms_workspace

New-AzOperationalInsightsLinuxPerformanceObjectDataSource -Force -Workspace $oms_workspace -ObjectName "Processor" -InstanceName "*" -Name "CPU" `
    -IntervalSeconds 60 -CounterNames @("% Processor Time", "% Idle Time")

New-AzOperationalInsightsLinuxPerformanceObjectDataSource -Force -Workspace $oms_workspace -ObjectName "Logical Disk" -InstanceName "*" -Name "Disk" `
    -IntervalSeconds 60 -CounterNames @("% Free Inodes", "% Used Inodes", "% Free Space", "% Used Space", "Free Megabytes", "Disk Reads/sec", "Disk Writes/sec", "Disk Transfers/sec")

New-AzOperationalInsightsLinuxPerformanceObjectDataSource -Force -Workspace $oms_workspace -ObjectName "Memory" -InstanceName "*" -Name "Memory" `
    -IntervalSeconds 60 -CounterNames @("% Available Memory", "% Used Memory", "Available MBytes Memory", "Used Memory MBytes", "Pages/sec")

New-AzOperationalInsightsLinuxPerformanceObjectDataSource -Force -Workspace $oms_workspace -ObjectName "Network" -InstanceName "*" -Name "Network" `
    -IntervalSeconds 60 -CounterNames @("Total Bytes", "Total Bytes Received", "Total Bytes Transmitted")

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Linux Performance Counters Configured Successfully"
Write-Output ""
