# Azure Infrastructure Resources - Reader Access Guide

**Repository:** Azure Infrastructure Documentation & Audit Tools
**Access Level:** Reader (Read-Only)
**Last Updated:** January 11, 2026

---

## 📋 Overview

This repository contains tools and scripts designed for Azure infrastructure discovery, cost analysis, security auditing, and compliance monitoring - all optimized for **Reader-level access**.

### What is Reader Access?

Reader access in Azure allows you to:
- ✅ View all resources and their configurations
- ✅ Run queries and generate reports
- ✅ Access cost and usage data (with Cost Management Reader)
- ✅ View security recommendations and alerts
- ✅ Export configuration and compliance data
- ❌ Cannot create, modify, or delete resources
- ❌ Cannot change configurations or settings

---

## 🗂️ Repository Structure

```
.
├── azure-resource-inventory.sh           # Bash script for complete resource discovery
├── azure-resource-inventory.ps1          # PowerShell version of inventory script
├── azure-cost-analysis-queries.md        # Cost analysis queries and reports
├── azure-security-compliance-audit.sh    # Security and compliance audit script
├── azure-cost-optimization-report.md     # Comprehensive cost optimization report
├── 16.cost-optimization.md               # Original cost optimization recommendations
└── AZURE-READER-ACCESS-GUIDE.md         # This file
```

---

## 🚀 Quick Start

### Prerequisites

**For Bash Scripts (Linux/macOS/WSL):**
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure
az login

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify access
az account show
```

**For PowerShell Scripts (Windows/Linux/macOS):**
```powershell
# Install Az PowerShell Module
Install-Module -Name Az -Repository PSGallery -Force

# Login to Azure
Connect-AzAccount

# Set your subscription
Set-AzContext -SubscriptionId "YOUR_SUBSCRIPTION_ID"

# Verify access
Get-AzContext
```

### Running Your First Inventory

**Bash:**
```bash
# Make scripts executable
chmod +x azure-resource-inventory.sh
chmod +x azure-security-compliance-audit.sh

# Run complete resource inventory
./azure-resource-inventory.sh

# Results will be in: azure-inventory-YYYYMMDD-HHMMSS/
```

**PowerShell:**
```powershell
# Run complete resource inventory
./azure-resource-inventory.ps1

# Results will be in: azure-inventory-YYYYMMDD-HHMMSS/
```

---

## 📊 Available Tools

### 1. Resource Inventory Script

**Purpose:** Complete discovery of all Azure resources in your subscription

**Files:**
- `azure-resource-inventory.sh` (Bash)
- `azure-resource-inventory.ps1` (PowerShell)

**What it discovers:**
- Account and subscription information
- Resource groups
- All resources with categorization
- AKS clusters and node pools
- Virtual machines with sizes and status
- Container registries and repositories
- Storage accounts
- Network resources (VNets, NSGs, Load Balancers)
- Databases (SQL, PostgreSQL, MySQL, CosmosDB)
- Monitoring resources (Log Analytics, App Insights)
- Key Vaults and secret names
- Cost analysis and tag inventory

**Usage:**
```bash
./azure-resource-inventory.sh
# Output: azure-inventory-YYYYMMDD-HHMMSS.tar.gz
```

**Output Files:**
- `00-SUMMARY.txt` - Executive summary
- `01-account-info.txt` - Subscription details
- `02-resource-groups.txt` - All resource groups
- `03-all-resources.txt` - Complete resource list
- `04-aks-clusters.txt` - Kubernetes clusters
- `05-virtual-machines.txt` - VM inventory
- `06-container-registries.txt` - ACR details
- `07-storage-accounts.txt` - Storage inventory
- `08-networking.txt` - Network topology
- `09-databases.txt` - Database resources
- `10-monitoring.txt` - Monitoring setup
- `11-key-vaults.txt` - Key vault inventory
- `12-tags-and-costs.txt` - Tagging and cost data

---

### 2. Cost Analysis Queries

**Purpose:** Analyze and report on Azure spending

**File:** `azure-cost-analysis-queries.md`

**Features:**
- Current month cost by resource group
- 30-day cost trends
- Cost by service type
- Cost by location
- Top 10 most expensive resources
- Cost by tags
- Budget monitoring
- Automated reporting scripts

**Quick Commands:**
```bash
# Current month costs
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table

