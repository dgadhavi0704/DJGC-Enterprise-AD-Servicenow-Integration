<#
.SYNOPSIS
    Creates license security groups (F1, E3, PowerBI) for DJ Group of Companies
    and assigns all 25 existing users to the correct group(s) based on role.

.NOTES
    Run this ON the domain controller (or a machine with RSAT AD PowerShell module),
    logged in as a Domain Admin. Assumes New-DJGCUsers.ps1 has already been run,
    so all 25 users and the DJGC-Groups OU already exist.
#>

Import-Module ActiveDirectory

$DomainDN   = "DC=corp,DC=djgroup,DC=com"
$GroupsPath = "OU=DJGC-Groups,$DomainDN"

# ---------------------------------------------------------------------------
# 1. Create the three license groups if they don't already exist
# ---------------------------------------------------------------------------
$LicenseGroups = @("SG-License-F1", "SG-License-E3", "SG-License-PowerBI")

foreach ($g in $LicenseGroups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $GroupsPath
        Write-Host "Created group: $g" -ForegroundColor Green
    } else {
        Write-Host "Group already exists: $g" -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
# 2. Role -> license mapping
#    E3   = full Office/Exchange users (office & knowledge workers)
#    F1   = frontline/limited users (warehouse, site-based roles)
#    PBI  = PowerBI add-on (finance, reporting, leadership analytics)
# ---------------------------------------------------------------------------
$LicenseMap = @{
    "dsharma"  = @("E3","PBI")   # President & Principal Broker
    "mgonzales"= @("E3")         # Brokerage Sales Manager
    "jwong"    = @("E3")         # Senior Real Estate Agent
    "ppatel"   = @("E3","PBI")   # Corporate Services Lead
    "jsmith"   = @("E3")         # Real Estate Agent
    "jsmith2"  = @("E3")         # Real Estate Agent
    "rchen"    = @("E3","PBI")   # Accountant
    "aklein"   = @("E3")         # HR Generalist
    "kosei"    = @("E3")         # IT Support Specialist
    "lbennett" = @("E3")         # Marketing Coordinator

    "mtorres"  = @("E3","PBI")   # Construction Director
    "spark"    = @("E3")         # Project Manager
    "cmendez"  = @("F1")         # Site Supervisor
    "ahussain" = @("F1")         # Site Coordinator
    "bfischer" = @("F1")         # Site Coordinator
    "nadams"   = @("E3","PBI")   # Estimator

    "slee"     = @("E3")         # Building Materials Manager
    "tbrooks"  = @("F1")         # Warehouse Supervisor
    "omartin"  = @("E3")         # Sales Rep
    "dnguyen"  = @("F1")         # Warehouse Staff
    "fibrahim" = @("F1")         # Warehouse Staff

    "rkim"     = @("E3")         # Property Manager
    "valvarez" = @("E3")         # Leasing & Maintenance Coordinator
    "gnovak"   = @("F1")         # Maintenance Technician
    "hcole"    = @("E3")         # Tenant Services Coordinator
}

$GroupNameFor = @{
    "E3"  = "SG-License-E3"
    "F1"  = "SG-License-F1"
    "PBI" = "SG-License-PowerBI"
}

# ---------------------------------------------------------------------------
# 3. Assign each user to their mapped group(s)
# ---------------------------------------------------------------------------
foreach ($sam in $LicenseMap.Keys) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
        Write-Host "Skipping $sam - user not found in AD" -ForegroundColor Red
        continue
    }

    foreach ($lic in $LicenseMap[$sam]) {
        $groupName = $GroupNameFor[$lic]
        try {
            Add-ADGroupMember -Identity $groupName -Members $sam
            Write-Host "Added $sam to $groupName" -ForegroundColor Green
        } catch {
            Write-Host "Could not add $sam to $groupName : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone. License groups created and $($LicenseMap.Count) users assigned." -ForegroundColor Magenta
