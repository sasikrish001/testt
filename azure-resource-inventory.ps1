################################################################################
# Azure Resource Inventory Script - PowerShell Version (Reader Access Only)
# Purpose: Discover and document all Azure infrastructure resources
# Requirements: Az PowerShell Module, Reader role or higher
# Date: January 11, 2026
################################################################################

#Requires -Modules Az.Accounts, Az.Resources

# Output directory
$OutputDir = "azure-inventory-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "=== Azure Resource Inventory Tool ===" -ForegroundColor Green
Write-Host "Output Directory: $OutputDir`n" -ForegroundColor Cyan

################################################################################
# Helper Function
################################################################################
function Write-Section {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

################################################################################
# 1. Account and Subscription Information
################################################################################
Write-Section "[1/12] Collecting Account Information..."

$context = Get-AzContext
$subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id

@"
=== Azure Account Information ===
Subscription Name: $($subscription.Name)
Subscription ID: $($subscription.Id)
Tenant ID: $($subscription.TenantId)
Account: $($context.Account.Id)
Environment: $($context.Environment.Name)

=== All Subscriptions ===
"@ | Out-File "$OutputDir/01-account-info.txt"

Get-AzSubscription | Format-Table -AutoSize | Out-File "$OutputDir/01-account-info.txt" -Append
Get-AzSubscription | ConvertTo-Json -Depth 5 | Out-File "$OutputDir/01-account-info.json"

################################################################################
# 2. Resource Groups
################################################################################
Write-Section "[2/12] Collecting Resource Groups..."

"=== Resource Groups ===" | Out-File "$OutputDir/02-resource-groups.txt"
Get-AzResourceGroup | Format-Table -AutoSize | Out-File "$OutputDir/02-resource-groups.txt" -Append
Get-AzResourceGroup | ConvertTo-Json -Depth 5 | Out-File "$OutputDir/02-resource-groups.json"

################################################################################
# 3. All Resources Overview
################################################################################
Write-Section "[3/12] Collecting All Resources..."

$allResources = Get-AzResource

"=== All Resources ===" | Out-File "$OutputDir/03-all-resources.txt"
$allResources | Format-Table -AutoSize | Out-File "$OutputDir/03-all-resources.txt" -Append
$allResources | ConvertTo-Json -Depth 5 | Out-File "$OutputDir/03-all-resources.json"

"`n=== Resource Count by Type ===" | Out-File "$OutputDir/03-all-resources.txt" -Append
$allResources | Group-Object ResourceType |
    Select-Object Count, Name |
    Sort-Object Count -Descending |
    Format-Table -AutoSize |
    Out-File "$OutputDir/03-all-resources.txt" -Append

################################################################################
# 4. AKS Clusters
################################################################################
Write-Section "[4/12] Collecting AKS Clusters..."

"=== AKS Clusters ===" | Out-File "$OutputDir/04-aks-clusters.txt"

$aksClusters = Get-AzResource -ResourceType "Microsoft.ContainerService/managedClusters"
$aksClusters | Format-Table -AutoSize | Out-File "$OutputDir/04-aks-clusters.txt" -Append

foreach ($cluster in $aksClusters) {
    "`n--- Cluster: $($cluster.Name) (RG: $($cluster.ResourceGroupName)) ---" |
        Out-File "$OutputDir/04-aks-clusters.txt" -Append

    Get-AzResource -ResourceId $cluster.ResourceId |
        Format-List |
        Out-File "$OutputDir/04-aks-clusters.txt" -Append
}

$aksClusters | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/04-aks-clusters.json"

################################################################################
# 5. Virtual Machines
################################################################################
Write-Section "[5/12] Collecting Virtual Machines..."

"=== Virtual Machines ===" | Out-File "$OutputDir/05-virtual-machines.txt"

$vms = Get-AzVM
$vms | Format-Table -AutoSize | Out-File "$OutputDir/05-virtual-machines.txt" -Append

"`n=== VM Details with Status ===" | Out-File "$OutputDir/05-virtual-machines.txt" -Append
foreach ($vm in $vms) {
    $vmStatus = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
    "`n--- VM: $($vm.Name) ---" | Out-File "$OutputDir/05-virtual-machines.txt" -Append
    $vmStatus | Format-List | Out-File "$OutputDir/05-virtual-machines.txt" -Append
}

$vms | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/05-virtual-machines.json"

################################################################################
# 6. Container Registries (ACR)
################################################################################
Write-Section "[6/12] Collecting Container Registries..."

"=== Azure Container Registries ===" | Out-File "$OutputDir/06-container-registries.txt"

$acrs = Get-AzResource -ResourceType "Microsoft.ContainerRegistry/registries"
$acrs | Format-Table -AutoSize | Out-File "$OutputDir/06-container-registries.txt" -Append
$acrs | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/06-container-registries.json"

################################################################################
# 7. Storage Accounts
################################################################################
Write-Section "[7/12] Collecting Storage Accounts..."

"=== Storage Accounts ===" | Out-File "$OutputDir/07-storage-accounts.txt"

$storageAccounts = Get-AzStorageAccount
$storageAccounts | Format-Table -AutoSize | Out-File "$OutputDir/07-storage-accounts.txt" -Append
$storageAccounts | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/07-storage-accounts.json"

################################################################################
# 8. Networks (VNets, Subnets, NSGs)
################################################################################
Write-Section "[8/12] Collecting Network Resources..."

"=== Virtual Networks ===" | Out-File "$OutputDir/08-networking.txt"
$vnets = Get-AzVirtualNetwork
$vnets | Format-Table -AutoSize | Out-File "$OutputDir/08-networking.txt" -Append

"`n=== Network Security Groups ===" | Out-File "$OutputDir/08-networking.txt" -Append
Get-AzNetworkSecurityGroup | Format-Table -AutoSize | Out-File "$OutputDir/08-networking.txt" -Append

"`n=== Public IP Addresses ===" | Out-File "$OutputDir/08-networking.txt" -Append
Get-AzPublicIpAddress | Format-Table -AutoSize | Out-File "$OutputDir/08-networking.txt" -Append

"`n=== Load Balancers ===" | Out-File "$OutputDir/08-networking.txt" -Append
Get-AzLoadBalancer | Format-Table -AutoSize | Out-File "$OutputDir/08-networking.txt" -Append

"`n=== Application Gateways ===" | Out-File "$OutputDir/08-networking.txt" -Append
Get-AzApplicationGateway | Format-Table -AutoSize | Out-File "$OutputDir/08-networking.txt" -Append

$vnets | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/08-networking.json"

################################################################################
# 9. Databases
################################################################################
Write-Section "[9/12] Collecting Database Resources..."

"=== SQL Servers ===" | Out-File "$OutputDir/09-databases.txt"
$sqlServers = Get-AzSqlServer -ErrorAction SilentlyContinue
$sqlServers | Format-Table -AutoSize | Out-File "$OutputDir/09-databases.txt" -Append

if ($sqlServers) {
    "`n=== SQL Databases ===" | Out-File "$OutputDir/09-databases.txt" -Append
    foreach ($server in $sqlServers) {
        "`n--- Server: $($server.ServerName) ---" | Out-File "$OutputDir/09-databases.txt" -Append
        Get-AzSqlDatabase -ServerName $server.ServerName -ResourceGroupName $server.ResourceGroupName |
            Format-Table -AutoSize | Out-File "$OutputDir/09-databases.txt" -Append
    }
}

"`n=== PostgreSQL Servers ===" | Out-File "$OutputDir/09-databases.txt" -Append
Get-AzResource -ResourceType "Microsoft.DBforPostgreSQL/servers" |
    Format-Table -AutoSize | Out-File "$OutputDir/09-databases.txt" -Append

"`n=== MySQL Servers ===" | Out-File "$OutputDir/09-databases.txt" -Append
Get-AzResource -ResourceType "Microsoft.DBforMySQL/servers" |
    Format-Table -AutoSize | Out-File "$OutputDir/09-databases.txt" -Append

"`n=== CosmosDB Accounts ===" | Out-File "$OutputDir/09-databases.txt" -Append
Get-AzResource -ResourceType "Microsoft.DocumentDB/databaseAccounts" |
    Format-Table -AutoSize | Out-File "$OutputDir/09-databases.txt" -Append

################################################################################
# 10. Monitoring and Log Analytics
################################################################################
Write-Section "[10/12] Collecting Monitoring Resources..."

"=== Log Analytics Workspaces ===" | Out-File "$OutputDir/10-monitoring.txt"
Get-AzOperationalInsightsWorkspace -ErrorAction SilentlyContinue |
    Format-Table -AutoSize | Out-File "$OutputDir/10-monitoring.txt" -Append

"`n=== Application Insights ===" | Out-File "$OutputDir/10-monitoring.txt" -Append
Get-AzApplicationInsights -ErrorAction SilentlyContinue |
    Format-Table -AutoSize | Out-File "$OutputDir/10-monitoring.txt" -Append

################################################################################
# 11. Key Vaults
################################################################################
Write-Section "[11/12] Collecting Key Vaults..."

"=== Key Vaults ===" | Out-File "$OutputDir/11-key-vaults.txt"

$keyVaults = Get-AzKeyVault
$keyVaults | Format-Table -AutoSize | Out-File "$OutputDir/11-key-vaults.txt" -Append
$keyVaults | ConvertTo-Json -Depth 10 | Out-File "$OutputDir/11-key-vaults.json"

"`n=== Key Vault Secrets (Names Only) ===" | Out-File "$OutputDir/11-key-vaults.txt" -Append
foreach ($kv in $keyVaults) {
    try {
        "`n--- Key Vault: $($kv.VaultName) ---" | Out-File "$OutputDir/11-key-vaults.txt" -Append
        Get-AzKeyVaultSecret -VaultName $kv.VaultName |
            Select-Object Name, Created, Updated, Enabled |
            Format-Table -AutoSize |
            Out-File "$OutputDir/11-key-vaults.txt" -Append
    }
    catch {
        "  No access to secrets in $($kv.VaultName)" | Out-File "$OutputDir/11-key-vaults.txt" -Append
    }
}

################################################################################
# 12. Cost and Tags Analysis
################################################################################
Write-Section "[12/12] Collecting Cost and Tags Information..."

"=== Resource Tags Analysis ===" | Out-File "$OutputDir/12-tags-and-costs.txt"
$allResources | Select-Object Name, ResourceType, Tags |
    Format-Table -AutoSize |
    Out-File "$OutputDir/12-tags-and-costs.txt" -Append

"`n=== Resources Without Tags ===" | Out-File "$OutputDir/12-tags-and-costs.txt" -Append
$allResources | Where-Object { $null -eq $_.Tags -or $_.Tags.Count -eq 0 } |
    Select-Object Name, ResourceType, ResourceGroupName |
    Format-Table -AutoSize |
    Out-File "$OutputDir/12-tags-and-costs.txt" -Append

################################################################################
# Generate Summary Report
################################################################################
Write-Section "Generating Summary Report..."

$resourceGroups = Get-AzResourceGroup
$vms = Get-AzVM
$storageAccounts = Get-AzStorageAccount

@"
===========================================
AZURE RESOURCE INVENTORY SUMMARY
===========================================
Generated: $(Get-Date)
Subscription: $($subscription.Name)
Subscription ID: $($subscription.Id)

--- Resource Counts ---
Resource Groups: $($resourceGroups.Count)
Total Resources: $($allResources.Count)
AKS Clusters: $($aksClusters.Count)
Virtual Machines: $($vms.Count)
Container Registries: $($acrs.Count)
Storage Accounts: $($storageAccounts.Count)
Virtual Networks: $($vnets.Count)
Key Vaults: $($keyVaults.Count)

--- Top 10 Resource Types ---
"@ | Out-File "$OutputDir/00-SUMMARY.txt"

$allResources | Group-Object ResourceType |
    Select-Object Count, Name |
    Sort-Object Count -Descending |
    Select-Object -First 10 |
    Format-Table -AutoSize |
    Out-File "$OutputDir/00-SUMMARY.txt" -Append

@"

--- Files Generated ---
01-account-info.txt          - Account and subscription details
02-resource-groups.txt       - All resource groups
03-all-resources.txt         - Complete resource inventory
04-aks-clusters.txt          - Kubernetes clusters and node pools
05-virtual-machines.txt      - Virtual machines and sizes
06-container-registries.txt  - Container registries
07-storage-accounts.txt      - Storage accounts
08-networking.txt            - VNets, NSGs, load balancers
09-databases.txt             - SQL, PostgreSQL, MySQL, CosmosDB
10-monitoring.txt            - Log Analytics, App Insights
11-key-vaults.txt            - Key vaults and secret names
12-tags-and-costs.txt        - Tags analysis and cost data

All data is also available in JSON format where applicable.

===========================================
"@ | Out-File "$OutputDir/00-SUMMARY.txt" -Append

################################################################################
# Completion
################################################################################
Write-Host "`n✓ Inventory Complete!" -ForegroundColor Green
Write-Host "Results saved to: $OutputDir" -ForegroundColor Cyan
Write-Host "View summary: Get-Content $OutputDir/00-SUMMARY.txt" -ForegroundColor Cyan

# Create a zip archive
$archivePath = "$OutputDir.zip"
Compress-Archive -Path $OutputDir -DestinationPath $archivePath -Force
Write-Host "✓ Archive created: $archivePath" -ForegroundColor Green
