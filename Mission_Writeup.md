# Mission: DJGC Identity & Offboarding Automation

Written per the Mission Framework: Objective, Real Project, Deliverable, Documentation, Evidence of Applied Learning, Success Criteria.

## Objective

Design a realistic mid-size enterprise Active Directory environment from scratch, then build a real, end-to-end automated offboarding workflow integrated with ServiceNow — not a toy script, a system that resolves real ticket data, acts on Active Directory, and reports back what it did.

## Real Project

DJGC Enterprise Lab: a fictional 25-employee company across four divisions (Head Office, Construction, Building Materials, Property Management), built with a deliberate OU structure, security-group model, and license-tier mapping — then wired to a ServiceNow developer instance to trigger and track offboarding.

## Deliverable

- A documented AD identity design (OU structure, naming convention, group model) that another engineer could build from without asking clarifying questions.
- A working PowerShell automation that pulls open offboarding tickets from ServiceNow, resolves the employee via a reference field (not name-matching), checks the effective end date, disables and cleans up the AD account, and writes a real summary back to the ticket.

## Documentation

This repository. README with architecture diagram, design doc with reasoning behind every structural decision, and this writeup.

## Evidence of Applied Learning

- **Reference-field resolution over name-matching** — learned partway through that ServiceNow reference fields store a `sys_id`, not a display string, and that resolving through the real user record is both more correct and safer at scale than parsing text.
- **Query-level filtering over in-loop state checking** — chose to filter closed tickets out at the API query itself rather than pull everything and branch on status in code, because it removes an entire class of possible bugs.
- **Diagnosed a real licensing/architecture gate correctly** — when ServiceNow's native MCP connector failed, traced it to a real prerequisite (Now Assist / AI Native SKU, admin-side MCP Server config) rather than assuming it was a typo or config error, and made the right call to fall back to a proven, always-available path (the Table API) instead of losing time chasing a dead end.
- **Idempotency as a design requirement, not an afterthought** — the script explicitly checks whether an account is already disabled before acting, so it's safe to re-run on a schedule without manual oversight.

## Success Criteria (defined before starting, evaluated after)

| Criterion | Result |
|---|---|
| AD environment reflects a real enterprise structure, not a flat list of users | Met — divisional OUs, admin/service account isolation, disabled-user holding OU |
| Offboarding automation runs against real ServiceNow ticket data, not hardcoded input | Met |
| Automation correctly identifies the right user even with duplicate/similar names | Met, via reference-field resolution |
| Automation never silently fails | Met — every branch (skip, error, success) writes a work note back to the ticket |
| Re-running the automation is safe | Met — already-processed tickets are detected and skipped cleanly |

## What this mission strengthened

Per the Operating System's five strategic assets:

- **Technical Depth** — real AD design decisions, ServiceNow Table API + OAuth, PowerShell error handling and idempotency patterns.
- **Business Understanding** — modeled the license tiers and reporting structure the way an actual mid-size company would need them, not just "25 generic users."
- **Automation & AI** — the core of the mission: turning a manual multi-step process into a script that's safe to run unattended.
- **Communication** — this documentation itself; written so someone unfamiliar with the project could pick it up.

## Next mission this feeds into

Applying the same notification pattern to onboarding, and extending with Microsoft Graph for cloud-side identity actions (session revocation, license removal) that on-prem AD can't reach.

---

# Mission 2: Notification & Failure-Visibility Layer (Power Automate)

## Objective

Close the one real gap Mission 1 left open: if the offboarding script failed partway, or silently skipped a ticket, nothing surfaced it beyond a work note someone had to go looking for. Add human-facing visibility without touching the proven AD/ServiceNow logic.

## Real Project

Extended `Invoke-DJGCOffboarding-Final.ps1` with a Power Automate HTTP-triggered flow. The environment constraint shaped the design: DJGC's AD isn't connected to Entra, so there's no data gateway for Power Automate to reach in — the script instead POSTs its result out to Power Automate over plain HTTPS once it's already finished, no new infrastructure required.

## Deliverable

- A Power Automate flow with an HTTP trigger and a Switch control routing three distinct outcomes (Success / Failed / Skipped) to differently-worded emails.
- A `Send-DJGCNotification` function added to the script, called on real success and on real failure (`catch` block), plus a run-level rollup for skipped tickets (one summary email listing all skips and their reasons, not one email per skip).
- The notification call is isolated in its own try/catch — a Power Automate outage can never break the actual deprovisioning work.

## Evidence of Applied Learning

- **Recognized when a binary Condition wasn't enough** — the flow started with a True/False Condition (Success vs. Failed), which broke the moment a third real outcome (Skipped) needed its own path. Rebuilt as a Switch rather than nesting a second Condition inside the False branch.
- **Traced a real ServiceNow 403 to its actual cause** — swapped OAuth users first (reasonable first guess), it didn't fix it; kept investigating instead of stopping there, and found the real issue was the OAuth application's scope configuration having no scopes selected. User permissions were never the problem.
- **Understood JSON as the shared language across every system touched** — the same `ConvertTo-Json`/`ConvertFrom-Json` pattern already used for ServiceNow carries straight over to Power Automate and (eventually) Graph; one concept, reused, not relearned per integration.
- **Deliberately did not over-notify** — skipped tickets are expected, routine outcomes, not failures, so they're collected and sent as one rollup per run instead of a separate alert per skip.

## Success Criteria

| Criterion | Result |
|---|---|
| Real failure (thrown exception) triggers a distinct alert | Met |
| Real success triggers a distinct confirmation | Met |
| Skipped tickets are visible without being treated as failures | Met — single rollup email per run |
| Notification layer cannot break the core automation if it fails | Met — isolated try/catch around the HTTP call |
| No new on-prem infrastructure required, given AD isn't Entra-connected | Met — script-initiates-outbound design, no gateway needed |

## What this mission strengthened

- **Automation & AI** — orchestration layer on top of an already-working system, not automation in isolation.
- **Technical Depth** — real debugging under pressure (403 error against 4 live tickets), traced to root cause instead of guessed at.
- **Communication** — the notification content itself is written for a human glancing at an inbox, not a log file.
