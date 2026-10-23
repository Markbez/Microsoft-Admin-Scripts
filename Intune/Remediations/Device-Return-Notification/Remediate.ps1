<#
.SYNOPSIS
    Displays a persistent device return notification to the signed-in user.

.DESCRIPTION
    Displays a prominent Windows notification requesting that the device
    is returned to IT.

    The notification remains on top and cannot be dismissed until the
    configured acknowledgement delay has expired.

    Designed for use as a Microsoft Intune Remediations remediation script
    running in the logged-on user's context.

.NOTES
    Customise the configuration values below for your organisation.
#>

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$WindowTitle = "Device Return Required"

$Heading = "ACTION REQUIRED: RETURN THIS DEVICE TO IT"

$Message = @"
Windows 10 has reached end of support. This device must be returned to IT
for replacement or upgrade.

Contact your IT team today to arrange the return.
"@

# Number of seconds before the user can acknowledge the notification.
$AcknowledgementDelay = 120

# ---------------------------------------------------------------------------
# Notification UI
# ---------------------------------------------------------------------------

Add-Type -AssemblyName PresentationFramework

$window = New-Object System.Windows.Window
$window.Title = $WindowTitle
$window.Width = 1200
$window.Height = 720
$window.WindowStartupLocation = "CenterScreen"
$window.ResizeMode = "NoResize"
$window.WindowStyle = "None"
$window.Topmost = $true
$window.Background = [System.Windows.Media.Brushes]::WhiteSmoke

$layout = New-Object System.Windows.Controls.StackPanel
$layout.Margin = [System.Windows.Thickness]::new(48)
$layout.VerticalAlignment = "Center"

# Banner
$banner = New-Object System.Windows.Controls.Border
$banner.Background = [System.Windows.Media.Brushes]::DarkRed
$banner.Padding = [System.Windows.Thickness]::new(24, 18, 24, 18)
$banner.Margin = [System.Windows.Thickness]::new(0, 0, 0, 32)

$headingText = New-Object System.Windows.Controls.TextBlock
$headingText.Text = $Heading
$headingText.FontSize = 38
$headingText.FontWeight = "Bold"
$headingText.Foreground = [System.Windows.Media.Brushes]::White
$headingText.TextWrapping = "Wrap"

$banner.Child = $headingText
$layout.Children.Add($banner) | Out-Null

# Main message
$messageText = New-Object System.Windows.Controls.TextBlock
$messageText.Text = $Message
$messageText.FontSize = 32
$messageText.FontWeight = "SemiBold"
$messageText.Foreground = [System.Windows.Media.Brushes]::Black
$messageText.TextWrapping = "Wrap"
$messageText.Margin = [System.Windows.Thickness]::new(0, 0, 0, 36)

$layout.Children.Add($messageText) | Out-Null

# Device name
$device = New-Object System.Windows.Controls.TextBlock
$device.Text = "Device: $env:COMPUTERNAME"
$device.FontSize = 24
$device.FontWeight = "Bold"
$device.Foreground = [System.Windows.Media.Brushes]::DimGray
$device.Margin = [System.Windows.Thickness]::new(0, 0, 0, 36)

$layout.Children.Add($device) | Out-Null

# Countdown status
$status = New-Object System.Windows.Controls.TextBlock
$status.Text = "Acknowledgement will be available in $AcknowledgementDelay seconds."
$status.FontSize = 20
$status.FontWeight = "SemiBold"
$status.Margin = [System.Windows.Thickness]::new(0, 0, 0, 16)

$layout.Children.Add($status) | Out-Null

# Acknowledge button
$button = New-Object System.Windows.Controls.Button
$button.Content = "Acknowledge ($AcknowledgementDelay)"
$button.Width = 200
$button.Height = 54
$button.FontSize = 20
$button.HorizontalAlignment = "Right"
$button.IsEnabled = $false
$button.IsDefault = $false

$button.Add_Click({
    $window.Close()
})

$layout.Children.Add($button) | Out-Null

# ---------------------------------------------------------------------------
# Countdown timer
# ---------------------------------------------------------------------------

$timerState = [pscustomobject]@{
    SecondsRemaining = $AcknowledgementDelay
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(1)

$tickHandler = {

    $timerState.SecondsRemaining--

    if ($timerState.SecondsRemaining -le 0) {

        $timer.Stop()

        $window.Topmost = $false

        $button.Content = "Acknowledge"
        $button.IsEnabled = $true
        $button.IsDefault = $true

        $status.Text = "You can now acknowledge this notice."

        return
    }

    $button.Content = "Acknowledge ($($timerState.SecondsRemaining))"

    $status.Text =
        "Acknowledgement will be available in $($timerState.SecondsRemaining) seconds."

}.GetNewClosure()

$timer.Add_Tick($tickHandler)

# Stop the timer when the window closes.
$closedHandler = {
    $timer.Stop()
}.GetNewClosure()

$window.Add_Closed($closedHandler)

# Prevent the window from being closed before the countdown completes.
$closingHandler = {

    if ($timerState.SecondsRemaining -gt 0) {
        $_.Cancel = $true
    }

}.GetNewClosure()

$window.Add_Closing($closingHandler)

# ---------------------------------------------------------------------------
# Display notification
# ---------------------------------------------------------------------------

$window.Content = $layout

$timer.Start()

$window.ShowDialog() | Out-Null