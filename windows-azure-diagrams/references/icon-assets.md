# Icon Assets

Bundled icons live in `assets/icons/` and are loaded by icon key from `scripts/New-AzureProcessFlow.ps1`.

Included service icons:

- `sre-agent.svg`: Azure SRE Agent icon from `https://sre.azure.com/SreAgent.svg`
- `key-vaults.svg`: Microsoft Azure Architecture Icons, Key Vaults
- `app-registrations.svg`: Microsoft Azure Architecture Icons, App Registrations
- `managed-identities.svg`: Microsoft Azure Architecture Icons, Entra Managed Identities
- `resource-groups.svg`: Microsoft Azure Architecture Icons, Resource Groups
- `virtual-machine.svg`: Microsoft Azure Architecture Icons, Virtual Machine
- `app-services.svg`: Microsoft Azure Architecture Icons, App Services
- `storage-accounts.svg`: Microsoft Azure Architecture Icons, Storage Accounts
- `sql-database.svg`: Microsoft Azure Architecture Icons, SQL Database
- `monitor.svg`: Microsoft Azure Architecture Icons, Monitor

Current scenario icon keys:

- `sre-agent`
- `key-vault`
- `app-registration`
- `managed-identity`
- `resource-group`
- `virtual-machine` or `vm`
- `app-service`
- `storage-account`
- `sql-database`
- `monitor`

When adding services, copy only the required SVG files into `assets/icons/` and update the `$iconFiles` map in `New-AzureProcessFlow.ps1`.
