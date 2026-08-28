<#
.SYNOPSIS
    End-to-end DJGC lab offboarding automation.

    1. Pulls open "Account Deprecation" RITMs from ServiceNow
    2. Resolves the Employee Name / Manager reference variables to real
       usernames (no manual UPN lookup)
    3. Skips any ticket whose Effective End Date hasn't fully passed yet
       (that date = last working day - person should still have access
       through end of that day)
    4. Skips (with a note) any user who is already deprecated, instead of
       erroring or re-processing
    5. Deprecates the AD account: disable, strip ALL group membership,
       move to DJGC-Disabled OU
    6. Writes a real summary back to the ticket as a work note
       (closing the ticket itself is left for a person to do)

.NOTES
    Assumes $instance and $headers (valid Bearer token) are already set.
    Run on a machine with the RSAT Active Directory module available.
#>

Import-Module ActiveDirectory

$DomainDN   = "DC=corp,DC=djgroup,DC=com"
$DisabledOU = "OU=DJGC-Disabled,$DomainDN"

# ---------------------------------------------------------------------------
# 1. Pull open Account Deprecation RITMs
#    (filtered by catalog item name, not short description - more reliable,
#    matches how the ticket was actually generated)
# ---------------------------------------------------------------------------
$query  = "cat_item.name=Account Deprecation^active=true"
$fields = "number,sys_id,variables.employee_name,variables.manager,variables.effective_end_date,variables.mailbox_forwarding"

$uri = "$instance/api/now/table/sc_req_item?sysparm_query=$query&sysparm_fields=$fields&sysparm_display_value=all"
$openTickets = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

Write-Host "Found $($openTickets.result.Count) open Account Deprecation ticket(s)." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 2. Process each ticket
# ---------------------------------------------------------------------------
foreach ($ticket in $openTickets.result) {

    $ticketNumber = $ticket.number.value
    $sysId        = $ticket.sys_id.value

    Write-Host "`nProcessing $ticketNumber" -ForegroundColor Cyan

    try {
        # -- Pull the employee reference (sys_id) and resolve it to a real username --
        $employeeSysId = $ticket.'variables.employee_name'.value
        $employeeName  = $ticket.'variables.employee_name'.display_value

        if ([string]::IsNullOrWhiteSpace($employeeSysId)) {
            Write-Host "  SKIPPING - no Employee Name set on this ticket" -ForegroundColor Yellow
            $body = @{ work_notes = "Skipped by automation: no Employee Name set on this ticket. Manual review required." } | ConvertTo-Json
            Invoke-RestMethod -Uri "$instance/api/now/table/sc_req_item/$sysId" -Headers $headers -Method Patch -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
            continue
        }

        $employee = Invoke-RestMethod -Uri "$instance/api/now/table/sys_user/$employeeSysId" -Headers $headers -Method Get
        $samAccountName = $employee.result.user_name

        Write-Host "  Employee: $employeeName ($samAccountName)" -ForegroundColor Cyan

        # -- Check the Effective End Date - skip if the last working day hasn't fully passed --
        $effectiveEndRaw = $ticket.'variables.effective_end_date'.value
        $effectiveEnd    = [datetime]$effectiveEndRaw
        $today           = (Get-Date).Date

        if ($effectiveEnd.Date -ge $today) {
            Write-Host "  SKIPPING - Effective End Date ($($effectiveEnd.Date.ToShortDateString())) has not fully passed yet" -ForegroundColor Yellow
            $body = @{ work_notes = "Not yet processed: Effective End Date ($($effectiveEnd.Date.ToShortDateString())) has not fully passed. Will be picked up automatically once it has." } | ConvertTo-Json
            Invoke-RestMethod -Uri "$instance/api/now/table/sc_req_item/$sysId" -Headers $headers -Method Patch -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
            continue
        }

        # -- Confirm the AD account actually exists --
        $adUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -Properties Enabled, DistinguishedName -ErrorAction SilentlyContinue

        if (-not $adUser) {
            Write-Host "  AD user not found - skipping AD actions" -ForegroundColor Red
            $body = @{ work_notes = "Automation could not find AD account '$samAccountName'. No action taken. Manual review required." } | ConvertTo-Json
            Invoke-RestMethod -Uri "$instance/api/now/table/sc_req_item/$sysId" -Headers $headers -Method Patch -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
            continue
        }

        # -- Already deprecated? Let us know and move on, don't re-process --
        if (-not $adUser.Enabled) {
            Write-Host "  Already deprecated - account is already disabled" -ForegroundColor Yellow
            $body = @{ work_notes = "No action needed: '$samAccountName' is already deprecated (account already disabled)." } | ConvertTo-Json
            Invoke-RestMethod -Uri "$instance/api/now/table/sc_req_item/$sysId" -Headers $headers -Method Patch -Body $body -ContentType "application/json" -ErrorAction Stop | Out-Null
            continue
        }

        # -- Disable the account --
        Disable-ADAccount -Identity $samAccountName
        Write-Host "  Disabled account" -ForegroundColor Green

        # -- Remove from ALL groups (except the built-in Domain Users primary group) --
        $currentGroups = Get-ADPrincipalGroupMembership -Identity $samAccountName |
            Where-Object { $_.Name -ne "Domain Users" }

        $removedGroups = @()
        foreach ($grp in $currentGroups) {
            Remove-ADGroupMember -Identity $grp.DistinguishedName -Members $samAccountName -Confirm:$false
            $removedGroups += $grp.Name
            Write-Host "  Removed from $($grp.Name)" -ForegroundColor Green
        }

        # -- Move to Disabled OU --
        Move-ADObject -Identity $adUser.DistinguishedName -TargetPath $DisabledOU
        Write-Host "  Moved to DJGC-Disabled OU" -ForegroundColor Green

        # -- Write the real result back to the ticket --
        $groupSummary = if ($removedGroups.Count -gt 0) { $removedGroups -join ", " } else { "none" }
        $summary = "Offboarding automation completed for $employeeName ($samAccountName). Account disabled. Removed groups: $groupSummary. Moved to DJGC-Disabled OU. Closing left for manual review."

        $patchBody = @{ work_notes = $summary } | ConvertTo-Json
        Invoke-RestMethod -Uri "$instance/api/now/table/sc_req_item/$sysId" -Headers $headers -Method Patch -Body $patchBody -ContentType "application/json" -ErrorAction Stop | Out-Null
        Write-Host "  Ticket $ticketNumber updated with results" -ForegroundColor Magenta

    } catch {
        Write-Host "  ERROR processing $ticketNumber : $_" -ForegroundColor Red
        Write-Host "  Continuing to next ticket..." -ForegroundColor Yellow
    }
}

Write-Host "`nDone. Processed $($openTickets.result.Count) ticket(s)." -ForegroundColor Magenta
