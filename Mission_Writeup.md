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

Extending this same system with Microsoft Graph (cloud-side session/token revocation, license removal) and Power Automate (approval + failure notification layer) — not a new project, a continuation of this one.
