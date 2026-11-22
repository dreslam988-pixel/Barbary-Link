# SPDX-License-Identifier: GPL-3.0-or-later
<#
.SYNOPSIS
  Installs, starts, quits and uninstalls the packaged app silently, checking
  each step. For CI (needs admin; changes this PC), not for everyday use.
#>
param(
    [string]$Setup
)

$ErrorActionPreference = 'Stop'

if (-not $Setup) {
    $arch = if ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture -eq [System.Runtime.InteropServices.Architecture]::Arm64) { 'arm64' } else { 'x64' }
    $pkgDir = Join-Path $PSScriptRoot '..\target\package'
    $match = Get-ChildItem (Join-Path $pkgDir "*-$arch-setup.exe") -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $match) {
        $match = Get-ChildItem (Join-Path $pkgDir '*-setup.exe') -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($match) { $Setup = $match.FullName }
}
if (-not $Setup -or -not (Test-Path $Setup)) { throw "no setup installer found to test under target\package" }
$dir = Join-Path $env:ProgramFiles 'BarbaryLink'
$exe = Join-Path $dir 'barbary-link.exe'
$uninstallKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\BarbaryLink'
$shortcut = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\BarbaryLink.lnk'
$desktopShortcut = Join-Path $env:PUBLIC 'Desktop\Barbary Link.lnk'
$data = if ($env:RUNNER_TEMP) { Join-Path $env:RUNNER_TEMP 'nectarlink-smoke' } else { Join-Path $env:TEMP 'nectarlink-smoke' }

