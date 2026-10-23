# UK Language Configuration - User Detection
# Intune Remediations
# Run using logged-on credentials: YES
#
# Requires:
# - en-GB to be the ONLY preferred language
# - UK keyboard layout to be configured
# - No en-US / US keyboard entry

$Issues = @()

try {
    $LanguageList = @(Get-WinUserLanguageList)

    if ($LanguageList.Count -ne 1) {
        $Issues += "User has $($LanguageList.Count) languages configured; expected 1"
    }

    $UKLanguage = $LanguageList | Where-Object {
        $_.LanguageTag -eq 'en-GB'
    }

    if (-not $UKLanguage) {
        $Issues += "en-GB is not configured"
    }
    else {
        if ($UKLanguage.InputMethodTips -notcontains '0809:00000809') {
            $Issues += "UK keyboard 0809:00000809 is not configured"
        }
    }

    $OtherLanguages = @(
        $LanguageList | Where-Object {
            $_.LanguageTag -ne 'en-GB'
        }
    )

    if ($OtherLanguages.Count -gt 0) {
        $Tags = $OtherLanguages.LanguageTag -join ', '
        $Issues += "Additional languages configured: $Tags"
    }
}
catch {
    $Issues += "Unable to read user language configuration: $($_.Exception.Message)"
}

if ($Issues.Count -eq 0) {
    Write-Output "Compliant: User language is en-GB only with UK keyboard."
    exit 0
}
else {
    Write-Output "Non-compliant: $($Issues -join ' | ')"
    exit 1
}