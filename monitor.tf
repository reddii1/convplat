
## Resources

## Action Groups #########################################################

provider "azurerm" {
  features {}
  subscription_id            = terraform.workspace == "prod" ? "d485e879-936d-42a4-8c08-e6d5edf1e0e0" : terraform.workspace == "stag" ? "3f3211cf-dd73-44d2-947c-dd279aae767b" : "3f3211cf-dd73-44d2-947c-dd279aae767b"
  alias                      = "ts-sre-prod"
  skip_provider_registration = "true"
}

# TODO use pdu spn for bmc action group
data "azurerm_monitor_action_group" "bmc_action_group" {
  count               = terraform.workspace == "prod" || terraform.workspace == "stag" ? 1 : 0
  provider            = azurerm.ts-sre-prod
  resource_group_name = terraform.workspace == "prod" ? "rg-dwp-bmc-prod-dw-ts-core" : terraform.workspace == "stag" ? "rg-dwp-bmc-stag-dw-ts-core" : "rg-dwp-bmc-devt-dw-ts-core"
  name                = "Azure BMC Integration"
}

# Action Group - SRE Team
resource "azurerm_monitor_action_group" "action_group_sre_dwp" {
  name                = "SRE PagerDuty"
  resource_group_name = azurerm_resource_group.rg_oms.name

  short_name = "SREPagerDuty"
  enabled    = var.sre_team_alert_status[terraform.workspace]

  webhook_receiver {
    name        = "PagerDuty"
    service_uri = var.sre_team_webhook[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Action Group - SRE Team Email
resource "azurerm_monitor_action_group" "action_group_sre_email_dwp" {
  name                = "SRE Team Email"
  resource_group_name = azurerm_resource_group.rg_oms.name

  short_name = "SRE Email"
  enabled    = var.sre_team_alert_status[terraform.workspace]

  email_receiver {
    name          = "SRE Team Email"
    email_address = var.sre_team_email[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Action Group - APP Team
resource "azurerm_monitor_action_group" "action_group_app_dwp" {
  name                = "App Team"
  resource_group_name = azurerm_resource_group.rg_oms.name

  short_name = "App Team"
  enabled    = var.app_team_alert_status[terraform.workspace]

  email_receiver {
    name          = "APP Team Email"
    email_address = var.app_team_email[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Action Group - SecMon
resource "azurerm_monitor_action_group" "action_group_secmon_dwp" {
  name                = "Security Monitoring Team"
  resource_group_name = azurerm_resource_group.rg_oms.name
  short_name          = "SecMon Team"
  enabled             = var.secmon_team_alert_status[terraform.workspace]

  email_receiver {
    name                    = "Security Monitoring Team Email"
    email_address           = var.secmon_team_email[terraform.workspace]
    use_common_alert_schema = true
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_action_group" "cp_alerts_slack_nonprod" {
  count               = terraform.workspace == "prod" || terraform.workspace == "stag" ? 0 : 1
  name                = "Conversational Platform Slack Action Group NonProd"
  resource_group_name = azurerm_resource_group.rg_oms.name
  short_name          = "CP Slack NP"
  tags                = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })

  email_receiver {
    name                    = "CP Alert NonProd"
    email_address           = var.slack_email_address_nonprod
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_action_group" "cp_alerts_slack_prod" {
  count               = terraform.workspace == "prod" || terraform.workspace == "stag" ? 1 : 0
  name                = "Conversational Platform Slack Action Group Prod"
  resource_group_name = azurerm_resource_group.rg_oms.name
  short_name          = "CP Slack Prd"
  tags                = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })

  email_receiver {
    name                    = "CP Alert Prod"
    email_address           = var.slack_email_address_prod
    use_common_alert_schema = true
  }
}

locals {
  bmc_action_group = terraform.workspace == "prod" || terraform.workspace == "stag" ? data.azurerm_monitor_action_group.bmc_action_group[0].id : null

  non_production_action_group_list = [{
    action_group_id = terraform.workspace == "sbox" || terraform.workspace == "devt" || terraform.workspace == "test" ? azurerm_monitor_action_group.cp_alerts_slack_nonprod[0].id : null
  }]

  production_action_group_list = [{
    action_group_id = terraform.workspace == "prod" || terraform.workspace == "stag" ? azurerm_monitor_action_group.cp_alerts_slack_prod[0].id : null
  },
    {
      action_group_id = local.bmc_action_group
  }]
  action_group_list = terraform.workspace == "prod" || terraform.workspace == "stag" ? local.production_action_group_list : local.non_production_action_group_list
}

## Metric Alerts #########################################################

# VM Offline - detection via CPU rather than Heartbeat
resource "azurerm_monitor_metric_alert" "metric_alert_vm_offline_no_cpu" {
  name                = "VM Offline"
  enabled             = true
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_log_analytics_workspace.oms.id]
  description         = "A VM appears to be offline.  No CPU activity detetcted."
  frequency           = "PT5M"
  window_size         = "PT15M"
  severity            = 2
  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Processor Time"
    aggregation      = "Average"
    operator         = "LessThanOrEqual"
    threshold        = 0
    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }
  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM CPU Warning
resource "azurerm_monitor_metric_alert" "metric_alert_vm_cpu_warning" {
  name                = "VM CPU Warning"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine CPU is greater than 85%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 3

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Processor Time"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM CPU Critical
resource "azurerm_monitor_metric_alert" "metric_alert_vm_cpu_critical" {
  name                = "VM CPU Critical"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine CPU is greater than 95%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Processor Time"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Memory Warning (Linux)
resource "azurerm_monitor_metric_alert" "metric_alert_vm_mem_warning_linux" {
  name                = "VM Memory Warning (Linux)"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Memory is greater than 85%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 3

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Used Memory"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Memory Critical (Linux)
resource "azurerm_monitor_metric_alert" "metric_alert_vm_mem_critical_linux" {
  name                = "VM Memory Critical (Linux)"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Memory is greater than 95%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Used Memory"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Memory Warning (Windows)
resource "azurerm_monitor_metric_alert" "metric_alert_vm_mem_warning_windows" {
  name                = "VM Memory Warning (Windows)"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Memory is greater than 85%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 3

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Committed Bytes In Use"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Memory Critical (Windows)
resource "azurerm_monitor_metric_alert" "metric_alert_vm_mem_critical_windows" {
  name                = "VM Memory Critical (Windows)"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Memory is greater than 95%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Committed Bytes In Use"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Excessive Paging
resource "azurerm_monitor_metric_alert" "metric_alert_vm_paging" {
  name                = "VM Excessive Paging"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Paging is greater than 10000 per Second"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 3

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_Pages/sec"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 10000

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Disk Space Warning
resource "azurerm_monitor_metric_alert" "metric_alert_vm_disk_space_warning" {
  name                = "VM Disk Space Warning"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Disk Space is greater than 80%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 3

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Free Space"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM Disk Space Critical
resource "azurerm_monitor_metric_alert" "metric_alert_vm_disk_space_critical" {
  name                = "VM Disk Space Critical"
  resource_group_name = azurerm_resource_group.rg_oms.name

  scopes      = [azurerm_log_analytics_workspace.oms.id]
  description = "Action will be triggered when Virtual Machine Disk Space is greater than 90%"
  frequency   = "PT5M"
  window_size = "PT15M"
  severity    = 2

  criteria {
    metric_namespace = "Microsoft.OperationalInsights/workspaces"
    metric_name      = "Average_% Free Space"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 10

    dimension {
      name     = "Computer"
      operator = "Include"
      values   = ["*"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

## App Insights Alert - Exception Failures
#resource "azurerm_monitor_metric_alert" "metric_alert_appinsights_exceptions" {
#  name                = "Application Insights - exceptions"
#  resource_group_name = azurerm_resource_group.rg_oms.name
#  scopes              = [var.app_insights_resource_id]
#  description         = "Action will be triggered when Exceptions is >=${var.metric_alert_appinsights_exceptions_threshold}"
#  severity            = 3
#  enabled             = true
#  frequency           = "PT15M"
#  window_size         = "PT15M"
#  criteria {
#    metric_namespace = "microsoft.insights/components"
#    metric_name      = "exceptions/count"
#    aggregation      = "Count"
#    operator         = "GreaterThanOrEqual"
#    threshold        = var.metric_alert_appinsights_exceptions_threshold
#  }
#  action {
#    action_group_id = azurerm_monitor_action_group.action_group_uxcc_dwp.id
#  }
#  tags                = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
#}

## Log Alerts #################################################################

## SQL Error Alert
resource "azurerm_monitor_scheduled_query_rules_alert" "sql_errors" {
  name                = "SQL Errors"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id, azurerm_monitor_action_group.action_group_app_dwp.id]
    email_subject = "SQL Errors"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when SQL Errors occur"
  enabled        = true
  query          = <<-QUERY
  Event
    | where EventLevelName == "Error"
    | where Source contains "SQL"
  QUERY
  severity       = 3
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 5
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

#Computers with detected threats
resource "azurerm_monitor_scheduled_query_rules_alert" "detected_threats" {
  name                = "Detected Threats"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "Detected Threats"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when threats are detected"
  enabled        = true
  query          = <<-QUERY
  ProtectionStatus
    | summarize (TimeGenerated, Rank) = argmax(TimeGenerated, ThreatStatusRank) by Computer
    | where Rank > 199 and Rank != 470
    | sort by TimeGenerated desc
  QUERY
  severity       = 3
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 5
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

###VM Offline
#resource "azurerm_monitor_scheduled_query_rules_alert" "vm_offline" {
#  name                = "VM Offline"
#  location            = var.location
#  resource_group_name = azurerm_resource_group.rg_oms.name
#
#  action {
#    action_group           = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
#    email_subject          = "VM Offline"
#    custom_webhook_payload = "{}"
#  }
#  data_source_id = azurerm_log_analytics_workspace.oms.id
#  description    = "Alerts when a VM is offline for more than 30 minutes"
#  enabled        = true
#  query       = <<-QUERY
#  Heartbeat
#    | summarize LastCall = max(TimeGenerated) by Computer
#    | where LastCall < ago(15m)
#    | sort by LastCall asc
#  QUERY
#  severity    = 1
#  frequency   = 5
#  time_window = 30
#  trigger {
#    operator  = "GreaterThan"
#    threshold = 0
#  }
#  tags                = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
#}

# Failed Backup
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert__failed_backup" {
  name                = "Failed Backup"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "Failed Backup"
  }

  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when a VM is offline for more than 30 minutes"
  enabled        = true
  query          = <<-QUERY
  AzureDiagnostics
    | where ResourceProvider == "MICROSOFT.RECOVERYSERVICES" and Category == "AzureBackupReport"
    | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed"
  QUERY
  severity       = 4
  frequency      = 60
  time_window    = 60
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Security Centre Alerts: High Severity
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_securitycentre_high" {
  name                = "Security Centre Alerts - High"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id, azurerm_monitor_action_group.action_group_secmon_dwp.id]
    email_subject = "Security Centre Alerts - High Severity"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers if any High Severity alerts are generated within Azure Security Centre"
  enabled        = true
  query          = <<-KQL
  SecurityAlert
  | where AlertSeverity == "High"
  KQL
  severity       = 1
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Security Centre Alerts: Medium and Low Severity
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_securitycentre_medium_low" {
  name                = "Security Centre Alerts - Medium and Low"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id, azurerm_monitor_action_group.action_group_secmon_dwp.id]
    email_subject = "Security Centre Alerts - Medium or Low Severity"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers if any Medium or Low Severity alerts are generated within Azure Security Centre"
  enabled        = true
  query          = <<-KQL
  SecurityAlert
  | where AlertSeverity in ("Low","Medium")
  KQL
  severity       = 2
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Resource Deployment: Non-allowed Azure Regions
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_deployment_non_allowed_location" {
  name                = "Deployment to non-allowed regions"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "Resources deployed to non-allowed regions"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Resources deployed to non-allowed regions - i.e. other than UKSouth or UKWest"
  enabled        = true
  query          = <<-KQL
  let policyDefId = 'poldef-dwp-allowed-locations';
  AzureActivity
  | where Category == 'Policy' and Level != 'Informational'
  | extend p=todynamic(Properties)
  | extend policies=todynamic(tostring(p.policies))
  | mvexpand policy = policies
  | where policy.policyDefinitionName in (policyDefId) and p.isComplianceCheck == 'False'
  KQL
  severity       = 3
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Azure Capacity issue
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_azure_capacity" {
  name                = "Azure capacity"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "Failure due to Azure data centre capacity issue"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when an Azure activity fails and capacity is mentioned in the error"
  enabled        = true
  query          = <<-KQL
  AzureActivity
  | where ActivityStatus == "Failed"
  | where Properties contains "capacity"
  KQL
  severity       = 2
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Azure Site Recovery ReplicationHealth Status or FailoverHealthStatus Critical
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_asr_replication_critical" {
  name                = "Azure Site Recovery Critical Replication Status"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_dwp.id]
    email_subject = "Azure Site Recovery Critical Replication Status"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "${var.log_alert_asr_replication_critical_threshold[terraform.workspace] + 1} or more VMs protected by Azure Site Recovery are reporting a replication status of Critical."
  enabled        = true
  query          = <<-KQL
AzureDiagnostics
| where replicationProviderName_s == "A2A" 
| where isnotempty(name_s) and isnotnull(name_s)
| where (failoverHealth_s == "Critical") or (replicationHealth_s == "Critical")
| summarize hint.strategy=partitioned arg_max(TimeGenerated, *) by name_s
| project VirtualMachine = name_s ,
    Vault = Resource,
    SourceLocation = primaryFabricName_s,
    FailoverHealth = failoverHealth_s,
    ReplicationHealth = replicationHealth_s,
    Status = protectionState_s,
    RPO_in_Minutes = (rpoInSeconds_d / 60),
    TestFailoverStatus = failoverHealth_s,
    AgentVersion = agentVersion_s,
    FailoverError = failoverHealthErrors_s,
    ReplicationError = replicationHealthErrors_s
KQL
  severity       = 3
  frequency      = 60
  time_window    = 60
  trigger {
    operator  = "GreaterThan"
    threshold = var.log_alert_asr_replication_critical_threshold[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Azure Site Recovery RPO is over 30 mins
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_asr_rpo_greater_than_30m" {
  name                = "Azure Site Recovery RPO over 30m"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_dwp.id]
    email_subject = "Azure Site Recovery RPO is more than 30 minutes"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "${var.log_alert_asr_rpo_greater_than_30m_threshold[terraform.workspace] + 1} or more VMs protected by Azure Site Recovery are reporting an RPO greater than 30 minutes."
  enabled        = false
  query          = <<-KQL
AzureDiagnostics
| where replicationProviderName_s == "A2A"
| where isnotempty(name_s) and isnotnull(name_s)
| where rpoInSeconds_d > 1800
| summarize hint.strategy=partitioned arg_max(TimeGenerated, *) by name_s
| project name_s , RPO_in_Hours = (rpoInSeconds_d / 3600) 
KQL
  severity       = 3
  frequency      = 30
  time_window    = 30
  trigger {
    operator  = "GreaterThan"
    threshold = var.log_alert_asr_rpo_greater_than_30m_threshold[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Azure Site Recovery Job Failure
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_asr_recovery_job_fail" {
  name                = "Azure Site Recovery Recovery Job Failure"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_dwp.id]
    email_subject = "An Azure Site Recovery Recovery Job has failed"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "${var.log_alert_asr_recovery_job_fail_threshold[terraform.workspace] + 1} or more Azure Site Recovery jobs have failed to complete successfully."
  enabled        = true
  query          = <<-KQL
AzureDiagnostics
| where Category == "AzureSiteRecoveryJobs"
| where OperationName == "Reprotect"
| where ResultType == "Failed"
KQL
  severity       = 3
  frequency      = 60
  time_window    = 60
  trigger {
    operator  = "GreaterThan"
    threshold = var.log_alert_asr_recovery_job_fail_threshold[terraform.workspace]
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM, Linux - % Inodes in use warning
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_inodes_warning" {
  name                = "VM - inodes in use warning"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_dwp.id]
    email_subject = "logical disk inodes greater than ${var.log_alert_vm_inodes_warning_threshold[terraform.workspace]}%"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers when the % inodes used is greater than ${var.log_alert_vm_inodes_warning_threshold[terraform.workspace]}% for a given logical disk"
  enabled        = true
  query          = <<-KQL
  Perf
  | where CounterName =='% Used Inodes'
  | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
  | where AggregatedValue > ${var.log_alert_vm_inodes_warning_threshold[terraform.workspace]}
  KQL
  severity       = 3
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM, Linux - % Inodes in use critical
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_inodes_critical" {
  name                = "VM - inodes in use critical"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_dwp.id]
    email_subject = "logical disk inodes greater than ${var.log_alert_vm_inodes_critical_threshold[terraform.workspace]}%"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers when the % inodes used is greater than ${var.log_alert_vm_inodes_critical_threshold[terraform.workspace]}% for a given logical disk"
  enabled        = true
  query          = <<-KQL
  Perf
  | where CounterName =='% Used Inodes'
  | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
  | where AggregatedValue > ${var.log_alert_vm_inodes_critical_threshold[terraform.workspace]}
  KQL
  severity       = 3
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM, Linux - Logical Volume space used > warning threshold
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_logical_disk_warning" {
  name                = "VM - logical volume space used over ${var.log_alert_vm_logical_disk_warning_threshold[terraform.workspace]} percent"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "VM logical volume space low - ${var.log_alert_vm_logical_disk_warning_threshold[terraform.workspace]} percent full"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers when a logical volume is more than ${var.log_alert_vm_logical_disk_warning_threshold[terraform.workspace]} percent full."
  enabled        = true
  query          = <<-KQL
  Perf
  | where CounterName =='% Used Space' and InstanceName != '_Total'
  | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
  | where AggregatedValue > ${var.log_alert_vm_logical_disk_warning_threshold[terraform.workspace]}
  KQL
  severity       = 3
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# VM, Linux - Logical Volume space used > critical threshold
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_logical_disk_critical" {
  name                = "VM - logical volume space used over ${var.log_alert_vm_logical_disk_critical_threshold[terraform.workspace]} percent"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name
  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "VM logical volume space low - ${var.log_alert_vm_logical_disk_critical_threshold[terraform.workspace]} percent full"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Triggers when a logical volume is more than ${var.log_alert_vm_logical_disk_critical_threshold[terraform.workspace]} percent full."
  enabled        = true
  query          = <<-KQL
  Perf
  | where CounterName =='% Used Space' and InstanceName != '_Total'
  | summarize AggregatedValue = avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
  | where AggregatedValue > ${var.log_alert_vm_logical_disk_critical_threshold[terraform.workspace]}
  KQL
  severity       = 3
  frequency      = 5
  time_window    = 5
  trigger {
    operator  = "GreaterThan"
    threshold = 0
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

## IIS Log Alert
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_iis_log_errors" {
  name                = "IIS Log Errors"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "IIS Errors"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when IIS Errors occur"
  enabled        = true
  query          = <<-QUERY
  W3CIISLog
    | where scStatus ==500
  QUERY
  severity       = 3
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 5
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

## Updates overdue
resource "azurerm_monitor_scheduled_query_rules_alert" "log_alert_vm_updates_overdue" {
  name                = "Updates Overdue"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg_oms.name

  action {
    action_group  = [azurerm_monitor_action_group.action_group_sre_email_dwp.id]
    email_subject = "Updates Overdue"
  }
  data_source_id = azurerm_log_analytics_workspace.oms.id
  description    = "Alerts when there are security updates pending for more than 45 days"
  enabled        = true
  query          = <<-QUERY
  Update
    | where UpdateState == "Needed" and Optional == false and Classification == "Security Updates" and Approved != false
    | where PublishedDate <= ago(45d)
  QUERY
  severity       = 3
  frequency      = 15
  time_window    = 15
  trigger {
    operator  = "GreaterThan"
    threshold = 5
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}


## ARM Templates #########################################################

# Log Query Alerts via ARM Template - generates saved searches
data "template_file" "monitor_arm_template" {
  template = file("${path.module}/monitor.deploy.json")
}

resource "azurerm_resource_group_template_deployment" "dwp_monitor_arm_template" {
  name                = "dwp-monitor-arm-template"
  resource_group_name = azurerm_resource_group.rg_oms.name

  template_content = data.template_file.monitor_arm_template.rendered

  parameters_content = jsonencode({
    "omsWorkspaceName" = {
      value = azurerm_log_analytics_workspace.oms.name
    },
    "nsg_name" = {
      value = azurerm_network_security_group.fe01.name
    }
  })

  # No idea why these aren't just added above but
  # this at least will stop them being removed every
  # time the pipeline runs
  # - appTeam          = {
  #     - value = "App Team"
  #   } -> null
  # - sreTeam          = {
  #     - value = "SRE Team"
  #   } -> null
  # - sreTeamEmail     = {
  #     - value = "SRE Team Email"
  #   } -> null
  lifecycle {
    ignore_changes = [
      parameters_content
    ]
  }

  deployment_mode = "Incremental"

  depends_on = [
    azurerm_monitor_action_group.action_group_sre_dwp,
    azurerm_monitor_action_group.action_group_sre_email_dwp,
    azurerm_monitor_action_group.action_group_app_dwp
  ]
}

# Azure Monitor alert for Redis Server Load (>90%)
resource "azurerm_monitor_metric_alert" "redis_server_load_high" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Redis Server Load High - - ${azurerm_redis_cache.omilia[count.index].name}"
  description         = "Alert when Redis Server Load is above 90% for 5 minutes - ${azurerm_redis_cache.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_redis_cache.omilia[count.index].id]
  frequency           = "PT1M"
  window_size         = "PT5M"
  severity            = 3
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Cache/Redis"
    metric_name      = "ServerLoad"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_metric_alert" "redis_used_memory" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Redis Used Memory Alert - ${azurerm_redis_cache.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_redis_cache.omilia[count.index].id]
  description         = "Alert when Redis used memory percentage is more than 90% - ${azurerm_redis_cache.omilia[count.index].name}"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true
  criteria {
    metric_namespace = "Microsoft.Cache/Redis"
    metric_name      = "UsedMemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_metric_alert" "redis_errors" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Redis Errors Alert - ${azurerm_redis_cache.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_redis_cache.omilia[count.index].id]
  description         = "Alert when Redis errors are more than 10 - ${azurerm_redis_cache.omilia[count.index].name}"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true
  criteria {
    metric_namespace = "Microsoft.Cache/Redis"
    metric_name      = "Errors"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }
  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# MySQL CPU_percent
resource "azurerm_monitor_metric_alert" "mysql_cpu" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL CPU_percent - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.omilia[count.index].id]
  description         = "The percentage of CPU in use is high - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  auto_mitigate       = true
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_metric_alert" "mysql_cpu_replica" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL CPU_percent - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.replica[count.index].id]
  description         = "The percentage of CPU in use is high - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  auto_mitigate       = true
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# MySQL memory_percent
resource "azurerm_monitor_metric_alert" "mysql_memory" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL memory_percent - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.omilia[count.index].id]
  description         = "The percentage of memory in use is high - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  auto_mitigate       = true
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_metric_alert" "mysql_memory_replica" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL memory_percent - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.replica[count.index].id]
  description         = "The percentage of memory in use is high - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  auto_mitigate       = true
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# MySQL aborted_connections
resource "azurerm_monitor_metric_alert" "mysql_connections" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL aborted_connections - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.omilia[count.index].id]
  description         = "Total failed attempts to connect, for example, due to bad credentials is high - ${azurerm_mysql_flexible_server.omilia[count.index].name}"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "aborted_connections"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 500
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

resource "azurerm_monitor_metric_alert" "mysql_connections_replica" {
  count = length(local.cpenvprefix[terraform.workspace])

  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] MySQL aborted_connections - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_mysql_flexible_server.replica[count.index].id]
  description         = "Total failed attempts to connect, for example, due to bad credentials is high - ${azurerm_mysql_flexible_server.replica[count.index].name}"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "aborted_connections"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 500
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Postgres storage_percent
resource "azurerm_monitor_metric_alert" "postgres_storage" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Postgres storage percentage - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_postgresql_flexible_server.omilia[count.index].id]
  severity            = 3
  description         = "Alert when PostgreSQL Flexible Server storage percent exceeds 90% - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "storage_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Postgres cpu_percent
resource "azurerm_monitor_metric_alert" "postgres_cpu" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Postgres cpu percentage - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_postgresql_flexible_server.omilia[count.index].id]
  severity            = 3
  description         = "Alert when PostgreSQL Flexible Server CPU percent exceeds 90% - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }


  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Postgres memory_percent
resource "azurerm_monitor_metric_alert" "postgres_memory" {
  count               = length(local.cpenvprefix[terraform.workspace])
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Postgres memory percentage - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_postgresql_flexible_server.omilia[count.index].id]
  severity            = 3
  description         = "Alert when PostgreSQL Flexible Server memory percent exceeds 90% - ${azurerm_postgresql_flexible_server.omilia[count.index].name}"
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.DBforPostgreSQL/flexibleServers"
    metric_name      = "memory_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage successE2Elatency
resource "azurerm_monitor_metric_alert" "storage_latency_omilia" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage successE2Elatency - omilia"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.omilia.id]
  description         = "End-to-end latency including network and processing, of successful requests for ${azurerm_storage_account.omilia.name} is high"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "SuccessE2ELatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage Availability
resource "azurerm_monitor_metric_alert" "storage_availability_omilia" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage Availability - omilia"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.omilia.id]
  description         = "Availability of ${azurerm_storage_account.omilia.name} storage service or API operation is greater than 95%"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage successE2Elatency
resource "azurerm_monitor_metric_alert" "storage_latency_sounds" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage successE2Elatency - sounds"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.sounds.id]
  description         = "End-to-end latency including network and processing, of successful requests for ${azurerm_storage_account.sounds.name} is high"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "SuccessE2ELatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage Availability
resource "azurerm_monitor_metric_alert" "storage_availability_sounds" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage Availability - sounds"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.sounds.id]
  description         = "Availability of ${azurerm_storage_account.sounds.name} storage service or API operation is less than 95%"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage successE2Elatency
resource "azurerm_monitor_metric_alert" "storage_latency_dialogs" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage successE2Elatency - dialogs"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.dialogs.id]
  description         = "End-to-end latency including network and processing, of successful requests for ${azurerm_storage_account.dialogs.name} is high"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "SuccessE2ELatency"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# Storage Availability
resource "azurerm_monitor_metric_alert" "storage_availability_dialogs" {
  name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Storage Availability - dialogs"
  resource_group_name = azurerm_resource_group.rg_oms.name
  scopes              = [azurerm_storage_account.dialogs.id]
  description         = "Availability of ${azurerm_storage_account.dialogs.name} storage service or API operation is less than 95%"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
  }

  action {
    action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
  }

  dynamic "action" {
    for_each = local.action_group_list

    content {
      action_group_id = action.value.action_group_id
    }
  }

  tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
}

# # Analytics_VM Storage running out
# resource "azurerm_monitor_metric_alert" "disk_space_alert" {
#   count               = contains(local.build_tableau, terraform.workspace) ? 1 : 0
#   name                = "PLEASE NOTIFY LIVE SERVICE [DWP_NGCC][NGCC] Analytics Server disk space exceeds 80 Percent"
#   resource_group_name = azurerm_resource_group.rg_analytics[0].name
#   scopes              = [azurerm_managed_disk.analytics_data[0].id]
#   description         = "Analytics Server disk space exceeds 80 percent"
#   severity            = 3
#   frequency           = "PT5M"
#   window_size         = "PT15M"
#   auto_mitigate       = true

#   criteria {
#     metric_namespace = "Microsoft.Compute/virtualMachines"
#     metric_name      = "Percentage Disk Space Used"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#     dimensions = {
#       "InstanceId" = azurerm_virtual_machine.analytics[0].id
#       "Name" = "disk1"  # Specify the disk name
#     }
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.action_group_sre_dwp.id
#   }

#   action {
#     action_group_id = azurerm_monitor_action_group.action_group_sre_email_dwp.id
#   }

#   dynamic "action" {
#     for_each = local.action_group_list

#     content {
#       action_group_id = action.value.action_group_id
#     }
# }
# tags = merge(var.tags, { "Application" = var.application_tag, "Function" = var.function_tag, "Environment" = var.environment_tags[terraform.workspace], "Role" = var.role_tag })
# }
