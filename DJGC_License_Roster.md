# DJGC License Assignment Roster

Reference list of which license group(s) each employee belongs to.
Source of truth for AD group membership - update this if licensing changes.

| Name            | Username  | Division           | Title                        | Licenses      |
|-----------------|-----------|--------------------|-------------------------------|---------------|
| David Sharma    | dsharma   | Head Office        | President & Principal Broker  | E3, PowerBI   |
| Maria Gonzales  | mgonzales | Head Office        | Brokerage Sales Manager       | E3            |
| James Wong      | jwong     | Head Office        | Senior Real Estate Agent      | E3            |
| Priya Patel     | ppatel    | Head Office        | Corporate Services Lead       | E3, PowerBI   |
| John Smith      | jsmith    | Head Office        | Real Estate Agent             | E3            |
| Jane Smith      | jsmith2   | Head Office        | Real Estate Agent             | E3            |
| Robert Chen     | rchen     | Head Office        | Accountant                    | E3, PowerBI   |
| Amanda Klein    | aklein    | Head Office        | HR Generalist                 | E3            |
| Kevin Osei      | kosei     | Head Office        | IT Support Specialist         | E3            |
| Laura Bennett   | lbennett  | Head Office        | Marketing Coordinator         | E3            |
| Michael Torres  | mtorres   | Construction       | Construction Director         | E3, PowerBI   |
| Steven Park     | spark     | Construction       | Project Manager               | E3            |
| Carlos Mendez   | cmendez   | Construction       | Site Supervisor               | F1            |
| Ahmed Hussain   | ahussain  | Construction       | Site Coordinator              | F1            |
| Brian Fischer   | bfischer  | Construction       | Site Coordinator              | F1            |
| Nicole Adams    | nadams    | Construction       | Estimator                     | E3, PowerBI   |
| Sandra Lee      | slee      | Building Materials | Building Materials Manager    | E3            |
| Tyler Brooks    | tbrooks   | Building Materials | Warehouse Supervisor          | F1            |
| Olivia Martin   | omartin   | Building Materials | Sales Rep                     | E3            |
| Derek Nguyen    | dnguyen   | Building Materials | Warehouse Staff               | F1            |
| Frank Ibrahim   | fibrahim  | Building Materials | Warehouse Staff               | F1            |
| Rachel Kim      | rkim      | Property Mgmt      | Property Manager              | E3            |
| Victor Alvarez  | valvarez  | Property Mgmt      | Leasing & Maintenance Coord.  | E3            |
| George Novak    | gnovak    | Property Mgmt      | Maintenance Technician        | F1            |
| Hannah Cole     | hcole     | Property Mgmt      | Tenant Services Coordinator   | E3            |

## Assignment Logic

- **E3** - full Office/Exchange license: office and knowledge workers (agents, managers, coordinators, admin roles)
- **F1** - frontline/limited license: hands-on and site-based roles (warehouse, site coordination, maintenance)
- **PowerBI** - add-on license: finance, reporting, and leadership analytics roles

## Notes

- 3 users hold PowerBI as an add-on alongside E3: David Sharma, Priya Patel, Robert Chen, Michael Torres, Nicole Adams (5 total)
- No user holds both E3 and F1 - these are mutually exclusive tiers
- This mirrors the OU-based licensing your production environment uses, implemented here via
  security groups (SG-License-E3, SG-License-F1, SG-License-PowerBI) since the lab doesn't have
  OU-based licensing configured
