# DJ Group of Companies — Identity & User Management Design Document

**Phase 1 deliverable — Active Directory Identity Structure**

## Document Purpose

This document defines the complete Active Directory identity structure for DJ Group of Companies (a fictional lab company built to simulate a realistic mid-size enterprise). It's written to the standard that someone unfamiliar with the company could build the AD environment from this document alone, without needing to ask clarifying questions.

## 1. Company Profile

The internal AD domain is a subdomain of the (fictional) public company domain — `corp.djgroupofcompanies.com` — rather than a non-routable name like `.local`. This avoids UPN/verification conflicts later when configuring Hybrid Identity (Azure AD Connect), since Microsoft requires a domain that can be verified against a real, owned public domain.

## 2. Business Divisions

The company operates as one AD domain with four internal divisions. Divisions are treated as administrative/organizational boundaries in AD (OUs), not as separate domains or forests — separate legal entities for tax purposes doesn't require separate IT infrastructure at this scale.

- Head Office
- Construction
- Building Materials
- Property Management

## 3. Organizational Chart

Four reporting levels: **Executive → Division Director → Team Lead → Staff**. All division directors report to the President.

## 4. OU Structure

OUs are designed for two purposes only: applying Group Policy and delegating administrative control. They intentionally do **not** mirror the reporting hierarchy in Section 3 — a manager and their direct report sit in the same OU unless a policy or delegation reason says otherwise.

**OU Tree** (top level = domain root):

```
corp.djgroupofcompanies.com
├── OU=DJGC-HeadOffice
│   ├── OU=Users
│   └── OU=Computers
├── OU=DJGC-Construction
│   ├── OU=Users
│   └── OU=Computers
├── OU=DJGC-BuildingMaterials
│   ├── OU=Users
│   └── OU=Computers
├── OU=DJGC-PropertyMgmt
│   ├── OU=Users
│   └── OU=Computers
├── OU=DJGC-Admins            (IT/admin accounts — separate from standard users)
├── OU=DJGC-ServiceAccounts   (application/service accounts — never a real person)
└── OU=DJGC-Disabled          (offboarded users are disabled and moved here, not deleted)
```

**Design rationale:**

- **Users and Computers are split** within each division OU because GPOs frequently target only one object type — e.g. a password/lockout policy applies to a Users OU, while a BitLocker or software-deployment policy applies to a Computers OU. Splitting them prevents a policy from silently failing to apply because it landed on the wrong object type.
- **DJGC-Admins** isolates administrative accounts (e.g. `jsmith-adm`) from standard user accounts, so security policies for admin accounts (shorter password expiry, stricter lockout) can be applied without affecting everyday user accounts.
- **DJGC-ServiceAccounts** isolates non-human accounts so they can be exempted from interactive-logon and password-expiry policies that apply to people.
- **DJGC-Disabled** provides a holding area for offboarded identities, preserving an audit trail and giving time for license/access cleanup before eventual deletion.

## 5. Security Groups

Security groups control access to resources (file shares, applications, printers, VPN) and are independent of OU placement. A user's OU determines what policy applies to them; a user's group memberships determine what they can access.

## 6. Naming Convention

Applied uniformly across the domain so any object's name is predictable without lookup (e.g. `SG-<Division>-<Purpose>` for groups, `<first-initial><lastname>` for usernames).

## 7. Full Employee Roster

See [`scripts/DJGC_Employee_Roster.csv`](../scripts/DJGC_Employee_Roster.csv) for all 25 users, their assigned OU, username, and division baseline security groups. Every user also receives `SG-AllStaff` and their division's `-Users` group; additional role-based groups (e.g. `SG-Finance-ReadWrite` for the Accountant role) are assigned individually per Section 5.

See [`docs/DJGC_License_Roster.md`](DJGC_License_Roster.md) for license tier assignment logic (E3 / F1 / PowerBI).

## 8. Review Notes / Open Decisions

Documented explicitly so nothing is assumed silently:

- **Single domain, single forest** was chosen over separate domains per legal entity — appropriate at 25 users; would be revisited only if a hard security boundary between divisions is required.
- **Field construction crews** are not modeled as AD user accounts — assumed not to be issued corporate computers/logins at this stage. Revisit if that changes in later phases.
- **Admin (`-adm`) accounts and service accounts** are referenced structurally (OUs exist) but individual accounts are not enumerated in this document — created during Phase 1 build-out.
- This document does not define GPOs themselves (password policy values, software deployment) — OUs are structured to support them, but specific policy settings are a build-phase task, not a design-phase task.
