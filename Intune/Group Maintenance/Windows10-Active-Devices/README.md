# Windows 10 Active Device Group Maintenance

PowerShell runbook for maintaining an Entra ID security group containing Windows 10 devices that are actively checking in to Microsoft Intune.

The script is designed to run in Azure Automation using a system-assigned managed identity and Microsoft Graph PowerShell.

## What the script does

The script:

- Queries Intune managed devices.
- Selects Windows devices with an OS version starting with `10.0.19`.
- Excludes devices marked as personally owned.
- Only includes devices that have checked in within the configured number of days.
- Resolves the Intune devices to their corresponding Entra ID device objects.
- Adds qualifying devices to the specified Entra ID security group.
- Removes devices from the group when they no longer meet the criteria.

By default, a device is considered active if it has checked in within the last **30 days**.

## Requirements

The script is intended to run as an Azure Automation PowerShell runbook.

You will need:

- An Azure Automation Account.
- A system-assigned managed identity enabled on the Automation Account.
- Microsoft Graph PowerShell modules available to the Automation Account.
- An Entra ID security group to maintain.
- Appropriate Microsoft Graph application permissions assigned to the managed identity.

## Microsoft Graph permissions

The Azure Automation managed identity requires permissions that allow the script to:

- Read Intune managed devices.
- Read Entra ID device objects.
- Read the target group's membership.
- Add and remove group members.

Review the permissions assigned to the managed identity and use the least privilege appropriate for your environment.

## Parameters

### GroupId

`GroupId` is required.

This is the **Object ID** of the Entra ID security group that the script will maintain.

For example:

```text
00000000-0000-0000-0000-000000000000
```

In the Entra admin centre, locate the security group you want the script to maintain and copy its **Object ID**.

Pass this value to the `GroupId` parameter when configuring or running the Azure Automation runbook.

Example:

```powershell
.\Windows10-Active-Devices.ps1 `
    -GroupId "00000000-0000-0000-0000-000000000000"
```

### DaysActive

`DaysActive` controls how recently a device must have checked in to Intune to remain in the group.

This parameter is optional.

The default is:

```text
30
```

For example, to consider devices active for 60 days:

```powershell
.\Windows10-Active-Devices.ps1 `
    -GroupId "00000000-0000-0000-0000-000000000000" `
    -DaysActive 60
```

## Azure Automation

Import `Windows10-Active-Devices.ps1` as a PowerShell runbook in your Azure Automation Account.

The script authenticates to Microsoft Graph using:

```powershell
Connect-MgGraph -Identity
```

This means no username, password, application secret, or certificate needs to be stored in the script.

Configure the runbook with your target group Object ID using the `GroupId` parameter.

`DaysActive` can be left at its default value of 30 or changed to suit your environment.

## Windows 10 detection

The script identifies Windows 10 using:

```powershell
$_.OperatingSystem -eq "Windows" -and
$_.OSVersion -like "10.0.19*"
```

This distinguishes Windows 10 from Windows 11 based on the reported operating system version.

## Ownership filtering

Devices with an Intune ownership type of `personal` are excluded:

```powershell
$_.ManagedDeviceOwnerType -ne "personal"
```

This means the target group is intended to contain only devices that are not marked as personally owned in Intune.

## Safety check

The script includes a safety check before modifying group membership.

If **zero qualifying Intune devices** are returned, the runbook stops with an error:

```text
No qualifying non-personal Windows 10 devices were found. Group membership was not changed.
```

This is intended to prevent a failed or unexpected query from causing every device to be removed from the target group.

The script also avoids removing a group member when the corresponding Entra ID device object cannot be resolved.

## Important

The target group should be a **dedicated security group managed by this script**.

Do not use a group containing manually maintained members unless you are happy for the script to remove devices that do not meet its criteria.

Review the proposed additions and removals shown in the Azure Automation job output when initially testing the runbook.

## Disclaimer

Test the script thoroughly in your own environment before using it in production.

Microsoft Graph permissions and behaviour should be reviewed to ensure they are appropriate for your environment.