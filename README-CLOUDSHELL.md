# Azure Cloud Shell - Tenant Reader Toolkit

**Quick Start Guide for Azure Cloud Shell with Tenant Reader Access**

---

## 🚀 Getting Started (3 Simple Steps)

### Step 1: Open Azure Cloud Shell
1. Go to https://portal.azure.com
2. Click the Cloud Shell icon **`>_`** in the top menu bar
3. Select **Bash** when prompted

### Step 2: Download This Repository
```bash
# Option A: If this is a Git repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

# Option B: Download scripts individually (if hosted)
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cloudshell-quickstart.sh
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/cloudshell-tenant-inventory.sh

# Option C: Copy files to Cloud Shell manually
# 1. Click Upload/Download icon in Cloud Shell
# 2. Upload the .sh files
```

### Step 3: Run Quick Start
```bash
# Make scripts executable
chmod +x *.sh

# Run the quick start check
./cloudshell-quickstart.sh
```

**That's it!** The quick start will tell you exactly what you can access and what to run next.

---

## 📁 What's Included

### 🔧 Scripts (For Cloud Shell)

| Script | Purpose | Use When |
|--------|---------|----------|
| **cloudshell-quickstart.sh** | Check your access level | Run this FIRST |
| **cloudshell-tenant-inventory.sh** | Azure AD & tenant audit | Tenant Reader access |
| **azure-resource-inventory.sh** | Full infrastructure audit | Subscription Reader access |
| **azure-security-compliance-audit.sh** | Security assessment | Subscription Reader access |

### 📚 Documentation

| File | Purpose |
|------|---------|
| **CLOUDSHELL-TENANT-READER-GUIDE.md** | Complete guide for Tenant Reader |
| **QUICK-REFERENCE.md** | One-page command cheat sheet |
| **AZURE-READER-ACCESS-GUIDE.md** | Full guide for all reader access levels |
| **azure-cost-analysis-queries.md** | Cost analysis commands |
| **azure-cost-optimization-report.md** | Cost savings recommendations |

---

## 🎯 What Can You Do with Tenant Reader?

### ✅ You CAN Access:
- Azure AD users and groups
- Service principals and applications
- List of all subscriptions in tenant
- Your own role assignments
- Tenant-level governance data

### ❌ You CANNOT Access (without additional roles):
- Virtual machines, AKS, storage in subscriptions
- Cost and billing data
- Detailed security assessments
- Key vault secrets
- Resource configurations

---

## 🔄 Typical Workflow

### First Time Setup
```bash
# 1. Check your access
./cloudshell-quickstart.sh

# 2. Run tenant inventory
./cloudshell-tenant-inventory.sh

# 3. View the summary
cat tenant-inventory-*/00-SUMMARY.txt

# 4. Save to persistent storage
cp tenant-inventory-*.tar.gz ~/clouddrive/
```

### Regular Usage
```bash
# Weekly: Run tenant inventory
./cloudshell-tenant-inventory.sh

# View Azure AD user count
az ad user list --query 'length([])' -o tsv

# Check for guest users
az ad user list --query "[?userType=='Guest'].userPrincipalName" -o table

# List all subscriptions
az account list -o table

# Switch subscription
az account set --subscription "Subscription Name"
```

---

## 📊 Common Commands for Tenant Reader

### Azure AD Queries
```bash
# List all users
az ad user list -o table

# Count users
az ad user list --query 'length([])' -o tsv

# Find guest users
az ad user list --query "[?userType=='Guest']" -o table

# List groups
az ad group list -o table

# Find disabled accounts
az ad user list --query "[?accountEnabled==\`false\`]" -o table

# Service principals
az ad sp list --all -o table
```

### Multi-Subscription Queries
```bash
# List all subscriptions
az account list -o table

# Check access to each subscription
for sub in $(az account list --query "[].id" -o tsv); do
  az account set --subscription "$sub"
  echo "Subscription: $(az account show --query name -o tsv)"
  az group list --query 'length([])' -o tsv 2>/dev/null || echo "No access"
done
```