# Top 10 expensive resources this month
az costmanagement query \
  --type "Usage" \
  --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceId type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "properties.rows[:10]" \
  --output table
```

---

### 3. Security & Compliance Audit

**Purpose:** Security posture assessment and compliance checking

**File:** `azure-security-compliance-audit.sh`

**What it checks:**
- Azure Security Center/Defender status
- Network Security Group rules (identifies overly permissive rules)
- Public IP exposure
- Storage account security settings
- Key Vault security configuration
- AKS security settings (RBAC, network policies)
- VM security (diagnostics, extensions)
- Database security (firewall rules, TLS versions)
- IAM role assignments
- Azure Policy compliance

**Usage:**
```bash
./azure-security-compliance-audit.sh
# Output: azure-security-audit-YYYYMMDD-HHMMSS.tar.gz
```

**Key Security Checks:**
- ⚠️ NSG rules allowing 0.0.0.0/0 (Internet)
- ⚠️ Storage accounts without HTTPS enforcement
- ⚠️ Public blob access enabled
- ⚠️ Key Vaults on public networks
- ⚠️ SQL 'Allow All' firewall rules
- ⚠️ Missing TLS 1.2+ enforcement
- ⚠️ AKS without network policies
- ⚠️ High-privilege role assignments

---

### 4. Cost Optimization Report

**Purpose:** Comprehensive cost reduction recommendations

**Files:**
- `azure-cost-optimization-report.md` (Detailed analysis)
- `16.cost-optimization.md` (Quick reference)

**Highlights:**
- Estimated savings: $450-650/month (37-45% reduction)
- Right-sizing recommendations for AKS nodes
- Autoscaling implementation guides
- Spot instance opportunities
- Reserved instance analysis
- 3-phase implementation roadmap

**Key Recommendations:**
1. Downsize AKS nodes: Standard_DS2_v2 → Standard_B2s
2. Implement cluster autoscaling
3. Add Horizontal Pod Autoscaler (HPA)
4. Use Spot VMs for dev/test
5. Purchase Reserved Instances
6. Optimize storage lifecycle
7. Enable network optimizations

---

## 📅 Recommended Workflows

### Daily Workflow
```bash
# 1. Quick cost check
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table

# 2. Check Azure Advisor recommendations
az advisor recommendation list --category Cost --output table
```

### Weekly Workflow
```bash
# 1. Run resource inventory
./azure-resource-inventory.sh

# 2. Review security audit
./azure-security-compliance-audit.sh

# 3. Analyze cost trends (last 7 days)
# See azure-cost-analysis-queries.md for detailed queries
```

### Monthly Workflow
```bash
# 1. Full infrastructure audit
./azure-resource-inventory.sh
./azure-security-compliance-audit.sh

# 2. Generate cost reports
# Run monthly cost report script from azure-cost-analysis-queries.md

# 3. Review and document findings
# Update team on cost trends, security findings, optimization opportunities
```

---

## 🎯 Common Use Cases

### Use Case 1: New Team Member Onboarding

**Scenario:** New developer needs to understand the Azure infrastructure

**Steps:**
```bash
# 1. Run inventory
./azure-resource-inventory.sh

# 2. Share the results
cd azure-inventory-*/
cat 00-SUMMARY.txt  # Overview
cat 03-all-resources.txt  # All resources
cat 04-aks-clusters.txt  # Kubernetes details
```

### Use Case 2: Monthly Cost Review Meeting

**Scenario:** Finance team needs monthly cost breakdown

**Steps:**
```bash
# 1. Generate cost reports
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceGroupName type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table > monthly-cost-report.txt

