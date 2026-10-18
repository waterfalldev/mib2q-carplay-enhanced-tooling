#requires -version 7.0
<#
.SYNOPSIS
Build a checked M.I.B. package from committed application and tooling revisions.
.DESCRIPTION
No fetch, push or vehicle access. Both clean repositories are exported with LF
line endings. The selected tooling export supplies the worker, tests and templates;
the application export supplies component builds, runtime source and runtime tests.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SourceRepository,
    [Parameter(Mandatory=$true)][string]$FirmwareRoot,
    [Parameter(Mandatory=$true)][string]$Dependencies,
    [Parameter(Mandatory=$true)][string]$WorkRoot,
    [Parameter(Mandatory=$true)][string]$OutputRoot,
    [string]$Ref = 'HEAD',
    [string]$ToolingRef = 'HEAD',
    [string]$JavaHome = '',
    [string]$JavaImage = 'eclipse-temurin:8-jdk-jammy',
    [string]$ExpectedToolchainImageId = '',
    [string]$HostTestImage = 'carplay-rgi-host-tests:local',
    [ValidatePattern('^[A-Za-z0-9]*$')][string]$Label = '',
    [switch]$ForceRebuild,
    [switch]$ArmRollback
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
. "$PSScriptRoot/PackageTools.ps1"
. "$PSScriptRoot/SourceExports.ps1"
$application = Get-BuildRepository -Path $SourceRepository -Ref $Ref -Description 'Application'
$tooling = Get-BuildRepository -Path (Split-Path -Parent $PSScriptRoot) -Ref $ToolingRef -Description 'Tooling'
Assert-SeparateBuildPaths $application.Root $tooling.Root
foreach ($name in @('FirmwareRoot','Dependencies','WorkRoot','OutputRoot')) {
    $value = Get-BuildPath (Get-Variable $name -ValueOnly)
    foreach ($repo in @($application, $tooling)) { Assert-SeparateBuildPaths $value $repo.Root }
    Set-Variable $name $value
}
foreach ($writable in @($WorkRoot, $OutputRoot)) {
    foreach ($inputRoot in @($FirmwareRoot, $Dependencies)) { Assert-SeparateBuildPaths $writable $inputRoot }
}
Assert-SeparateBuildPaths $WorkRoot $OutputRoot
$profileData = Import-PowerShellDataFile -LiteralPath (Join-Path $FirmwareRoot 'Firmware.psd1')
$firmware = [string]$profileData.Name
if ($firmware -notmatch '^[A-Za-z0-9_]+$') { throw 'Invalid firmware profile name.' }
$short = $application.Commit.Substring(0,12)
$toolsShort = $tooling.Commit.Substring(0,12)
New-Item -ItemType Directory -Force -Path $WorkRoot, $OutputRoot | Out-Null
$run = Join-Path $WorkRoot ('source-' + $short + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
Assert-SafeChildPath -Root $WorkRoot -Candidate $run -Description 'source export'
New-Item -ItemType Directory -Path $run | Out-Null
$source = Export-BuildRepository $application $run 'application'
$tools = Export-BuildRepository $tooling $run 'tooling'
$scratch = Join-Path $run 'scratch'
New-Item -ItemType Directory -Path $scratch | Out-Null
$snapshot = Join-Path $tools 'packaging/Build-Snapshot.ps1'
Assert-FileExists $snapshot 'selected tooling build worker'
if (-not (Get-Command -Name $snapshot).Parameters.ContainsKey('ToolingCommit')) {
    throw 'Selected tooling revision predates the two-repository build contract.'
}
$final = Join-Path $OutputRoot ('mib2q-carplay-enhanced_' + $firmware + '_source_' + $short + '_tooling_' + $toolsShort + $(if ($Label) { '_' + $Label } else { '' }))
if ((Test-Path -LiteralPath $final) -and -not $ForceRebuild) { throw "Completed package already exists: $final" }
$pending = Join-Path $OutputRoot ('.pending-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $pending | Out-Null
Write-Host "Application commit: $($application.Commit)"
Write-Host "Tooling commit: $($tooling.Commit)"
& $snapshot -SourceRoot $source -ToolingRoot $tools -Commit $application.Commit -ToolingCommit $tooling.Commit `
    -FirmwareRoot $FirmwareRoot -Firmware $firmware -Dependencies $Dependencies -ScratchRoot $scratch `
    -ReleaseDirectory $pending -JavaImage $JavaImage -ExpectedToolchainImageId $ExpectedToolchainImageId `
    -HostTestImage $HostTestImage -ArmRollback:$ArmRollback
. (Join-Path $tools 'packaging/PackageTools.ps1')
Publish-PreparedPackage -Root $OutputRoot -Pending $pending -Final $final -AllowReplace:$ForceRebuild
Write-Host "Completed package: $final"
Write-Host "Exact source: $($application.Commit)"
Write-Host "Exact tooling: $($tooling.Commit)"
Write-Output $final