### Your Access
```bash
# Show current user
az account show --query user.name -o tsv

# Your role assignments
az role assignment list --assignee $(az account show --query user.name -o tsv) -o table

# Current tenant
az account show --query tenantId -o tsv
```

---

## 🔐 Requesting Additional Access

If you need to access subscription resources, use this template:

```
To: [Azure Administrator Email]
Subject: Request for Azure Subscription Reader Access

Hello,

I currently have Tenant Reader access and would like to request additional
permissions to perform infrastructure auditing and cost analysis.

Current Role: Tenant Reader
Requested Roles:
  1. Reader (on subscriptions: [LIST SUBSCRIPTION NAMES])
  2. Cost Management Reader (on subscriptions: [LIST SUBSCRIPTION NAMES])

Purpose:
  - Infrastructure inventory and documentation
  - Cost optimization analysis
  - Security compliance reporting

These are read-only roles with no modification capabilities.

Business Justification: [YOUR REASON]

Thank you,
[Your Name]
```

---

## 💾 Saving Your Work in Cloud Shell

Cloud Shell sessions timeout after 20 minutes of inactivity, but you can persist data:

### Use Cloud Drive (Persistent Storage)
```bash
# Cloud Shell has a persistent drive at ~/clouddrive
cd ~/clouddrive

# Create a directory for scripts
mkdir -p azure-scripts
cd azure-scripts

# Copy your scripts here
cp ~/cloudshell-*.sh .
cp ~/azure-*.sh .

# Scripts will be available in future sessions
ls ~/clouddrive/azure-scripts/

# Save outputs
./cloudshell-tenant-inventory.sh
cp tenant-inventory-*.tar.gz ~/clouddrive/
```

### Download Results to Your Computer
```bash
# After running a script
./cloudshell-tenant-inventory.sh

# In Cloud Shell, click Upload/Download icon (folder with arrow)
# Select "Download"
# Enter filename: tenant-inventory-YYYYMMDD-HHMMSS.tar.gz
```

---

## 🎨 Customization

### Create Aliases
```bash
# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'
# Azure shortcuts
alias azl='az account list -o table'
alias azs='az account set --subscription'
alias azshow='az account show'
alias adusers='az ad user list -o table'
alias adgroups='az ad group list -o table'
alias myaccess='az role assignment list --assignee $(az account show -s "$(az account list --all --query "[0].id" -o tsv)" --query user.name -o tsv) -o table'
EOF

# Reload
source ~/.bashrc

# Use aliases
azl              # List subscriptions
adusers          # List Azure AD users
myaccess         # Show your roles
```

### Create Daily Report Script
```bash
cat > ~/clouddrive/daily-check.sh << 'EOF'
#!/bin/bash
echo "=== Azure Daily Check - $(date) ==="
echo ""
echo "Current User: $(az account show --query user.name -o tsv)"
echo "Subscriptions: $(az account list --query 'length([])' -o tsv)"
echo "Azure AD Users: $(az ad user list --query 'length([])' -o tsv)"
echo "Azure AD Groups: $(az ad group list --query 'length([])' -o tsv)"
echo ""
echo "Guest Users:"
az ad user list --query "[?userType=='Guest'].userPrincipalName" -o table
EOF

chmod +x ~/clouddrive/daily-check.sh

# Run anytime
~/clouddrive/daily-check.sh
```

---

## 🐛 Troubleshooting

### "Permission Denied" on Scripts
```bash
chmod +x *.sh
```

### "Command Not Found: az"
Cloud Shell has Azure CLI pre-installed. If you see this:
```bash
# Verify you're in Bash (not PowerShell)
echo $SHELL
# Should show: /bin/bash

# If in PowerShell, type:
bash
```

### "Insufficient Privileges" Errors
This is normal with Tenant Reader. You need additional roles for:
- Subscription resources → Request "Reader" role
- Cost data → Request "Cost Management Reader" role
- Security data → Request "Security Reader" role

