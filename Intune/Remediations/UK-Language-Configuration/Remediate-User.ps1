# UK Language Configuration - User Remediation
# Intune Remediations
# Run using logged-on credentials: YES
#
# Sets:
# - en-GB as the ONLY preferred language
# - UK keyboard
#
# Removes user-level en-US and other language entries.

try {
    Write-Output "Creating en-GB user language configuration"

    $LanguageList = New-WinUserLanguageList -Language 'en-GB'

    if (-not $LanguageList) {
        throw "New-WinUserLanguageList returned no language configuration"
    }

    Write-Output "Applying en-GB as the only user language"

    Set-WinUserLanguageList `
        -LanguageList $LanguageList `
        -Force `
        -ErrorAction Stop

    # Verify the resulting configuration
    $Result = @(Get-WinUserLanguageList)

    if ($Result.Count -ne 1) {
        throw "Language list contains $($Result.Count) entries after remediation"
    }

    if ($Result[0].LanguageTag -ne 'en-GB') {
        throw "Language after remediation is $($Result[0].LanguageTag), expected en-GB"
    }

    if ($Result[0].InputMethodTips -notcontains '0809:00000809') {
        throw "UK keyboard 0809:00000809 was not configured"
    }

    Write-Output "Remediation successful: User language is en-GB only with UK keyboard."
    exit 0
}
catch {
    Write-Output "Remediation failed: $($_.Exception.Message)"
    exit 1
}