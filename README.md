# Microsoft Admin Scripts

A collection of PowerShell scripts for Microsoft Intune, Entra ID, Microsoft Graph, Azure Automation and general Microsoft administration.

These are scripts I use or have developed to solve real-world IT administration and device management tasks.

## Scripts

### Intune

#### Group Maintenance

**[Windows 10 Active Device Group Maintenance](Intune/Group-Maintenance/Windows10-Active-Devices/)**

Maintains an Entra ID security group containing Windows 10 devices that:

- Are managed by Microsoft Intune
- Have recently checked in
- Are not marked as personally owned

The script is designed to run as an Azure Automation runbook using a system-assigned managed identity and Microsoft Graph.

## Repository structure

Scripts are organised by Microsoft product or administrative area.

```text
Microsoft-Admin-Scripts
├── Intune
│   └── Group-Maintenance
│       └── Windows10-Active-Devices
├── .gitignore
├── LICENSE
└── README.md
```

More categories will be added as additional scripts are published.

## Using these scripts

Each script or project has its own README containing:

- What the script does
- Requirements
- Configuration
- Required permissions
- Usage instructions
- Important considerations and safety information

Always review a script and understand what it does before running it in your environment.

## Contributing

Issues and suggestions are welcome.

If you find a problem or have an improvement, feel free to open an issue.

## Disclaimer

These scripts are provided as-is.

Always review and test scripts in a suitable test environment before using them in production. Configuration, permissions and behaviour may need to be adjusted for your environment.

## License

This repository is licensed under the MIT License. See [LICENSE](LICENSE) for details.