### Cloud Shell Timeout
Cloud Shell times out after 20 minutes of inactivity.
```bash
# Keep alive with a simple loop
while true; do echo "$(date)"; sleep 300; done &

# Or just reconnect - your files in ~/clouddrive will persist
```

### Can't Download Files
```bash
# Files must be in your home directory to download
cp output-file.tar.gz ~/

# Then use the Download feature in Cloud Shell UI
```

---

## 📈 Next Steps After Running Scripts

### 1. Review Your Tenant Inventory
```bash
./cloudshell-tenant-inventory.sh
cat tenant-inventory-*/00-SUMMARY.txt
```

**Look for:**
- Number of guest users (potential security review)
- Disabled accounts (cleanup opportunity)
- Service principals (identify unused apps)
- Subscription access gaps

### 2. If You Get Subscription Reader Access
```bash
# Run full infrastructure audit
./azure-resource-inventory.sh

# Run security audit
./azure-security-compliance-audit.sh

# Review cost optimization
cat azure-cost-optimization-report.md
```

### 3. Set Up Regular Reporting
```bash
# Weekly tenant audit
cd ~/clouddrive
cat > weekly-audit.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d)
~/clouddrive/azure-scripts/cloudshell-tenant-inventory.sh
cp tenant-inventory-*.tar.gz ~/clouddrive/reports/weekly-$DATE.tar.gz
echo "Weekly report saved to ~/clouddrive/reports/weekly-$DATE.tar.gz"
EOF

chmod +x weekly-audit.sh
mkdir -p ~/clouddrive/reports
```

---

## 📚 Learning Resources

### Azure CLI Documentation
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure AD Commands](https://docs.microsoft.com/cli/azure/ad)
- [JMESPath Queries](https://jmespath.org/tutorial.html)

### Cloud Shell
- [Cloud Shell Overview](https://docs.microsoft.com/azure/cloud-shell/overview)
- [Persisting Files](https://docs.microsoft.com/azure/cloud-shell/persisting-shell-storage)

### RBAC & Roles
- [Azure Built-in Roles](https://docs.microsoft.com/azure/role-based-access-control/built-in-roles)
- [Tenant Reader Role](https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#tenant-reader)

---

## 🎯 Quick Reference Card

```bash
# Essential Commands - Keep This Handy

# Check who you are
az account show

# List subscriptions
az account list -o table

# Switch subscription
az account set --subscription "NAME"

# List Azure AD users
az ad user list -o table

# List groups
az ad group list -o table

# Your roles
az role assignment list --assignee $(az account show --query user.name -o tsv) -o table

# Run quick check
./cloudshell-quickstart.sh

# Run tenant inventory
./cloudshell-tenant-inventory.sh

# Help
az --help
az COMMAND --help
```

---

## ✨ Pro Tips

1. **Persist Your Scripts**: Always keep scripts in `~/clouddrive/`
2. **Use Tab Completion**: Type `az acc<TAB>` to auto-complete
3. **Format Output**: Try `-o table`, `-o json`, `-o tsv`
4. **Query Results**: Use `--query` with JMESPath for filtering
5. **Save Common Commands**: Create aliases in `~/.bashrc`
6. **Download Reports**: Use Cloud Shell's download feature for sharing
7. **Multiple Tabs**: Open multiple Cloud Shell tabs for parallel work

---

## 🆘 Need Help?

1. **Check the guides**:
   - `cat CLOUDSHELL-TENANT-READER-GUIDE.md` (detailed guide)
   - `cat QUICK-REFERENCE.md` (command reference)

2. **Azure CLI help**:
   ```bash
   az --help
   az ad user --help
   ```

3. **Contact your Azure admin** if you need additional access

---

**Happy Exploring! 🚀**

Start with `./cloudshell-quickstart.sh` to understand your access level,
then proceed to the appropriate inventory script for your environment.
