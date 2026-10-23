# UK Language Configuration

Microsoft Intune Remediations scripts for configuring Windows devices and users with UK English (`en-GB`) language settings.

The configuration is split into separate SYSTEM and USER remediations because Windows system language components and user language preferences require different execution contexts.

## What it configures

### SYSTEM configuration

The SYSTEM remediation ensures the following English (United Kingdom) Windows language capabilities are installed:

- Basic language support
- Handwriting
- OCR
- Speech
- Text-to-Speech

The remediation also configures:

- System locale: `en-GB`
- Time zone: `GMT Standard Time`

The SYSTEM scripts deliberately do not modify the signed-in user's preferred language list or keyboard configuration.

### USER configuration

The USER remediation configures:

- `en-GB` as the only preferred user language
- United Kingdom keyboard layout
- Input method: `0809:00000809`

The remediation removes other preferred language entries from the user's Windows language list.

This includes `en-US` if it is currently configured.

## Files

```text
UK-Language-Configuration
├── Detect-System.ps1
├── Remediate-System.ps1
├── Detect-User.ps1
├── Remediate-User.ps1
└── README.md
```

## Deployment

These scripts should be deployed as two separate Microsoft Intune Remediations packages.

This is important because the two packages require different execution contexts.

## 1. SYSTEM remediation

Create an Intune Remediations package using:

Detection script:

```text
Detect-System.ps1
```

Remediation script:

```text
Remediate-System.ps1
```

Configure:

```text
Run this script using the logged-on credentials: No
```

This causes the scripts to run in the SYSTEM context.

### SYSTEM detection

`Detect-System.ps1` checks that the required English (United Kingdom) Windows language capabilities are installed:

- Basic language support
- Handwriting
- OCR
- Speech
- Text-to-Speech

It also verifies:

- System locale is `en-GB`
- Time zone is `GMT Standard Time`

If all checks pass, the detection script returns exit code `0`.

If any required component or setting is missing or incorrectly configured, the detection script returns exit code `1`, allowing Intune to run the SYSTEM remediation.

### SYSTEM remediation

`Remediate-System.ps1` installs any missing UK language capabilities.

For each language capability, the script:

1. Checks its current installation state.
2. Installs it if required.
3. Checks the installation state again.
4. Reports a failure if the capability could not be installed successfully.

The script also ensures:

```text
System locale: en-GB
Time zone: GMT Standard Time
```

A restart may be required after changing the Windows system locale.

## 2. USER remediation

Create a second Intune Remediations package using:

Detection script:

```text
Detect-User.ps1
```

Remediation script:

```text
Remediate-User.ps1
```

Configure:

```text
Run this script using the logged-on credentials: Yes
```

This allows the scripts to inspect and modify the language configuration belonging to the currently signed-in user.

### USER detection

`Detect-User.ps1` checks that the user's preferred language list contains exactly one language:

```text
en-GB
```

It also verifies that the United Kingdom keyboard input method is configured:

```text
0809:00000809
```

The detection is intentionally strict.

For example, a language list containing both:

```text
en-GB
en-US
```

is considered non-compliant.

Any additional preferred language causes detection to return exit code `1`.

### USER remediation

`Remediate-User.ps1` creates a new Windows user language list containing `en-GB` and applies it to the current user.

After applying the configuration, the script verifies that:

- Exactly one preferred language exists
- The preferred language is `en-GB`
- The UK keyboard input method `0809:00000809` is configured

If verification succeeds, the remediation returns exit code `0`.

If the configuration cannot be applied or verified, it returns exit code `1`.

## Why two Remediations packages?

Windows system configuration and user language preferences are separate.

The SYSTEM remediation handles device-wide settings:

- Windows language capabilities
- System locale
- Time zone

The USER remediation handles settings associated with the signed-in user's Windows profile:

- Preferred language list
- Keyboard and input method

Keeping these separate allows each script to run in the correct context.

It also makes detection, remediation reporting and troubleshooting easier in Microsoft Intune.

## Expected result

After both remediations have successfully applied, the device should have the required English (United Kingdom) Windows language capabilities installed.

The device-wide configuration should be:

```text
System locale: en-GB
Time zone: GMT Standard Time
```

The signed-in user's Windows language configuration should contain only:

```text
LanguageTag: en-GB
InputMethodTips: 0809:00000809
```

There should be no additional preferred user languages configured.

## Important considerations

The USER remediation deliberately replaces the user's existing preferred language list with `en-GB`.

This means additional preferred languages configured by the user will be removed.

Before deploying widely:

- Test both Remediations packages on suitable test devices.
- Confirm that removing additional user languages is appropriate for your environment.
- Consider users who legitimately require multiple languages or alternative keyboard layouts.
- Review Intune detection and remediation results before broad deployment.
- Be aware that a restart may be required after changing the system locale.

The SYSTEM remediation installs Windows language capabilities. Devices therefore need to be able to obtain the required Windows capability packages.

## Troubleshooting

If the SYSTEM remediation succeeds but the user's language settings do not change, verify that the USER remediation is configured with:

```text
Run this script using the logged-on credentials: Yes
```

The user language scripts must run in the signed-in user's context.

You can inspect the resulting user language configuration with:

```powershell
Get-WinUserLanguageList | Format-List *
```

A compliant result should contain `en-GB` as the only language and include the UK input method:

```text
0809:00000809
```

## Disclaimer

These scripts are provided as-is.

Always review and test scripts in a suitable test environment before deploying them to production.

Language requirements vary between organisations and users. Modify the detection and remediation logic if your environment requires additional languages or keyboard layouts.