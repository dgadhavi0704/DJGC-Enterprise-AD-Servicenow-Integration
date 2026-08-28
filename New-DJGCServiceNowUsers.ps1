<#
.SYNOPSIS
    Creates sys_user records in ServiceNow for all 25 DJGC lab employees, so
    ticket reference fields (like Employee Name / Manager) can point at real
    ServiceNow users - matching how production reference fields work.

.NOTES
    Assumes $instance and $headers (valid Bearer token) are already set.
    user_name is set to match the AD SamAccountName exactly, so the script
    can later resolve tickets back to a real AD account by username.
#>

$djgcUsers = @(
    @{ user_name = "dsharma";   first_name = "David";   last_name = "Sharma";   email = "dsharma@djgroup.com";   title = "President & Principal Broker" },
    @{ user_name = "mgonzales"; first_name = "Maria";   last_name = "Gonzales"; email = "mgonzales@djgroup.com"; title = "Brokerage Sales Manager" },
    @{ user_name = "jwong";     first_name = "James";   last_name = "Wong";     email = "jwong@djgroup.com";     title = "Senior Real Estate Agent" },
    @{ user_name = "ppatel";    first_name = "Priya";   last_name = "Patel";    email = "ppatel@djgroup.com";    title = "Corporate Services Lead" },
    @{ user_name = "jsmith";    first_name = "John";    last_name = "Smith";    email = "jsmith@djgroup.com";    title = "Real Estate Agent" },
    @{ user_name = "jsmith2";   first_name = "Jane";    last_name = "Smith";    email = "jsmith2@djgroup.com";   title = "Real Estate Agent" },
    @{ user_name = "rchen";     first_name = "Robert";  last_name = "Chen";     email = "rchen@djgroup.com";     title = "Accountant" },
    @{ user_name = "aklein";    first_name = "Amanda";  last_name = "Klein";    email = "aklein@djgroup.com";    title = "HR Generalist" },
    @{ user_name = "kosei";     first_name = "Kevin";   last_name = "Osei";     email = "kosei@djgroup.com";     title = "IT Support Specialist" },
    @{ user_name = "lbennett";  first_name = "Laura";   last_name = "Bennett";  email = "lbennett@djgroup.com";  title = "Marketing Coordinator" },

    @{ user_name = "mtorres";   first_name = "Michael"; last_name = "Torres";   email = "mtorres@djgroup.com";   title = "Construction Director" },
    @{ user_name = "spark";     first_name = "Steven";  last_name = "Park";     email = "spark@djgroup.com";     title = "Project Manager" },
    @{ user_name = "cmendez";   first_name = "Carlos";  last_name = "Mendez";   email = "cmendez@djgroup.com";   title = "Site Supervisor" },
    @{ user_name = "ahussain";  first_name = "Ahmed";   last_name = "Hussain";  email = "ahussain@djgroup.com";  title = "Site Coordinator" },
    @{ user_name = "bfischer";  first_name = "Brian";   last_name = "Fischer";  email = "bfischer@djgroup.com";  title = "Site Coordinator" },
    @{ user_name = "nadams";    first_name = "Nicole";  last_name = "Adams";    email = "nadams@djgroup.com";    title = "Estimator" },

    @{ user_name = "slee";      first_name = "Sandra";  last_name = "Lee";      email = "slee@djgroup.com";      title = "Building Materials Manager" },
    @{ user_name = "tbrooks";   first_name = "Tyler";   last_name = "Brooks";   email = "tbrooks@djgroup.com";   title = "Warehouse Supervisor" },
    @{ user_name = "omartin";   first_name = "Olivia";  last_name = "Martin";   email = "omartin@djgroup.com";   title = "Sales Rep" },
    @{ user_name = "dnguyen";   first_name = "Derek";   last_name = "Nguyen";   email = "dnguyen@djgroup.com";   title = "Warehouse Staff" },
    @{ user_name = "fibrahim";  first_name = "Frank";   last_name = "Ibrahim";  email = "fibrahim@djgroup.com";  title = "Warehouse Staff" },

    @{ user_name = "rkim";      first_name = "Rachel";  last_name = "Kim";      email = "rkim@djgroup.com";      title = "Property Manager" },
    @{ user_name = "valvarez";  first_name = "Victor";  last_name = "Alvarez";  email = "valvarez@djgroup.com";  title = "Leasing & Maintenance Coordinator" },
    @{ user_name = "gnovak";    first_name = "George";  last_name = "Novak";    email = "gnovak@djgroup.com";    title = "Maintenance Technician" },
    @{ user_name = "hcole";     first_name = "Hannah";  last_name = "Cole";     email = "hcole@djgroup.com";     title = "Tenant Services Coordinator" }
)

foreach ($u in $djgcUsers) {

    # Skip if this user already exists (avoids duplicate creation on re-runs)
    $existing = Invoke-RestMethod -Uri "$instance/api/now/table/sys_user?sysparm_query=user_name=$($u.user_name)" -Headers $headers -Method Get
    if ($existing.result.Count -gt 0) {
        Write-Host "SKIPPING $($u.user_name) - already exists" -ForegroundColor Yellow
        continue
    }

    $body = @{
        user_name  = $u.user_name
        first_name = $u.first_name
        last_name  = $u.last_name
        email      = $u.email
        title      = $u.title
        active     = "true"
    } | ConvertTo-Json

    try {
        $newUser = Invoke-RestMethod -Uri "$instance/api/now/table/sys_user" -Headers $headers -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-Host "Created sys_user: $($u.user_name) ($($u.first_name) $($u.last_name))" -ForegroundColor Green
    } catch {
        Write-Host "FAILED for $($u.user_name): $_" -ForegroundColor Red
    }
}

Write-Host "`nDone." -ForegroundColor Magenta