# 2. Identify top spenders
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --dataset-grouping name=ResourceId type=Dimension \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --query "properties.rows[:10]" \
  --output table > top-10-expensive-resources.txt

# 3. Review cost optimization report
cat azure-cost-optimization-report.md
```

### Use Case 3: Security Audit for Compliance

**Scenario:** Quarterly security review required for compliance

**Steps:**
```bash
# 1. Run security audit
./azure-security-compliance-audit.sh

# 2. Review findings
cd azure-security-audit-*/
cat 00-SECURITY-SUMMARY.txt

# 3. Document critical findings
grep -r "WARNING" . > critical-security-findings.txt

# 4. Create remediation plan
# Use findings to create tickets for team with write access
```

### Use Case 4: Pre-Migration Assessment

**Scenario:** Planning to migrate workloads, need current state

**Steps:**
```bash
# 1. Complete inventory
./azure-resource-inventory.sh

# 2. Document dependencies
# Review network topology in 08-networking.txt
# Review database connections in 09-databases.txt

# 3. Analyze costs
# Review current spending to estimate post-migration costs
```

---

## 🔐 Required Azure Roles

### Minimum Required Role: **Reader**

**Capabilities with Reader:**
- ✅ View all resources
- ✅ Run inventory scripts
- ✅ Export configurations
- ✅ View basic metrics
- ❌ View detailed cost data
- ❌ View security assessments

### Recommended Roles for Full Functionality:

1. **Reader** (Minimum)
   - Basic resource visibility
   - Configuration viewing

2. **Cost Management Reader** (Highly Recommended)
   - Required for: Cost analysis queries
   - Enables: Budget viewing, cost exports

3. **Security Reader** (Recommended)
   - Required for: Complete security audits
   - Enables: Security Center access, alert viewing

4. **Monitoring Reader** (Optional)
   - Enhanced Log Analytics access
   - Better metrics visibility

### Requesting Additional Access

If you need broader access, request these roles from your Azure administrator:

```
Role Request Template:
---------------------
To: Azure Administrator
Subject: Request for Additional Azure Roles

I would like to request the following Azure roles for better infrastructure visibility:

1. Cost Management Reader (Subscription level)
   - Purpose: Generate cost reports and analysis
   - Scope: [Your Subscription Name/ID]

2. Security Reader (Subscription level)
   - Purpose: Run security audits and compliance checks
   - Scope: [Your Subscription Name/ID]

Current Access: Reader
Business Justification: [Your reason]

These are read-only roles and will not allow any modifications to resources.
```

---

## 📖 Best Practices

### 1. Regular Auditing Schedule

```bash
# Create a cron job for weekly inventory (Linux/macOS)
# Add to crontab: crontab -e

# Run every Monday at 9 AM
0 9 * * 1 /path/to/azure-resource-inventory.sh

# Run security audit every Friday at 2 PM
0 14 * * 5 /path/to/azure-security-compliance-audit.sh
```

### 2. Version Control Your Outputs

```bash
# Create a Git repository for audit results
mkdir azure-audit-history
cd azure-audit-history
git init

# After each run, commit results
cp -r ../azure-inventory-* ./
git add .
git commit -m "Inventory snapshot $(date +%Y-%m-%d)"

# Track changes over time
git log --oneline
git diff HEAD~1 -- */00-SUMMARY.txt
```

### 3. Automate Reporting

**Create a wrapper script:**
```bash
#!/bin/bash
# File: weekly-azure-audit.sh

DATE=$(date +%Y-%m-%d)
REPORT_DIR="weekly-reports/$DATE"
mkdir -p "$REPORT_DIR"

# Run inventory
./azure-resource-inventory.sh
mv azure-inventory-* "$REPORT_DIR/"

# Run security audit
./azure-security-compliance-audit.sh
mv azure-security-audit-* "$REPORT_DIR/"

