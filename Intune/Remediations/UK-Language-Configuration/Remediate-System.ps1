# UK Language Configuration - SYSTEM Remediation
# Intune Remediations
# Run as SYSTEM in 64-bit Windows PowerShell
#
# Design:
# - Applies system locale and time zone first.
# - Installs no more than ONE missing language capability per run.
# - Subsequent scheduled runs install the next missing capability.
# - This reduces the risk of Intune timing out while installing
#   several Features on Demand sequentially.
#
# Does NOT modify user language or keyboard settings.

$RequiredCapabilities = @(
    'Language.Basic~~~en-GB~0.0.1.0',
    'Language.Handwriting~~~en-GB~0.0.1.0',
    'Language.OCR~~~en-GB~0.0.1.0',
    'Language.Speech~~~en-GB~0.0.1.0',
    'Language.TextToSpeech~~~en-GB~0.0.1.0'
)

$Failures = @()
$ChangesMade = @()

# Configure the UK time zone first
try {
    $CurrentTimeZone = (Get-TimeZone -ErrorAction Stop).Id

    if ($CurrentTimeZone -ne 'GMT Standard Time') {
        Write-Output "Changing time zone from '$CurrentTimeZone' to 'GMT Standard Time'."

        Set-TimeZone `
            -Id 'GMT Standard Time' `
            -ErrorAction Stop

        $ChangesMade += 'Time zone changed to GMT Standard Time'
    }
    else {
        Write-Output "Time zone is already GMT Standard Time."
    }
}
catch {
    $Failures += "Failed to configure time zone: $($_.Exception.Message)"
}

# Configure the UK system locale
try {
    $CurrentSystemLocale = (Get-WinSystemLocale -ErrorAction Stop).Name

    if ($CurrentSystemLocale -ne 'en-GB') {
        Write-Output "Changing system locale from '$CurrentSystemLocale' to 'en-GB'."

        Set-WinSystemLocale `
            -SystemLocale 'en-GB' `
            -ErrorAction Stop

        $ChangesMade += 'System locale set to en-GB; restart required'
    }
    else {
        Write-Output "System locale is already en-GB."
    }
}
catch {
    $Failures += "Failed to configure system locale: $($_.Exception.Message)"
}

# Find all missing en-GB capabilities
$MissingCapabilities = @()

foreach ($CapabilityName in $RequiredCapabilities) {
    try {
        $Capability = Get-WindowsCapability `
            -Online `
            -Name $CapabilityName `
            -ErrorAction Stop

        if ($Capability.State -eq 'Installed') {
            Write-Output "Already installed: $CapabilityName"
        }
        else {
            Write-Output "Missing: $CapabilityName [$($Capability.State)]"

            $MissingCapabilities += $CapabilityName
        }
    }
    catch {
        $Failures += "Failed to check $CapabilityName : $($_.Exception.Message)"
    }
}

# Install only the first missing capability
if ($MissingCapabilities.Count -gt 0) {
    $CapabilityToInstall = $MissingCapabilities[0]

    Write-Output "Installing one capability during this run: $CapabilityToInstall"
    Write-Output "Remaining missing capabilities will be handled by later remediation runs."

    try {
        Add-WindowsCapability `
            -Online `
            -Name $CapabilityToInstall `
            -ErrorAction Stop |
            Out-Null

        # Verify the installation
        $Verification = Get-WindowsCapability `
            -Online `
            -Name $CapabilityToInstall `
            -ErrorAction Stop

        if ($Verification.State -eq 'Installed') {
            Write-Output "Installed successfully: $CapabilityToInstall"

            $ChangesMade += "Installed $CapabilityToInstall"
        }
        else {
            $Failures += "Installation did not complete for $CapabilityToInstall. Current state: $($Verification.State)"
        }
    }
    catch {
        $Failures += "Failed to install $CapabilityToInstall : $($_.Exception.Message)"
    }
}
else {
    Write-Output "All required en-GB language capabilities are installed."
}

# Final result
if ($Failures.Count -gt 0) {
    Write-Output "Remediation completed with errors: $($Failures -join ' | ')"
    exit 1
}

if ($ChangesMade.Count -gt 0) {
    Write-Output "Remediation completed successfully: $($ChangesMade -join ' | ')"
}
else {
    Write-Output "No remediation was required. UK system language configuration is already compliant."
}

if ($MissingCapabilities.Count -gt 1) {
    $RemainingCount = $MissingCapabilities.Count - 1

    Write-Output "$RemainingCount additional language capability/capabilities remain for subsequent runs."
}

exit 0