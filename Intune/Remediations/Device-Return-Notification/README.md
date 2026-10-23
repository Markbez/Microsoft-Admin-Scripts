# Device Return Notification

An Intune Remediations package that displays a persistent full-screen notification asking the signed-in user to return a Windows device to IT.

This was originally designed to help recover Windows 10 devices that need to be returned for upgrade or replacement.

## What it does

The remediation displays a prominent notification to the signed-in user containing:

- A configurable window title
- A large action-required banner
- A configurable message
- The computer name
- A countdown before the notification can be acknowledged
- An acknowledgement button that remains disabled until the countdown expires

By default, the user must wait **120 seconds** before the notification can be acknowledged.

During the countdown:

- The window remains on top.
- The acknowledgement button is disabled.
- Closing the window is prevented.
- The remaining time is displayed to the user.

Once the countdown expires, the user can acknowledge and close the notification.

## Files

### Detect.ps1

The detection script deliberately returns:

```powershell
exit 1
```

This is intentional.

It causes Intune to run the remediation every time the Remediations package evaluates the device.

The notification will therefore continue to appear according to the configured Intune Remediations schedule until the device is removed from the assignment or the assignment is otherwise changed.

### Remediate.ps1

Creates and displays the notification using Windows Presentation Foundation (WPF).

No external application or notification module is required by the script.

## Customisation

The main settings are located at the top of `Remediate.ps1`.

### Window title

```powershell
$WindowTitle = "Device Return Required"
```

### Heading

```powershell
$Heading = "ACTION REQUIRED: RETURN THIS DEVICE TO IT"
```

### Message

```powershell
$Message = @"
Windows 10 has reached end of support. This device must be returned to IT
for replacement or upgrade.

Contact your IT team today to arrange the return.
"@
```

Change this text to suit your organisation and the reason the device needs attention.

### Acknowledgement delay

```powershell
$AcknowledgementDelay = 120
```

This controls how many seconds must pass before the user can acknowledge the notification.

For example, to reduce the delay to 60 seconds:

```powershell
$AcknowledgementDelay = 60
```

## Intune Remediations configuration

Create a new Remediations package in Microsoft Intune and use:

- `Detect.ps1` as the detection script.
- `Remediate.ps1` as the remediation script.

The remediation script is intended to display an interactive window to the currently signed-in user, so configure the package to run using the logged-on user's credentials rather than the SYSTEM context.

Assign the Remediations package only to the devices or groups that should receive the notification.

The frequency with which the notification reappears is controlled by the Remediations assignment schedule.

## Optional: Automatic Windows 10 targeting

This remediation can be assigned to any appropriate Intune device group.

It can also be used alongside the following script in this repository:

[Windows 10 Active Device Group Maintenance](../../Group-Maintenance/Windows10-Active-Devices/)

That Azure Automation runbook maintains an Entra ID security group containing Windows 10 devices that:

- Are managed by Microsoft Intune
- Are not marked as personally owned
- Have checked in within a configurable number of days

The resulting group can then be used to target this Device Return Notification remediation.

This creates a useful workflow:

1. Azure Automation identifies active Windows 10 devices.
2. The devices are automatically maintained in an Entra ID security group.
3. The Intune Remediations package is assigned to that group.
4. Targeted users receive the persistent device return notification according to the configured Remediations schedule.
5. Devices that no longer meet the group-maintenance criteria are removed from the targeting group.

The Azure Automation script is **optional**. It is not required to use this remediation.

## Important considerations

This notification is deliberately intrusive.

It is designed for situations where repeated user action is required, such as recovering devices that need to be replaced, upgraded or returned to IT.

Before deployment:

- Test the remediation on a small number of devices.
- Confirm that the message contains suitable instructions for your users.
- Ensure users have a clear way to contact IT or arrange the device return.
- Carefully target the Intune assignment.
- Consider the remediation schedule, as this determines how frequently users receive the notification.

Because the detection script deliberately returns `exit 1`, simply acknowledging the notification does **not** permanently satisfy the detection.

This is intentional.

## Intended use

The example configuration is aimed at recovering Windows 10 devices requiring replacement or upgrade, but the notification can be adapted for other administrative purposes by changing the heading and message.

## Disclaimer

These scripts are provided as-is.

Always review and test scripts in a suitable test environment before deploying them to production.

Consider the impact on end users before deploying persistent or recurring notifications widely.