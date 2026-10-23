# UK Language Configuration - SYSTEM Remediation
# Intune Remediations
# Runs as SYSTEM
#
# Ensures:
# - en-GB Basic
# - en-GB Handwriting
# - en-GB OCR
# - en-GB Speech
# - en-GB Text-to-Speech
# - System locale = en-GB
# - Time zone = GMT Standard Time
#
# Does NOT modify user language list / keyboard settings.
# A restart may be required after changing the system locale.

$RequiredCapabilities = @(
    'Language.Basic~~~en-GB~0.0.1.0',
    'Language.Handwriting~~~en-GB~0.0.1.0',
    'Language.OCR~~~en-GB~0.0.1.0',
    'Language.Speech~~~en-GB~0.0.1.0',
    'Language.TextToSpeech~~~en-GB~0.0.1.0'
)

$Failures = @()
$ChangesMade = $false

# Install missing en-GB language capabilities
foreach ($CapabilityName in $RequiredCapabilities) {

    try {
        $Capability = Get-WindowsCapability -Online -Name $CapabilityName -ErrorAction Stop

        if ($Capability.State -eq 'Installed') {
            Write-Output "Already installed: $CapabilityName"
        }
        else {
            Write-Output "Installing: $CapabilityName"

            Add-WindowsCapability `
                -Online `
                -Name $CapabilityName `
                -ErrorAction Stop | Out-Null

            # Verify installation
            $Capability = Get-WindowsCapability `
                -Online `
                -Name $CapabilityName `
                -ErrorAction Stop

            if ($Capability.State -eq 'Installed') {
                Write-Output "Installed successfully: $CapabilityName"
                $ChangesMade = $true
            }
            else {
                $Failures += "Capability installation verification failed: $CapabilityName [$($Capability.State)]"
            }
        }
    }
    catch {
        $Failures += "Failed to install $CapabilityName : $($_.Exception.Message)"
    }
}

# Configure system locale
try {
    $CurrentLocale = (Get-WinSystemLocale).Name

    if ($CurrentLocale -ne 'en-GB') {

        Write-Output "Changing system locale from $CurrentLocale to en-GB"

        Set-WinSystemLocale -SystemLocale 'en-GB' -ErrorAction Stop

        $ChangesMade = $true
    }
    else {
        Write-Output "System locale already en-GB"
    }
}
catch {
    $Failures += "Failed to configure system locale: $($_.Exception.Message)"
}

# Configure UK time zone
try {
    $CurrentTimeZone = (Get-TimeZone).Id

    if ($CurrentTimeZone -ne 'GMT Standard Time') {

        Write-Output "Changing time zone from $CurrentTimeZone to GMT Standard Time"

        Set-TimeZone -Id 'GMT Standard Time' -ErrorAction Stop

        $ChangesMade = $true
    }
    else {
        Write-Output "Time zone already GMT Standard Time"
    }
}
catch {
    $Failures += "Failed to configure time zone: $($_.Exception.Message)"
}

# Final result
if ($Failures.Count -gt 0) {

    Write-Output "Remediation completed with errors: $($Failures -join ' | ')"
    exit 1
}

if ($ChangesMade) {
    Write-Output "Remediation completed successfully. Changes were made. A restart may be required."
}
else {
    Write-Output "No remediation required. UK system language configuration is already compliant."
}

exit 0