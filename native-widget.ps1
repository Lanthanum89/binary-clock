Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing") -TypeDefinition @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class WidgetNativeMethods
{
    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
}

public class WidgetForm : Form
{
    private const int WM_NCHITTEST = 0x84;
    private const int HTCLIENT = 1;
    private const int HTLEFT = 10;
    private const int HTRIGHT = 11;
    private const int HTTOP = 12;
    private const int HTTOPLEFT = 13;
    private const int HTTOPRIGHT = 14;
    private const int HTBOTTOM = 15;
    private const int HTBOTTOMLEFT = 16;
    private const int HTBOTTOMRIGHT = 17;

    public int GripSize { get; set; }

    public WidgetForm()
    {
        GripSize = 10;
        DoubleBuffered = true;
        ResizeRedraw = true;
    }

    protected override void WndProc(ref Message m)
    {
        base.WndProc(ref m);

        if (m.Msg != WM_NCHITTEST || (int)m.Result != HTCLIENT)
        {
            return;
        }

        Point cursor = PointToClient(new Point((int)m.LParam));
        bool left = cursor.X <= GripSize;
        bool right = cursor.X >= ClientSize.Width - GripSize;
        bool top = cursor.Y <= GripSize;
        bool bottom = cursor.Y >= ClientSize.Height - GripSize;

        if (left && top) m.Result = (IntPtr)HTTOPLEFT;
        else if (right && top) m.Result = (IntPtr)HTTOPRIGHT;
        else if (left && bottom) m.Result = (IntPtr)HTBOTTOMLEFT;
        else if (right && bottom) m.Result = (IntPtr)HTBOTTOMRIGHT;
        else if (left) m.Result = (IntPtr)HTLEFT;
        else if (right) m.Result = (IntPtr)HTRIGHT;
        else if (top) m.Result = (IntPtr)HTTOP;
        else if (bottom) m.Result = (IntPtr)HTBOTTOM;
    }
}

public class BufferedPanel : Panel
{
    private const int WM_NCHITTEST = 0x84;
    private const int HTCLIENT = 1;
    private const int HTTRANSPARENT = -1;

    public BufferedPanel()
    {
        DoubleBuffered = true;
        ResizeRedraw = true;
    }

    protected override void WndProc(ref Message m)
    {
        base.WndProc(ref m);

        if (m.Msg == WM_NCHITTEST && (int)m.Result == HTCLIENT)
        {
            WidgetForm form = TopLevelControl as WidgetForm;
            if (form != null)
            {
                Point cursor = form.PointToClient(new Point((int)m.LParam));
                int g = form.GripSize;
                bool left   = cursor.X <= g;
                bool right  = cursor.X >= form.ClientSize.Width - g;
                bool top    = cursor.Y <= g;
                bool bottom = cursor.Y >= form.ClientSize.Height - g;

                if (left || right || top || bottom)
                {
                    // Let the parent form perform non-client edge handling.
                    m.Result = (IntPtr)HTTRANSPARENT;
                }
            }
        }
    }
}
"@

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

$statePath = Join-Path $PSScriptRoot "widget-state.json"
$screenMargin = 24
$minWidth = 520
$minHeight = 620
$defaultWidth = 980
$defaultHeight = 760
$clockValues = @(8, 4, 2, 1)

$theme = @{
    BackgroundTop = [System.Drawing.ColorTranslator]::FromHtml("#FFF5FC")
    BackgroundBottom = [System.Drawing.ColorTranslator]::FromHtml("#F5ECFF")
    Border = [System.Drawing.Color]::FromArgb(190, 219, 169, 229)
    TextMain = [System.Drawing.ColorTranslator]::FromHtml("#4A2954")
    TextSoft = [System.Drawing.ColorTranslator]::FromHtml("#7F5B87")
    AccentDeep = [System.Drawing.ColorTranslator]::FromHtml("#B05AD4")
    TileIdle = [System.Drawing.Color]::FromArgb(208, 255, 255, 255)
    TileActiveTop = [System.Drawing.ColorTranslator]::FromHtml("#FFA8D9")
    TileActiveBottom = [System.Drawing.ColorTranslator]::FromHtml("#E39CFF")
    Sparkle = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
}

