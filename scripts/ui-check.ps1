# SPDX-License-Identifier: GPL-3.0-or-later
<#
.SYNOPSIS
  Opens the Windows app's main window for a few seconds and fails on any
  QML warning or error.

.DESCRIPTION
  Runs barbary-link.exe --ui-check with a new data folder under
  target\ui-check, so the user's own data is never touched, and without
  USB (NECTARLINK_NO_ADB=1). The app shows the main window, quits after a
  few seconds and exits with an error if QML reported a problem, such as a
  component that didn't load. The QML tests can't catch that for the app's
  windows, which need the Rust singletons and NativeWindow.

  It runs twice: once on a fresh folder (the first-run walkthrough), and
  once with the walkthrough done, so Home opens. Both times the app adds a
  pretend paired phone to the folder, so the pages that only show with a
  phone load too.

  -Exe defaults to the staged package (scripts\package.ps1), which has its
  Qt libraries next to it; for target\release, pass -Exe and have Qt's bin
  folder on PATH.

.EXAMPLE
  .\scripts\package.ps1 -StageOnly; .\scripts\ui-check.ps1
#>
param(
    [string]$Exe
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $Exe) { $Exe = Join-Path $repo 'target\package\BarbaryLink\barbary-link.exe' }
if (-not (Test-Path $Exe)) { throw "$Exe not found; run scripts\package.ps1 -StageOnly first, or pass -Exe" }

# Capture outside Qt: the existing pre-application Qt timer cannot reliably
# run before QGuiApplication has created its event dispatcher.
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class BarbaryWindowCapture {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    private delegate bool EnumProc(IntPtr hwnd, IntPtr data);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumProc fn, IntPtr data);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] private static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hwnd, IntPtr dc, uint flags);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
    public static IntPtr Find(int pid) {
        IntPtr found = IntPtr.Zero;
        EnumWindows((hwnd, data) => {
            uint owner; Rect r; GetWindowThreadProcessId(hwnd, out owner);
            if (owner == pid && IsWindowVisible(hwnd) && GetWindowRect(hwnd, out r) && r.Right-r.Left > 500 && r.Bottom-r.Top > 200) {
                found = hwnd; return false;
            }
            return true;
        }, IntPtr.Zero);
        return found;
    }
}
'@
function Save-BarbaryWindow([int]$ProcessId, [string]$Path, [string]$DesktopPath) {
    $window = [BarbaryWindowCapture]::Find($ProcessId)
    if ($window -eq [IntPtr]::Zero) { return $false }
    $null = [BarbaryWindowCapture]::SetForegroundWindow($window)
    $rect = New-Object BarbaryWindowCapture+Rect
    if (-not [BarbaryWindowCapture]::GetWindowRect($window, [ref]$rect)) { return $false }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    foreach ($method in @('print', 'screen')) {
        $image = [System.Drawing.Bitmap]::new($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($image)
        try {
            if ($method -eq 'print') {
                $dc = $graphics.GetHdc()
                try { $null = [BarbaryWindowCapture]::PrintWindow($window, $dc, 2) }
                finally { $graphics.ReleaseHdc($dc) }
                $image.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
            } else {
                $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width,$height))
                $image.Save($DesktopPath, [System.Drawing.Imaging.ImageFormat]::Png)
            }
        } finally { $graphics.Dispose(); $image.Dispose() }
    }
    return $true
}

foreach ($pass in @('walkthrough', 'home')) {
    Write-Host "UI check: $pass"
    $data = Join-Path $repo "target\ui-check\$pass"
    if (Test-Path $data) { Remove-Item -Recurse -Force $data }
    New-Item -ItemType Directory -Force $data | Out-Null
    if ($pass -eq 'home') {
        [System.IO.File]::WriteAllText((Join-Path $data 'desktop-settings.json'), '{ "walkthroughCompleted": true }')
    }
    $stderr = Join-Path $data 'stderr.txt'

    $env:NECTARLINK_NO_ADB = '1'
    $env:BARBARY_UI_SCREENSHOT = Join-Path $data "screenshot.png"
    $app = Start-Process $Exe -ArgumentList '--ui-check', '--data-dir', "`"$data`"" `
        -RedirectStandardError $stderr -PassThru -NoNewWindow
    # Without the handle, ExitCode stays empty after the process exits.
    $null = $app.Handle
    Start-Sleep -Milliseconds 3500
    $captured = Save-BarbaryWindow -ProcessId $app.Id -Path (Join-Path $data 'screenshot.png') -DesktopPath (Join-Path $data 'desktop-capture.png')
    if (-not $captured) { throw "No visible application window was available for $pass" }
    if (-not $app.WaitForExit(120000)) {
        $app.Kill()
        throw "the app didn't quit within 2 minutes"
    }
    Get-Content $stderr | Write-Host
    if ($app.ExitCode -ne 0) { throw "UI check ($pass) failed (exit code $($app.ExitCode))" }
}
