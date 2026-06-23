# Icon Assets

Bundled icons live in `assets/icons/` and are loaded by filename from `scripts/New-AzureProcessFlow.ps1`.

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

When adding services, copy only the required SVG files into `assets/icons/` and update the `$icons` map in `New-AzureProcessFlow.ps1`.
