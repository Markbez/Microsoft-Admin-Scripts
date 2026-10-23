<#
.SYNOPSIS
    Maintains an Entra ID security group containing recently active Windows 10 devices managed by Microsoft Intune.

.DESCRIPTION
    Queries Microsoft Intune for Windows 10 devices that have checked in within
    a specified number of days and are not marked as personally owned.

    Qualifying Intune devices are resolved to their corresponding Entra ID device
    objects and synchronised with the specified Entra ID security group.

    The script is designed to run in Azure Automation using a system-assigned
    managed identity.

    Windows 10 is identified by an OS version beginning with 10.0.19.

.PARAMETER GroupId
    The Object ID of the Entra ID security group to maintain.

.PARAMETER DaysActive
    The number of days since the last Intune check-in for a device to be considered
    active. Defaults to 30 days.

.EXAMPLE
    .\Windows10-Active-Devices.ps1 -GroupId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    .\Windows10-Active-Devices.ps1 `
        -GroupId "00000000-0000-0000-0000-000000000000" `
        -DaysActive 60

.NOTES
    Designed for use with Microsoft Graph PowerShell in Azure Automation.

    Review and test this script before using it in a production environment.
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupId,

    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$DaysActive = 30
)

$CutoffDate = (Get-Date).AddDays(-$DaysActive)

Write-Output "Windows 10 Active Device Group Maintenance"
Write-Output "------------------------------------------"
Write-Output "Active period: $DaysActive days"
Write-Output "Cutoff date:   $CutoffDate"
Write-Output "Group ID:      $GroupId"
Write-Output ""

# Connect to Microsoft Graph using the Azure Automation
# account's system-assigned managed identity.
Connect-MgGraph -Identity -NoWelcome

$GraphContext = Get-MgContext

Write-Output "Connected to Microsoft Graph."
Write-Output "Authentication type: $($GraphContext.AuthType)"
Write-Output ""

Write-Output "Querying Intune managed devices..."

$TargetIntuneDevices = @(
    Get-MgDeviceManagementManagedDevice -All |
        Where-Object {
            $_.OperatingSystem -eq "Windows" -and
            $_.OSVersion -like "10.0.19*" -and
            $_.ManagedDeviceOwnerType -ne "personal" -and
            $_.LastSyncDateTime -ge $CutoffDate
        }
)

Write-Output "Qualifying Windows 10 devices: $($TargetIntuneDevices.Count)"
Write-Output ""

# Safety check to prevent an empty query result from removing
# all devices from the target group.
if ($TargetIntuneDevices.Count -eq 0) {
    throw "No qualifying non-personal Windows 10 devices were found. Group membership was not changed."
}

$TargetIntuneDevices |
    Select-Object DeviceName, ManagedDeviceOwnerType, OSVersion, LastSyncDateTime, AzureAdDeviceId |
    Sort-Object LastSyncDateTime -Descending |
    Format-Table -AutoSize

# Resolve Intune managed devices to their corresponding Entra ID objects.
Write-Output ""
Write-Output "Resolving Intune devices to Entra ID device objects..."

$TargetDevices = @(
    foreach ($Device in $TargetIntuneDevices) {
        try {
            $EntraDevice = Get-MgDeviceByDeviceId `
                -DeviceId $Device.AzureAdDeviceId `
                -ErrorAction Stop

            [PSCustomObject]@{
                DeviceName       = $Device.DeviceName
                AzureAdDeviceId  = $Device.AzureAdDeviceId
                EntraObjectId    = $EntraDevice.Id
                LastSyncDateTime = $Device.LastSyncDateTime
            }
        }
        catch {
            Write-Warning "Could not resolve $($Device.DeviceName) to an Entra ID device object."
        }
    }
)

Write-Output "Successfully resolved: $($TargetDevices.Count)"
Write-Output ""

# Get current group membership.
Write-Output "Reading current group membership..."

$CurrentMembers = @(
    Get-MgGroupMember -GroupId $GroupId -All
)

Write-Output "Current group members: $($CurrentMembers.Count)"
Write-Output ""

# Determine membership changes.
$TargetObjectIds  = @($TargetDevices.EntraObjectId)
$CurrentObjectIds = @($CurrentMembers.Id)

$DevicesToAdd = @(
    $TargetDevices |
        Where-Object {
            $_.EntraObjectId -notin $CurrentObjectIds
        }
)

$DevicesToRemove = @(
    foreach ($Member in $CurrentMembers) {
        if ($Member.Id -notin $TargetObjectIds) {
            try {
                $EntraDevice = Get-MgDevice `
                    -Filter "id eq '$($Member.Id)'" `
                    -Top 1 `
                    -ErrorAction Stop

                if (-not $EntraDevice) {
                    Write-Warning "Could not find device with Entra object ID $($Member.Id); it will not be removed."
                    continue
                }

                [PSCustomObject]@{
                    DeviceName             = $EntraDevice.DisplayName
                    OperatingSystem        = $EntraDevice.OperatingSystem
                    OperatingSystemVersion = $EntraDevice.OperatingSystemVersion
                    EntraObjectId          = $Member.Id
                }
            }
            catch {
                Write-Warning "Could not resolve group member $($Member.Id); it will not be removed."
            }
        }
    }
)

Write-Output "------------------------------"
Write-Output "Proposed changes"
Write-Output "------------------------------"

Write-Output ""
Write-Output "Devices to ADD: $($DevicesToAdd.Count)"

$DevicesToAdd |
    Select-Object DeviceName, LastSyncDateTime |
    Format-Table -AutoSize

Write-Output "Devices to REMOVE: $($DevicesToRemove.Count)"

$DevicesToRemove |
    Select-Object DeviceName, OperatingSystem, OperatingSystemVersion, EntraObjectId |
    Format-Table -AutoSize

# Add missing devices.
Write-Output ""
Write-Output "Applying additions..."

foreach ($Device in $DevicesToAdd) {
    try {
        New-MgGroupMemberByRef `
            -GroupId $GroupId `
            -OdataId "https://graph.microsoft.com/v1.0/directoryObjects/$($Device.EntraObjectId)" `
            -ErrorAction Stop

        Write-Output "ADDED: $($Device.DeviceName)"
    }
    catch {
        Write-Warning "FAILED TO ADD: $($Device.DeviceName) - $($_.Exception.Message)"
    }
}

# Remove devices that no longer qualify.
Write-Output ""
Write-Output "Applying removals..."

foreach ($Device in $DevicesToRemove) {
    try {
        Remove-MgGroupMemberByRef `
            -GroupId $GroupId `
            -DirectoryObjectId $Device.EntraObjectId `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Output "REMOVED: $($Device.DeviceName)"
    }
    catch {
        Write-Warning "FAILED TO REMOVE: $($Device.DeviceName) - $($_.Exception.Message)"
    }
}