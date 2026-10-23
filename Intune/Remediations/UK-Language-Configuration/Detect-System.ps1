# UK Language Configuration - SYSTEM Detection
# Intune Remediations
# Runs as SYSTEM
#
# Checks:
# - en-GB Basic
# - en-GB Handwriting
# - en-GB OCR
# - en-GB Speech
# - en-GB Text-to-Speech
# - System locale = en-GB
# - Time zone = GMT Standard Time
#
# Does NOT check user language list / keyboard settings.

$RequiredCapabilities = @(
    'Language.Basic~~~en-GB~0.0.1.0',
    'Language.Handwriting~~~en-GB~0.0.1.0',
    'Language.OCR~~~en-GB~0.0.1.0',
    'Language.Speech~~~en-GB~0.0.1.0',
    'Language.TextToSpeech~~~en-GB~0.0.1.0'
)

$Issues = @()

# Check required en-GB language capabilities
foreach ($CapabilityName in $RequiredCapabilities) {

    try {
        $Capability = Get-WindowsCapability -Online -Name $CapabilityName -ErrorAction Stop

        if (-not $Capability) {
            $Issues += "Capability not found: $CapabilityName"
        }
        elseif ($Capability.State -ne 'Installed') {
            $Issues += "Not installed: $CapabilityName [$($Capability.State)]"
        }
    }
    catch {
        $Issues += "Unable to check: $CapabilityName"
    }
}

# Check system locale
try {
    $SystemLocale = Get-WinSystemLocale

    if ($SystemLocale.Name -ne 'en-GB') {
        $Issues += "System locale is $($SystemLocale.Name), expected en-GB"
    }
}
catch {
    $Issues += "Could not determine system locale"
}

# Check time zone
try {
    $TimeZone = Get-TimeZone

    if ($TimeZone.Id -ne 'GMT Standard Time') {
        $Issues += "Time zone is $($TimeZone.Id), expected GMT Standard Time"
    }
}
catch {
    $Issues += "Could not determine time zone"
}

# Return compliance result
if ($Issues.Count -eq 0) {
    Write-Output "Compliant: UK language components, system locale and time zone are configured."
    exit 0
}
else {
    Write-Output "Non-compliant: $($Issues -join ' | ')"
    exit 1
}