function Check($what, [bool]$ok) {
    if (-not $ok) { throw "FAILED: $what" }
    Write-Host "ok: $what"
}
function FirewallRule { (netsh advfirewall firewall show rule name=BarbaryLink) -match 'BarbaryLink' }
# Whether an allow entry for `$sid` grants every bit of `$rights`.
function Test-TaskRights($sd, [string]$sid, [int]$rights) {
    [bool]($sd.DiscretionaryAcl | Where-Object {
        $_.AceQualifier -eq 'AccessAllowed' -and $_.SecurityIdentifier.Value -eq $sid -and
        ($_.AccessMask -band $rights) -eq $rights })
}
# Whether anyone but SYSTEM and administrators may write, delete or re-permission it.
function Test-OthersMayWrite($sd) {
    # FILE_WRITE_DATA, APPEND, WRITE_EA, WRITE_ATTRIBUTES, DELETE, WRITE_DAC,
    # WRITE_OWNER, GENERIC_ALL, GENERIC_WRITE.
    $write = 0x2 -bor 0x4 -bor 0x10 -bor 0x100 -bor 0x10000 -bor 0x40000 -bor 0x80000 -bor 0x10000000 -bor 0x40000000
    [bool]($sd.DiscretionaryAcl | Where-Object {
        $_.AceQualifier -eq 'AccessAllowed' -and
        $_.SecurityIdentifier.Value -notin @('S-1-5-18', 'S-1-5-32-544') -and
        ($_.AccessMask -band $write) -ne 0 })
}
function UpdateTask {
    $scheduler = New-Object -ComObject Schedule.Service
    $scheduler.Connect()
    try { $scheduler.GetFolder('\').GetTask('BarbaryLink Update') } catch { $null }
}

Write-Host "Installing $Setup"
Start-Process $Setup -ArgumentList '/S' -Wait
Check "the app is installed" (Test-Path $exe)
Check "an uninstaller is installed" (Test-Path (Join-Path $dir 'uninstall.exe'))
$agent = Join-Path $dir 'nectarlink-agent.exe'
Check "the agent command is installed next to the app" (Test-Path $agent)
& $agent --help | Out-Null
Check "the agent command runs" ($LASTEXITCODE -eq 0)
Check "it's in Apps (uninstall entry)" (Test-Path $uninstallKey)
Check "it's in the Start menu" (Test-Path $shortcut)
Check "a first install adds a desktop shortcut" (Test-Path $desktopShortcut)
Check "the firewall lets phones in" ([bool](FirewallRule))
Check "license notices are included" ((Get-Item (Join-Path $dir 'THIRD-PARTY-NOTICES.txt')).Length -gt 100KB)
Check "the fork registers no original-project updater task" ($null -eq (UpdateTask))

# The desktop shortcut: an update (no /DESKTOP, as the updater runs it) leaves
# a deleted one deleted; the setup window's choice adds or removes it.
Remove-Item $desktopShortcut
Start-Process $Setup -ArgumentList '/S' -Wait
Check "an update doesn't bring back a deleted desktop shortcut" (-not (Test-Path $desktopShortcut))
Start-Process $Setup -ArgumentList '/S', '/DESKTOP=1' -Wait
Check "asking for a desktop shortcut adds it" (Test-Path $desktopShortcut)
Start-Process $Setup -ArgumentList '/S' -Wait
Check "an update keeps the desktop shortcut" (Test-Path $desktopShortcut)
Start-Process $Setup -ArgumentList '/S', '/DESKTOP=0' -Wait
Check "declining a desktop shortcut removes it" (-not (Test-Path $desktopShortcut))
Start-Process $Setup -ArgumentList '/S', '/DESKTOP=1' -Wait

# The installed copy starts on its own files and quits when asked.
$app = Start-Process $exe -ArgumentList '--minimized', '--data-dir', $data -PassThru
Start-Sleep 8
Check "the installed app keeps running" (-not $app.HasExited)
Start-Process $exe -ArgumentList '--quit', '--data-dir', $data -Wait
Check "the app quits when asked" ($app.WaitForExit(15000))
Check "it shut down cleanly" ($app.ExitCode -eq 0)

Write-Host "Uninstalling"
Start-Process (Join-Path $dir 'uninstall.exe') -ArgumentList '/S' -Wait
# The uninstaller runs from a copy in %TEMP%, so it returns before it's done.
$deadline = (Get-Date).AddSeconds(60)
while ((Test-Path $dir) -and (Get-Date) -lt $deadline) { Start-Sleep 1 }
Check "the app folder is gone" (-not (Test-Path $dir))
Check "the uninstall entry is gone" (-not (Test-Path $uninstallKey))
Check "the Start menu shortcut is gone" (-not (Test-Path $shortcut))
Check "the desktop shortcut is gone" (-not (Test-Path $desktopShortcut))
Check "the firewall rule is gone" (-not (FirewallRule))
Check "the update task is gone" ($null -eq (UpdateTask))

# A folder the user picked (#102), with a space in it, as the setup window
# passes it: /D last and unquoted. Its parent doesn't exist, so setup
# creates both and locks them like Program Files.
$top = 'C:\nl smoke'
$custom = Join-Path $top 'Apps\BarbaryLink'
$customExe = Join-Path $custom 'barbary-link.exe'
$reg = 'HKLM:\Software\BarbaryLink'
function Test-Locked($path) {
    $acl = Get-Acl $path
    $sd = New-Object System.Security.AccessControl.RawSecurityDescriptor $acl.Sddl
    $acl.Owner -eq 'BUILTIN\Administrators' -and -not (Test-OthersMayWrite $sd)
}
Write-Host "Installing into $custom"
Start-Process $Setup -ArgumentList "/S /ADMINONLY=1 /D=$custom" -Wait
Check "the app is installed in the chosen folder" (Test-Path $customExe)
Check "nothing went into Program Files" (-not (Test-Path $dir))
Check "the chosen folder is locked like Program Files" (Test-Locked $custom)
Check "the folder setup created above it is locked too" (Test-Locked $top)
Check "an admin-only fork install has no updater task" ($null -eq (UpdateTask))
Check "the chosen folder is remembered" ((Get-ItemProperty $reg).InstallDir -eq $custom -and (Get-ItemProperty $reg).AdminOnlyFolder -eq 1)
Start-Process $Setup -ArgumentList '/S' -Wait
Check "an update goes to the chosen folder" ((Test-Path $customExe) -and -not (Test-Path $dir))
Check "a reinstall keeps the updater task absent" ($null -eq (UpdateTask))
Start-Process (Join-Path $custom 'uninstall.exe') -ArgumentList '/S' -Wait
$deadline = (Get-Date).AddSeconds(60)
while ((Test-Path $custom) -and (Get-Date) -lt $deadline) { Start-Sleep 1 }
Check "uninstalling removes the chosen folder" (-not (Test-Path $custom))
Check "uninstalling removes the update task" ($null -eq (UpdateTask))

# Where folders above it aren't admin-only: no task running it as SYSTEM.
Start-Process $Setup -ArgumentList "/S /ADMINONLY=0 /D=$custom" -Wait
Check "the app is installed there" (Test-Path $customExe)
Check "a folder others could swap gets no update task" ($null -eq (UpdateTask))
Check "updates there will ask" ((Get-ItemProperty $reg).AdminOnlyFolder -eq 0)
Start-Process $Setup -ArgumentList '/S' -Wait
Check "an update there still adds no update task" ($null -eq (UpdateTask))
Start-Process (Join-Path $custom 'uninstall.exe') -ArgumentList '/S' -Wait
$deadline = (Get-Date).AddSeconds(60)
while ((Test-Path $custom) -and (Get-Date) -lt $deadline) { Start-Sleep 1 }
Check "it uninstalls from there" (-not (Test-Path $custom))

# A folder that already has files in it is refused.
$busy = Join-Path $top 'Busy\BarbaryLink'
New-Item -ItemType Directory -Force $busy | Out-Null
Set-Content (Join-Path $busy 'someone-elses.txt') 'x'
$run = Start-Process $Setup -ArgumentList "/S /ADMINONLY=1 /D=$busy" -Wait -PassThru
Check "a folder with files in it is refused" ($run.ExitCode -ne 0 -and -not (Test-Path (Join-Path $busy 'barbary-link.exe')))
Check "a refused folder leaves no update task" ($null -eq (UpdateTask))
Remove-Item -Recurse -Force $top
Write-Host "Installer smoke test passed."
# netsh reports "no rules match" with a failing exit code; that was the point.
exit 0
