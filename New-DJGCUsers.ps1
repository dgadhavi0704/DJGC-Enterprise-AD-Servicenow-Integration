<#
.SYNOPSIS
    Builds OUs, security groups, and 25 users for DJ Group of Companies from a CSV export.

.NOTES
    Run this ON the domain controller (or a machine with RSAT AD PowerShell module),
    logged in as a Domain Admin.
    Place DJGC_Employee_Roster.csv in the same folder as this script, or edit $CsvPath.
#>

Import-Module ActiveDirectory

$CsvPath   = "C:\AD Scripts\Company scv files\DJGC_Employee_Roster.csv"
$DomainDN  = "DC=corp,DC=djgroup,DC=com"

# ---------------------------------------------------------------------------
# 1. OU structure — already built manually. This just verifies it's all there
#    before we try to create users into it. Nothing is created in this step.

<# this command were used to create the OU structure:

$DomainDN = "DC=corp,DC=djgroup,DC=com"

$Departments = @(
    "DJGC-HeadOffice",
    "DJGC-Construction",
    "DJGC-BuildingMaterials",
    "DJGC-PropertyMgmt"
)

foreach ($Department in $Departments) {

    New-ADOrganizationalUnit `
        -Name $Department `
        -Path $DomainDN

    New-ADOrganizationalUnit `
        -Name "Users" `
        -Path "OU=$Department,$DomainDN"

    New-ADOrganizationalUnit `
        -Name "Computers" `
        -Path "OU=$Department,$DomainDN"
}

New-ADOrganizationalUnit -Name "DJGC-Admins" -Path $DomainDN
New-ADOrganizationalUnit -Name "DJGC-ServiceAccounts" -Path $DomainDN
New-ADOrganizationalUnit -Name "DJGC-Disabled" -Path $DomainDN
New-ADOrganizationalUnit -Name "DJGC-Groups" -Path $DomainDN
#>

# ---------------------------------------------------------------------------
$Divisions = @("DJGC-HeadOffice", "DJGC-Construction", "DJGC-BuildingMaterials", "DJGC-PropertyMgmt")
$RequiredOUs = @()
foreach ($div in $Divisions) {
    $RequiredOUs += "OU=Users,OU=$div,$DomainDN"
    $RequiredOUs += "OU=Computers,OU=$div,$DomainDN"
}
$RequiredOUs += @("OU=DJGC-Admins,$DomainDN", "OU=DJGC-ServiceAccounts,$DomainDN", "OU=DJGC-Disabled,$DomainDN", "OU=DJGC-Groups,$DomainDN")

$missing = @()
foreach ($ou in $RequiredOUs) {
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue)) {
        $missing += $ou
    }
}
if ($missing.Count -gt 0) {
    Write-Host "STOPPING: the following expected OUs were not found:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    return
}
Write-Host "OU structure verified OK." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 2. Security groups — already built manually in DJGC-Groups.
#    This step just verifies they all exist before user creation tries to
#    add members to them in Step 5. Nothing is created here either.

<# $Groups = @(
 "SG-AllStaff",
 "SG-Executives",
 "SG-HeadOffice-Users",
 "SG-Construction-Users",
 "SG-BuildingMaterials-Users",
 "SG-PropertyMgmt-Users",
 "SG-Finance-ReadWrite",
 "SG-HR-ReadWrite",
 "SG-IT-Admins",
 "SG-Brokerage-Agents",
 "SG-Construction-SiteApps"
 "SG-Materials-Inventory",
 "SG-PropertyMgmt-LeasingSystem",
 "SG-VPN-Access",
 "SG-Printers-HeadOffice",
 )

 foreach ($Group in $Groups) {
     New-ADGroup `
         -Name $Group `
         -GroupScope Global `
         -GroupCategory Security `
         -Path "OU=DJGC-Groups,DC=corp,DC=djgroup,DC=com"
#>

# ---------------------------------------------------------------------------
$Groups = @(
    "SG-AllStaff", "SG-Executives",
    "SG-HeadOffice-Users", "SG-Construction-Users", "SG-BuildingMaterials-Users", "SG-PropertyMgmt-Users",
    "SG-Finance-ReadWrite", "SG-HR-ReadWrite", "SG-IT-Admins",
    "SG-Brokerage-Agents", "SG-Construction-SiteApps", "SG-Materials-Inventory",
    "SG-PropertyMgmt-LeasingSystem", "SG-VPN-Access", "SG-Printers-HeadOffice"
)

$missingGroups = @()
foreach ($g in $Groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
        $missingGroups += $g
    }
}
if ($missingGroups.Count -gt 0) {
    Write-Host "STOPPING: the following expected groups were not found:" -ForegroundColor Red
    $missingGroups | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    return
}
Write-Host "Security groups verified OK." -ForegroundColor Green

# ---------------------------------------------------------------------------
# 3. Import users (pass 1: create accounts, no manager link yet)
# ---------------------------------------------------------------------------
$rows = Import-Csv -Path $CsvPath

foreach ($row in $rows) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($row.SamAccountName)'" -ErrorAction SilentlyContinue) {
        Write-Host "Skipping existing user: $($row.SamAccountName)" -ForegroundColor Yellow
        continue
    }

    $securePwd = ConvertTo-SecureString $row.InitialPassword -AsPlainText -Force

    New-ADUser `
        -Name $row.DisplayName `
        -GivenName $row.FirstName `
        -Surname $row.LastName `
        -DisplayName $row.DisplayName `
        -SamAccountName $row.SamAccountName `
        -UserPrincipalName $row.UserPrincipalName `
        -EmailAddress $row.Email `
        -Title $row.Title `
        -Department $row.Division `
        -Company "DJ Group of Companies" `
        -Path $row.OUPath `
        -AccountPassword $securePwd `
        -Enabled $true `
        -ChangePasswordAtLogon $true

    Write-Host "Created user: $($row.SamAccountName)" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 4. Pass 2: set the Manager attribute (needs everyone to exist first)
# ---------------------------------------------------------------------------
foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.ManagerSamAccountName)) { continue }
    try {
        Set-ADUser -Identity $row.SamAccountName -Manager $row.ManagerSamAccountName
    } catch {
        Write-Host "Could not set manager for $($row.SamAccountName): $_" -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------------
# 5. Pass 3: add each user to their security groups
# ---------------------------------------------------------------------------
foreach ($row in $rows) {
    $groupList = $row.SecurityGroups -split ";"
    foreach ($g in $groupList) {
        try {
            Add-ADGroupMember -Identity $g -Members $row.SamAccountName
        } catch {
            Write-Host "Could not add $($row.SamAccountName) to $g : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nDone. Verified $($RequiredOUs.Count) OUs, verified $($Groups.Count) groups, processed $($rows.Count) users." -ForegroundColor Magenta