$script:state = @{
    TimeFormat = "24"
    TopMost = $false
    Bounds = $null
}

function Import-State {
    if (-not (Test-Path $statePath)) {
        return
    }

    try {
        $saved = Get-Content -Path $statePath -Raw | ConvertFrom-Json
        if ($saved.TimeFormat -in @("12", "24")) {
            $script:state.TimeFormat = $saved.TimeFormat
        }
        if ($saved.TopMost -is [bool]) {
            $script:state.TopMost = $saved.TopMost
        }
        if ($saved.Bounds) {
            $script:state.Bounds = $saved.Bounds
        }
    } catch {
    }
}

function Save-State {
    $payload = [pscustomobject]@{
        TimeFormat = $script:state.TimeFormat
        TopMost = $script:state.TopMost
        Bounds = $script:state.Bounds
    }
    $payload | ConvertTo-Json | Set-Content -Path $statePath -Encoding UTF8
}

function New-RoundedPath {
    param(
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Set-RoundedRegion {
    param(
        [System.Windows.Forms.Form]$Form,
        [int]$Radius
    )

    if ($Form.Width -le 0 -or $Form.Height -le 0) {
        return
    }

    $rect = New-Object System.Drawing.RectangleF 0, 0, $Form.Width, $Form.Height
    $path = New-RoundedPath -Rect $rect -Radius $Radius
    $region = New-Object System.Drawing.Region($path)
    if ($Form.Region) {
        $Form.Region.Dispose()
    }
    $Form.Region = $region
    $path.Dispose()
}

function Get-WorkingArea {
    [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
}

function Set-FitToScreen {
    param([System.Windows.Forms.Form]$Form)

    $workingArea = Get-WorkingArea
    $width = [Math]::Min($defaultWidth, $workingArea.Width - ($screenMargin * 2))
    $height = [Math]::Min($defaultHeight, $workingArea.Height - ($screenMargin * 2))
    $left = $workingArea.Left + [Math]::Max($screenMargin, [int](($workingArea.Width - $width) / 2))
    $top = $workingArea.Top + [Math]::Max($screenMargin, [int](($workingArea.Height - $height) / 2))
    $Form.Bounds = [System.Drawing.Rectangle]::new($left, $top, $width, $height)
}

function Set-WithinScreenBounds {
    param([System.Windows.Forms.Form]$Form)

    $workingArea = Get-WorkingArea
    $width = [Math]::Min($Form.Width, $workingArea.Width - ($screenMargin * 2))
    $height = [Math]::Min($Form.Height, $workingArea.Height - ($screenMargin * 2))
    $left = [Math]::Min([Math]::Max($Form.Left, $workingArea.Left + $screenMargin), $workingArea.Right - $width - $screenMargin)
    $top = [Math]::Min([Math]::Max($Form.Top, $workingArea.Top + $screenMargin), $workingArea.Bottom - $height - $screenMargin)
    $Form.Bounds = [System.Drawing.Rectangle]::new($left, $top, $width, $height)
}

function Get-HourState {
    $now = Get-Date
    if ($script:state.TimeFormat -eq "24") {
        return @{
            Hour = $now.Hour
            Period = "24H"
            Minute = $now.Minute
            Second = $now.Second
            BinaryHour = $now.Hour
        }
    }

    $period = if ($now.Hour -ge 12) { "PM" } else { "AM" }
    $displayHour = $now.Hour % 12
    if ($displayHour -eq 0) {
        $displayHour = 12
    }

    return @{
        Hour = $displayHour
        Period = $period
        Minute = $now.Minute
        Second = $now.Second
        BinaryHour = $displayHour
    }
}

function Get-PreferredFontFamily {
    param(
        [string[]]$Candidates,
        [string]$Fallback = "Segoe UI"
    )

    $installed = [System.Drawing.Text.InstalledFontCollection]::new().Families | ForEach-Object { $_.Name }
    foreach ($name in $Candidates) {
        if ($installed -contains $name) {
            return $name
        }
    }

    return $Fallback
}

$script:uiFontFamily = Get-PreferredFontFamily -Candidates @(
    "Segoe UI Variable Text",
    "Space Grotesk",
    "Segoe UI",
    "Calibri"
) -Fallback "Segoe UI"

function New-Font {
    param(
        [float]$Size,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular,
        [string]$Family = $script:uiFontFamily
    )

    New-Object System.Drawing.Font($Family, $Size, $Style, [System.Drawing.GraphicsUnit]::Pixel)
}

Import-State

$form = New-Object WidgetForm
$form.Text = "Binary Bloom Clock"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.MinimumSize = New-Object System.Drawing.Size($minWidth, $minHeight)
$form.BackColor = $theme.BackgroundTop
$form.ShowInTaskbar = $true
$form.TopMost = $script:state.TopMost
$form.Icon = [System.Drawing.SystemIcons]::Information

if ($script:state.Bounds) {
    $bounds = $script:state.Bounds
    $form.Bounds = [System.Drawing.Rectangle]::new([int]$bounds.Left, [int]$bounds.Top, [int]$bounds.Width, [int]$bounds.Height)
    Set-WithinScreenBounds -Form $form
} else {
    Set-FitToScreen -Form $form
}

$rootPanel = New-Object BufferedPanel
$rootPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$rootPanel.Padding = New-Object System.Windows.Forms.Padding(24, 16, 24, 18)
$rootPanel.BackColor = $theme.BackgroundTop
$form.Controls.Add($rootPanel)

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 78
$headerPanel.BackColor = [System.Drawing.Color]::Transparent
$rootPanel.Controls.Add($headerPanel)

$clockPanel = New-Object BufferedPanel
$clockPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$clockPanel.BackColor = [System.Drawing.Color]::Transparent
$rootPanel.Controls.Add($clockPanel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Binary Bloom"
$titleLabel.Font = New-Font -Size 24 -Style ([System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $theme.TextMain
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.AutoSize = $true
$titleLabel.Location = [System.Drawing.Point]::new(10, 2)
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "A floating binary clock in pink and lilac. Resize freely, pin it on top, or hide it to the tray."
$subtitleLabel.Font = New-Font -Size 11
$subtitleLabel.ForeColor = $theme.TextSoft
$subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
$subtitleLabel.AutoSize = $false
$subtitleLabel.Size = New-Object System.Drawing.Size(620, 22)
$subtitleLabel.Location = [System.Drawing.Point]::new(12, 34)
$headerPanel.Controls.Add($subtitleLabel)

function New-ActionButton {
    param(
        [string]$Text,
        [int]$Width
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Width = $Width
    $button.Height = 34
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.Font = New-Font -Size 11 -Style ([System.Drawing.FontStyle]::Bold)
    $button.ForeColor = $theme.AccentDeep
    $button.BackColor = [System.Drawing.Color]::FromArgb(228, 255, 255, 255)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $button
}

$button12 = New-ActionButton -Text "12h" -Width 58
$button24 = New-ActionButton -Text "24h" -Width 58
$pinButton = New-ActionButton -Text "Pin" -Width 72
$fitButton = New-ActionButton -Text "Fit" -Width 68
$trayButton = New-ActionButton -Text "Tray" -Width 68
$closeButton = New-ActionButton -Text "Close" -Width 74

$buttons = @($button12, $button24, $pinButton, $fitButton, $trayButton, $closeButton)
function Set-ButtonPositions {
    $rightOffset = 0
    for ($index = $buttons.Count - 1; $index -ge 0; $index--) {
        $button = $buttons[$index]
        $button.Location = [System.Drawing.Point]::new(($headerPanel.Width - $button.Width - 4 - $rightOffset), 8)
        $rightOffset += $button.Width + 8
    }
}

foreach ($button in $buttons) {
    $headerPanel.Controls.Add($button)
}
Set-ButtonPositions
$headerPanel.add_SizeChanged({ Set-ButtonPositions })

$dragHandler = {
    [WidgetNativeMethods]::ReleaseCapture() | Out-Null
    [WidgetNativeMethods]::SendMessage($form.Handle, 0xA1, 2, 0) | Out-Null
}
$headerPanel.add_MouseDown($dragHandler)
$titleLabel.add_MouseDown($dragHandler)
$subtitleLabel.add_MouseDown($dragHandler)

$notifyMenu = New-Object System.Windows.Forms.ContextMenuStrip
$menuOpen = $notifyMenu.Items.Add("Open")
$menuTopMost = $notifyMenu.Items.Add("Always On Top")
$menuTopMost.CheckOnClick = $true
$null = $notifyMenu.Items.Add("Exit")
$menuExit = $notifyMenu.Items[$notifyMenu.Items.Count - 1]

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "Binary Bloom Clock"
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Visible = $true
$notifyIcon.ContextMenuStrip = $notifyMenu

$script:sparkles = @()
for ($i = 0; $i -lt 18; $i++) {
    $script:sparkles += [pscustomobject]@{
        X = [double](Get-Random -Minimum 5 -Maximum 95) / 100
        Y = [double](Get-Random -Minimum 6 -Maximum 94) / 100
        Radius = Get-Random -Minimum 4 -Maximum 11
        Seed = [double](Get-Random -Minimum 0 -Maximum 628) / 100
    }
}
$script:phase = 0.0
$script:balloonShown = $false
$script:allowExit = $false

function Update-ButtonStyles {
    foreach ($button in @($button12, $button24, $pinButton)) {
        $button.BackColor = [System.Drawing.Color]::FromArgb(228, 255, 255, 255)
        $button.ForeColor = $theme.AccentDeep
    }

    if ($script:state.TimeFormat -eq "12") {
        $button12.BackColor = $theme.TileActiveTop
        $button12.ForeColor = $theme.TextMain
    } else {
        $button24.BackColor = $theme.TileActiveTop
        $button24.ForeColor = $theme.TextMain
    }

    if ($script:state.TopMost) {
        $pinButton.BackColor = $theme.TileActiveTop
        $pinButton.ForeColor = $theme.TextMain
        $pinButton.Text = "Pinned"
    } else {
        $pinButton.Text = "Pin"
    }

    $menuTopMost.Checked = $script:state.TopMost
}

function Set-TopMostState {
    $form.TopMost = $script:state.TopMost
    Update-ButtonStyles
    Save-State
}

function Hide-ToTray {
    $form.Hide()
    if (-not $script:balloonShown) {
        $notifyIcon.ShowBalloonTip(1800, "Binary Bloom", "The clock is still running in the tray. Double-click the tray icon to restore it.", [System.Windows.Forms.ToolTipIcon]::Info)
        $script:balloonShown = $true
    }
}

function Restore-FromTray {
    $form.Show()
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    Set-WithinScreenBounds -Form $form
    Set-RoundedRegion -Form $form -Radius 34
    $form.Activate()
}

function Get-BinaryString {
    param([int]$Value)

    $bitCount = $clockValues.Count
    $binary = [Convert]::ToString($Value, 2)
    if ($binary.Length -gt $bitCount) {
        $binary = $binary.Substring($binary.Length - $bitCount)
    }

    $binary.PadLeft($bitCount, '0')
}

function Invoke-RoundedCardDraw {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius,
        [System.Drawing.Color]$Fill,
        [System.Drawing.Color]$Border,
        [float]$BorderWidth = 1.0
    )

    $path = New-RoundedPath -Rect $Rect -Radius $Radius
    $brush = New-Object System.Drawing.SolidBrush($Fill)
    $pen = New-Object System.Drawing.Pen($Border, $BorderWidth)
    $Graphics.FillPath($brush, $path)
    $Graphics.DrawPath($pen, $path)
    $brush.Dispose()
    $pen.Dispose()
    $path.Dispose()
}

function Invoke-BadgeDraw {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [System.Drawing.RectangleF]$Rect,
        [System.Drawing.Color]$Background,
        [System.Drawing.Color]$Foreground,
        [float]$Radius,
        [System.Drawing.Font]$Font
    )

    Invoke-RoundedCardDraw -Graphics $Graphics -Rect $Rect -Radius $Radius -Fill $Background -Border ([System.Drawing.Color]::FromArgb(60, $theme.AccentDeep))
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $brush = New-Object System.Drawing.SolidBrush($Foreground)
    $Graphics.DrawString($Text, $Font, $brush, $Rect, $stringFormat)
    $brush.Dispose()
    $stringFormat.Dispose()
}

$rootPanel.add_Paint({
    param($control, $e)

    $graphics = $e.Graphics
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $client = $rootPanel.ClientRectangle
    $backgroundRect = [System.Drawing.RectangleF]::new(0, 0, ($client.Width - 1), ($client.Height - 1))
    $path = New-RoundedPath -Rect $backgroundRect -Radius 28
    $gradient = [System.Drawing.Drawing2D.LinearGradientBrush]::new($backgroundRect, $theme.BackgroundTop, $theme.BackgroundBottom, 90.0)
    $graphics.FillPath($gradient, $path)

    $brushPink = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(58, 255, 160, 216))
    $brushLilac = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(46, 200, 164, 255))
    $graphics.FillEllipse($brushPink, -60 + ([math]::Sin($script:phase / 7) * 10), -30, 250, 210)
    $graphics.FillEllipse($brushLilac, $client.Width - 200 + ([math]::Cos($script:phase / 9) * 8), $client.Height - 220, 250, 230)
    $brushPink.Dispose()
    $brushLilac.Dispose()

    foreach ($sparkle in $script:sparkles) {
        $x = $sparkle.X * $client.Width
        $y = $sparkle.Y * $client.Height + ([math]::Sin($script:phase + $sparkle.Seed) * 6)
        $alpha = 70 + [int]((([math]::Sin(($script:phase * 1.6) + $sparkle.Seed) + 1) / 2) * 120)
        $sparkleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($alpha, $theme.Sparkle))
        $graphics.FillEllipse($sparkleBrush, $x, $y, $sparkle.Radius, $sparkle.Radius)
        $sparkleBrush.Dispose()
    }

    $borderPen = New-Object System.Drawing.Pen($theme.Border, 1.4)
    $graphics.DrawPath($borderPen, $path)
    $borderPen.Dispose()
    $gradient.Dispose()
    $path.Dispose()
})

$clockPanel.add_Paint({
    param($control, $e)

    $clockState = Get-HourState
    $graphics = $e.Graphics
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality

    $bounds = $clockPanel.ClientRectangle
    if ($bounds.Width -le 0 -or $bounds.Height -le 0) {
        return
    }

    $padding = 10
    $workingRect = [System.Drawing.RectangleF]::new($padding, $padding, ($bounds.Width - ($padding * 2)), ($bounds.Height - ($padding * 2)))
    $scaleX = $workingRect.Width / 930
    $scaleY = $workingRect.Height / 620
    # Keep sizing consistent: only shrink to fit smaller windows, never upscale above baseline.
    $scale = [Math]::Max(0.72, [Math]::Min(1.0, [Math]::Min($scaleX, $scaleY)))

    $gap = 18 * $scale
    $cardsHeight = $workingRect.Height - (6 * $scale)
    $columnWidth = ($workingRect.Width - ($gap * 2)) / 3
    $cardRadius = 24 * $scale
    $cardY = $workingRect.Y + (6 * $scale)

    $tinyFont = New-Font -Size (10 * $scale)
    $tileValueFont = New-Font -Size (11 * $scale) -Style ([System.Drawing.FontStyle]::Bold)
    $bigFont = New-Font -Size (36 * $scale) -Style ([System.Drawing.FontStyle]::Bold)

    $textBrush = New-Object System.Drawing.SolidBrush($theme.TextMain)
    $softBrush = New-Object System.Drawing.SolidBrush($theme.TextSoft)
    $accentBrush = New-Object System.Drawing.SolidBrush($theme.AccentDeep)

    $bitCount = $clockValues.Count

    $columns = @(
        @{ Title = "Hours"; Value = [int]$clockState.BinaryHour; Display = "{0:00}" -f $clockState.Hour; Period = $clockState.Period },
        @{ Title = "Minutes"; Value = [int]$clockState.Minute; Display = "{0:00}" -f $clockState.Minute; Period = $null },
        @{ Title = "Seconds"; Value = [int]$clockState.Second; Display = "{0:00}" -f $clockState.Second; Period = $null }
    )

    for ($index = 0; $index -lt $columns.Count; $index++) {
        $column = $columns[$index]
        $cardRect = [System.Drawing.RectangleF]::new(
            ($workingRect.X + (($columnWidth + $gap) * $index)),
            $cardY,
            $columnWidth,
            $cardsHeight
        )
        Invoke-RoundedCardDraw -Graphics $graphics -Rect $cardRect -Radius $cardRadius -Fill ([System.Drawing.Color]::FromArgb(138, 255, 255, 255)) -Border ([System.Drawing.Color]::FromArgb(70, $theme.Border))

        $graphics.DrawString($column.Title, $tinyFont, $softBrush, $cardRect.X + (18 * $scale), $cardRect.Y + (18 * $scale))
        $binaryRect = [System.Drawing.RectangleF]::new(($cardRect.Right - (110 * $scale)), ($cardRect.Y + (12 * $scale)), (92 * $scale), (28 * $scale))
        Invoke-BadgeDraw -Graphics $graphics -Text (Get-BinaryString $column.Value) -Rect $binaryRect -Background ([System.Drawing.Color]::FromArgb(210, 255, 255, 255)) -Foreground $theme.AccentDeep -Radius (14 * $scale) -Font $tinyFont

        $tileTop = $cardRect.Y + (56 * $scale)
        $tileBottom = $cardRect.Bottom - (104 * $scale)
        $tileGap = 10 * $scale
        $tileArea = [Math]::Max(80 * $scale, $tileBottom - $tileTop)
        $tileHeightColumn = ($tileArea - ($tileGap * ($bitCount - 1))) / $bitCount
        $tileWidth = $cardRect.Width - (36 * $scale)
        $binary = Get-BinaryString $column.Value
        for ($i = 0; $i -lt $bitCount; $i++) {
            $tileRect = [System.Drawing.RectangleF]::new(
                ($cardRect.X + (18 * $scale)),
                ($tileTop + (($tileHeightColumn + $tileGap) * $i)),
                $tileWidth,
                $tileHeightColumn
            )

            $isActive = $binary[$i] -eq '1'
            if ($isActive) {
                $pathTile = New-RoundedPath -Rect $tileRect -Radius (20 * $scale)
                $gradientTile = [System.Drawing.Drawing2D.LinearGradientBrush]::new($tileRect, $theme.TileActiveTop, $theme.TileActiveBottom, 90.0)
                $penTile = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(160, 255, 255, 255), 1.2)
                $graphics.FillPath($gradientTile, $pathTile)
                $graphics.DrawPath($penTile, $pathTile)
                $gradientTile.Dispose()
                $penTile.Dispose()
                $pathTile.Dispose()
            } else {
                Invoke-RoundedCardDraw -Graphics $graphics -Rect $tileRect -Radius (20 * $scale) -Fill $theme.TileIdle -Border ([System.Drawing.Color]::FromArgb(40, $theme.Border))
            }

            $graphics.DrawString([string]$clockValues[$i], $tileValueFont, $(if ($isActive) { $textBrush } else { $softBrush }), $tileRect.Right - (34 * $scale), $tileRect.Bottom - (24 * $scale))
        }

        $displayTextSize = $graphics.MeasureString($column.Display, $bigFont)
        $displayX = $cardRect.X + (($cardRect.Width - $displayTextSize.Width) / 2)
        $displayY = $cardRect.Bottom - (82 * $scale)
        $graphics.DrawString($column.Display, $bigFont, $textBrush, $displayX, $displayY)

        if ($column.Period) {
            $periodRect = [System.Drawing.RectangleF]::new(($cardRect.X + (($cardRect.Width - (78 * $scale)) / 2)), ($cardRect.Bottom - (42 * $scale)), (78 * $scale), (26 * $scale))
            Invoke-BadgeDraw -Graphics $graphics -Text $column.Period -Rect $periodRect -Background ([System.Drawing.Color]::FromArgb(216, 255, 255, 255)) -Foreground $theme.AccentDeep -Radius (13 * $scale) -Font $tinyFont
        }
    }

    $textBrush.Dispose()
    $softBrush.Dispose()
    $accentBrush.Dispose()
    $tinyFont.Dispose()
    $tileValueFont.Dispose()
    $bigFont.Dispose()
})

$animationTimer = New-Object System.Windows.Forms.Timer
$animationTimer.Interval = 90
$animationTimer.add_Tick({
    $script:phase += 0.14
    $rootPanel.Invalidate()
})

$clockTimer = New-Object System.Windows.Forms.Timer
$clockTimer.Interval = 1000
$clockTimer.add_Tick({
    $clockPanel.Invalidate()
})

$button12.add_Click({
    $script:state.TimeFormat = "12"
    Update-ButtonStyles
    Save-State
    $clockPanel.Invalidate()
})

$button24.add_Click({
    $script:state.TimeFormat = "24"
    Update-ButtonStyles
    Save-State
    $clockPanel.Invalidate()
})

$pinButton.add_Click({
    $script:state.TopMost = -not $script:state.TopMost
    Set-TopMostState
})

$fitButton.add_Click({
    Set-FitToScreen -Form $form
    Set-RoundedRegion -Form $form -Radius 34
    $script:state.Bounds = @{ Left = $form.Left; Top = $form.Top; Width = $form.Width; Height = $form.Height }
    Save-State
})

$trayButton.add_Click({
    Hide-ToTray
})

$closeButton.add_Click({
    $script:allowExit = $true
    $form.Close()
})

$menuOpen.add_Click({
    Restore-FromTray
})

$menuTopMost.add_Click({
    $script:state.TopMost = $menuTopMost.Checked
    Set-TopMostState
})

$menuExit.add_Click({
    $script:allowExit = $true
    $form.Close()
})

$notifyIcon.add_DoubleClick({
    Restore-FromTray
})

$form.add_Shown({
    Update-ButtonStyles
    Set-WithinScreenBounds -Form $form
    Set-RoundedRegion -Form $form -Radius 34
    $animationTimer.Start()
    $clockTimer.Start()
    $clockPanel.Invalidate()
})

$form.add_SizeChanged({
    if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
        Hide-ToTray
        return
    }

    Set-WithinScreenBounds -Form $form
    Set-RoundedRegion -Form $form -Radius 34
    $script:state.Bounds = @{ Left = $form.Left; Top = $form.Top; Width = $form.Width; Height = $form.Height }
    Save-State
    Set-ButtonPositions
    $clockPanel.Invalidate()
})

$form.add_Move({
    Set-WithinScreenBounds -Form $form
    $script:state.Bounds = @{ Left = $form.Left; Top = $form.Top; Width = $form.Width; Height = $form.Height }
    Save-State
})

$form.add_FormClosing({
    param($control, $e)

    if (-not $script:allowExit) {
        $e.Cancel = $true
        Hide-ToTray
        return
    }

    Save-State
    $animationTimer.Stop()
    $clockTimer.Stop()
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
})

Set-TopMostState
[System.Windows.Forms.Application]::Run($form)
