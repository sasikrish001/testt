# Azure Cost Analysis Queries and Reports (Reader Access)

This document contains ready-to-use queries and commands for analyzing Azure costs with Reader-level access.

**Prerequisites:**
- Azure CLI installed
- Reader or Cost Management Reader role
- Azure PowerShell module (for PowerShell queries)

**Date:** January 11, 2026

---

## Table of Contents
1. [Azure CLI Cost Queries](#azure-cli-cost-queries)
2. [PowerShell Cost Queries](#powershell-cost-queries)
3. [Azure Portal Cost Analysis](#azure-portal-cost-analysis)
4. [Log Analytics Cost Queries](#log-analytics-cost-queries)
5. [Cost Alerts and Budgets (Read-Only)](#cost-alerts-and-budgets)
6. [Export and Reporting](#export-and-reporting)

---

## Azure CLI Cost Queries

### 1. Current Month Cost by Resource Group

```bash
# Get current month costs grouped by resource group
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 2. Last 30 Days Cost Trend

```bash
# Daily cost breakdown for last 30 days
START_DATE=$(date -d '30 days ago' +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=UsageDate type=Dimension \
  --timeframe "Custom" \
  --time-period from="$START_DATE" to="$END_DATE" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 3. Cost by Service/Resource Type

```bash
# Get costs grouped by meter category (service type)
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=MeterCategory type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 4. Cost by Location

```bash
# Geographic distribution of costs
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceLocation type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 5. Top 10 Most Expensive Resources

```bash
# Identify the most costly individual resources
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceId type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "properties.rows[:10]" \
  --output table
```

### 6. Cost by Tag

```bash
# Cost analysis by environment tag
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=TagValue type=Tag --dataset-grouping name=TagKey type=Tag \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 7. Quarter-to-Date Costs

```bash
# Get current quarter costs
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "QuarterToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

### 8. Year-to-Date Comparison

```bash
# Year-to-date cost analysis
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=MeterCategory type=Dimension \
  --timeframe "YearToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table
```

---

## PowerShell Cost Queries

### 1. Current Month Cost Summary

```powershell
# Get current month cost summary
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

# Note: Cost Management cmdlets require Az.CostManagement module
# Install-Module -Name Az.CostManagement -Repository PSGallery

# Get cost by resource group
$query = @{
    Type = "Usage"
    Timeframe = "MonthToDate"
    DatasetAggregation = @{
        totalCost = @{
            Name = "PreTaxCost"
            Function = "Sum"
        }
    }
    DatasetGrouping = @(
        @{
            Type = "Dimension"
            Name = "ResourceGroupName"
        }
    )
}

# This is a conceptual example - actual PowerShell cmdlet may vary
Invoke-AzCostManagementQuery -Scope $scope -Query $query | Format-Table
```

### 2. Export Cost Data to CSV

```powershell
# Export current month costs to CSV
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

$costData = Invoke-AzCostManagementQuery -Scope $scope -Timeframe "MonthToDate"

# Convert and export to CSV
$costData.Rows | ForEach-Object {
    [PSCustomObject]@{
        Date = $_[0]
        Cost = $_[1]
        ResourceGroup = $_[2]
    }
} | Export-Csv -Path "azure-costs-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation

Write-Host "Cost data exported to: azure-costs-$(Get-Date -Format 'yyyyMMdd').csv"
```

### 3. Get Budget Information (Read-Only)

```powershell
# List all budgets
$subscriptionId = (Get-AzContext).Subscription.Id
$scope = "/subscriptions/$subscriptionId"

Get-AzConsumptionBudget -Scope $scope | Select-Object Name, Amount, TimeGrain, Category | Format-Table
```

---

## Azure Portal Cost Analysis

### Manual Steps for Cost Analysis (Reader Access)

1. **Navigate to Cost Management + Billing**
   - Portal: https://portal.azure.com
   - Search: "Cost Management + Billing"
   - Select: "Cost analysis"

2. **Key Views to Explore:**
   - **Accumulated costs:** Month-to-date spending
   - **Daily costs:** Daily breakdown
   - **Cost by service:** Grouping by Azure service
   - **Cost by resource:** Individual resource costs

3. **Recommended Filters:**
   ```
   - Time range: Last 30 days, Month to date, Custom
   - Granularity: Daily, Monthly
   - Group by: Service, Resource, Resource group, Location, Tag
   ```

4. **Download Options:**
   - Click "Download" → CSV or Excel
   - Includes current filtered view
   - Location: Downloads folder

---

## Log Analytics Cost Queries

### KQL Queries for Azure Monitor Logs

```kql
// 1. Resource consumption over time
AzureActivity
| where TimeGenerated > ago(30d)
| summarize Count=count() by bin(TimeGenerated, 1d), ResourceGroup
| render timechart

// 2. Operations by resource type
AzureActivity
| where TimeGenerated > ago(7d)
| summarize OperationCount=count() by ResourceProviderValue
| order by OperationCount desc
| take 10

// 3. Failed operations (potential waste)
AzureActivity
| where TimeGenerated > ago(30d)
| where ActivityStatusValue == "Failed"
| summarize FailureCount=count() by ResourceGroup, OperationNameValue
| order by FailureCount desc

// 4. Resource creation and deletion events
AzureActivity
| where TimeGenerated > ago(30d)
| where OperationNameValue contains "Create" or OperationNameValue contains "Delete"
| project TimeGenerated, OperationNameValue, ResourceGroup, Resource
| order by TimeGenerated desc

// 5. Compute resource usage patterns
AzureMetrics
| where TimeGenerated > ago(7d)
| where ResourceId contains "Microsoft.Compute/virtualMachines"
| where MetricName == "Percentage CPU"
| summarize AvgCPU=avg(Average) by Resource, bin(TimeGenerated, 1h)
| render timechart
```

### Application Insights Cost Query

```kql
// Track Application Insights data ingestion (affects costs)
Usage
| where TimeGenerated > ago(30d)
| where DataType in ("AppRequests", "AppDependencies", "AppExceptions", "AppTraces")
| summarize DataVolume_MB=sum(Quantity) / 1024 by bin(TimeGenerated, 1d), DataType
| render timechart
```

---

## Cost Alerts and Budgets (Read-Only)

### View Existing Budgets

```bash
# Azure CLI
az consumption budget list --subscription $(az account show --query id -o tsv)
```

```powershell
# PowerShell
Get-AzConsumptionBudget -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)"
```

### Check Current vs Budget Spend

```bash
# Get budget details
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
BUDGET_NAME="your-budget-name"

az consumption budget show \
  --budget-name "$BUDGET_NAME" \
  --subscription "$SUBSCRIPTION_ID"
```

---

## Export and Reporting

### 1. Automated Daily Cost Report Script

```bash
#!/bin/bash
# File: daily-cost-report.sh

OUTPUT_FILE="cost-report-$(date +%Y%m%d).json"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Generating cost report for subscription: $SUBSCRIPTION_ID"

# Get yesterday's costs
YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

az costmanagement query \
  --type "ActualCost" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --dataset-grouping name=MeterCategory type=Dimension \
  --timeframe "Custom" \
  --time-period from="$YESTERDAY" to="$TODAY" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output json > "$OUTPUT_FILE"

echo "Report saved to: $OUTPUT_FILE"

# Generate human-readable summary
echo "=== Cost Summary for $YESTERDAY ===" > "cost-summary-$(date +%Y%m%d).txt"
jq -r '.properties.rows[] | @csv' "$OUTPUT_FILE" >> "cost-summary-$(date +%Y%m%d).txt"
```

### 2. Monthly Cost Report with Charts

```bash
#!/bin/bash
# File: monthly-cost-report.sh

MONTH=$(date +%Y-%m)
OUTPUT_DIR="cost-reports-$MONTH"
mkdir -p "$OUTPUT_DIR"

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# 1. Cost by Resource Group
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output table > "$OUTPUT_DIR/by-resource-group.txt"

# 2. Cost by Service
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=MeterCategory type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output table > "$OUTPUT_DIR/by-service.txt"

# 3. Cost by Location
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceLocation type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output table > "$OUTPUT_DIR/by-location.txt"

# 4. Daily trend
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=UsageDate type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output json > "$OUTPUT_DIR/daily-trend.json"

echo "Monthly cost reports generated in: $OUTPUT_DIR"
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR"
echo "Archive created: $OUTPUT_DIR.tar.gz"
```

### 3. Cost Anomaly Detection

```bash
#!/bin/bash
# File: cost-anomaly-detection.sh

# Compare current month vs last month costs
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Current month
CURRENT=$(az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query 'properties.rows[0][0]' -o tsv)

# Same period last month
DAYS_IN_MONTH=$(date +%d)
LAST_MONTH_START=$(date -d "last month" +%Y-%m-01)
LAST_MONTH_END=$(date -d "last month +$((DAYS_IN_MONTH-1)) days" +%Y-%m-%d)

PREVIOUS=$(az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --timeframe "Custom" \
  --time-period from="$LAST_MONTH_START" to="$LAST_MONTH_END" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query 'properties.rows[0][0]' -o tsv)

echo "Current month-to-date: \$$CURRENT"
echo "Same period last month: \$$PREVIOUS"

# Calculate percentage change
CHANGE=$(echo "scale=2; (($CURRENT - $PREVIOUS) / $PREVIOUS) * 100" | bc)
echo "Change: $CHANGE%"

if (( $(echo "$CHANGE > 20" | bc -l) )); then
    echo "⚠️  WARNING: Cost increase > 20%!"
fi
```

---

## Best Practices for Cost Monitoring (Reader Access)

### Daily Tasks
- ✅ Review cost anomalies in Azure Portal
- ✅ Check budget alerts
- ✅ Monitor top 5 most expensive resources

### Weekly Tasks
- ✅ Run cost comparison scripts
- ✅ Review resource utilization metrics
- ✅ Identify unused or underutilized resources
- ✅ Check for orphaned resources (disks, IPs, etc.)

### Monthly Tasks
- ✅ Generate comprehensive cost report
- ✅ Analyze month-over-month trends
- ✅ Review Azure Advisor cost recommendations
- ✅ Document cost optimization opportunities

### Quarterly Tasks
- ✅ Review Reserved Instance utilization
- ✅ Assess resource rightsizing opportunities
- ✅ Evaluate Spot VM adoption
- ✅ Update cost forecasts and budgets

---

## Quick Reference Commands

```bash
# Current subscription costs (month-to-date)
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum --timeframe "MonthToDate" --scope "/subscriptions/$(az account show --query id -o tsv)" --output table

# List all budgets
az consumption budget list --subscription $(az account show --query id -o tsv)

# Show Azure Advisor cost recommendations
az advisor recommendation list --category Cost --output table

# Get resource usage metrics
az monitor metrics list --resource <resource-id> --metric "Percentage CPU" --start-time 2026-01-01T00:00:00Z --end-time 2026-01-11T23:59:59Z

# List all resource SKUs with pricing tier
az resource list --query "[].{Name:name, Type:type, SKU:sku.name, Tier:sku.tier}" --output table
```

---

## Additional Resources

- [Azure Cost Management REST API](https://docs.microsoft.com/rest/api/cost-management/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management Best Practices](https://docs.microsoft.com/azure/cost-management-billing/costs/cost-mgt-best-practices)
- [Azure Advisor Documentation](https://docs.microsoft.com/azure/advisor/)

---

**Note:** All commands in this document are read-only and safe to execute with Reader or Cost Management Reader roles. No resources will be modified.
