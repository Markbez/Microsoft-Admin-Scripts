<#
.SYNOPSIS
    Always triggers the device return notification remediation.

.DESCRIPTION
    This detection script deliberately exits with code 1 so that
    Microsoft Intune runs the associated remediation each time
    the remediation is evaluated.

    This behaviour is intentional because the notification is
    designed to be repeatedly displayed until the remediation
    assignment is removed from the device.
#>

Write-Output "Device return notification required."
exit 1