# Generate cost report
az costmanagement query --type "Usage" --dataset-aggregation totalCost=sum \
  --timeframe "MonthToDate" \
  --scope "/subscriptions/$(az account show --query id -o tsv)" \
  --output table > "$REPORT_DIR/weekly-costs.txt"

# Create summary email
echo "Weekly Azure Audit Complete - $DATE" > "$REPORT_DIR/summary.txt"
echo "Reports available at: $REPORT_DIR" >> "$REPORT_DIR/summary.txt"

# Optional: Send email
# mail -s "Azure Weekly Audit - $DATE" team@company.com < "$REPORT_DIR/summary.txt"

echo "✓ Weekly audit complete: $REPORT_DIR"
```

### 4. Data Retention

```bash
# Keep last 90 days of reports
find weekly-reports/ -type d -mtime +90 -exec rm -rf {} +

# Archive older reports
tar -czf archives/reports-$(date +%Y-%m).tar.gz weekly-reports/
```

---

## 🛠️ Troubleshooting

### Issue: "Permission Denied" Errors

**Solution:**
```bash
# Make scripts executable
chmod +x azure-resource-inventory.sh
chmod +x azure-security-compliance-audit.sh

# Or run with bash explicitly
bash azure-resource-inventory.sh
```

### Issue: "Subscription Not Found"

**Solution:**
```bash
# List available subscriptions
az account list --output table

# Set the correct subscription
az account set --subscription "SUBSCRIPTION_ID_OR_NAME"

# Verify
az account show
```

### Issue: "Cost Management Data Not Accessible"

**Problem:** Reader role doesn't include cost data access

**Solution:**
Request "Cost Management Reader" role from your administrator

### Issue: "Security Center Data Not Available"

**Problem:** Reader role has limited security data access

**Solution:**
Request "Security Reader" role for enhanced security visibility

### Issue: PowerShell Module Not Found

**Solution:**
```powershell
# Install required modules
Install-Module -Name Az -Repository PSGallery -Force
Install-Module -Name Az.CostManagement -Repository PSGallery -Force

# Import modules
Import-Module Az
Import-Module Az.CostManagement
```

---

## 📚 Additional Resources

### Official Microsoft Documentation
- [Azure RBAC Documentation](https://docs.microsoft.com/azure/role-based-access-control/)
- [Azure Cost Management](https://docs.microsoft.com/azure/cost-management-billing/)
- [Azure Security Center](https://docs.microsoft.com/azure/security-center/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure PowerShell Reference](https://docs.microsoft.com/powershell/azure/)

### Cost Optimization
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Advisor](https://portal.azure.com/#blade/Microsoft_Azure_Expert/AdvisorMenuBlade/overview)
- [FinOps Foundation](https://www.finops.org/)

### Security & Compliance
- [Azure Security Benchmark](https://docs.microsoft.com/security/benchmark/azure/)
- [Azure Compliance Documentation](https://docs.microsoft.com/azure/compliance/)
- [CIS Azure Benchmarks](https://www.cisecurity.org/benchmark/azure)

---

## 🤝 Contributing

If you develop additional tools or scripts for reader-level Azure access:

1. Ensure they only use read operations
2. Add clear documentation
3. Include error handling for permission issues
4. Update this guide with new capabilities

---

## 📞 Support

### Common Questions

**Q: Can I run these scripts in Azure Cloud Shell?**
A: Yes! All scripts are compatible with Azure Cloud Shell (bash version).

**Q: How often should I run audits?**
A: Recommended: Daily (cost check), Weekly (inventory), Monthly (full audit)

**Q: Can I export data to other formats?**
A: Yes! Use `--output json` or `--output table` with Azure CLI, or pipe to CSV.

**Q: Will these scripts work with Azure Government?**
A: Yes, but you need to set the appropriate cloud:
```bash
az cloud set --name AzureUSGovernment
az login
```

---

## 📄 License

This repository contains documentation and tools for Azure infrastructure management.
Use according to your organization's policies and Azure terms of service.

---

**Last Updated:** January 11, 2026
**Version:** 1.0
**Maintained By:** DevOps Team
