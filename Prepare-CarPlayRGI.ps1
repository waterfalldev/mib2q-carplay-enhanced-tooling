#requires -version 7.0
<#
.SYNOPSIS
    Build a CarPlay-RGI M.I.B. package for one firmware from the local fork.

.DESCRIPTION
    Local entry point for this workspace. PC only; it never accesses the car.
    -Firmware selects Build\Firmware\<name>: its schema-2 Firmware.psd1 and the
    stock lsd.jxe, lsd.jar and production JSONs it pins. The fork's
    packaging\Build-Package.ps1 then exports one committed revision, builds and
    checks Java, the hook, the renderer and the installer, and publishes the
    package under Packages. Older completed packages move to Packages\Archive
    only after the new one has passed every check.

    The fork checkout must be clean: commit changes before building. Every
    package starts with ACTION=install unless -ArmRollback is given.

    Source exports and test fixtures go to a new folder under the system temp
    directory, removed after a successful build and kept after a failed one. The
    complete output, with elapsed time on each line, is saved as build-log.txt in
    the published package.

.EXAMPLE
    .\Build\Prepare-CarPlayRGI.ps1 -Firmware MU1329 -Label mu1329nfc15
#>
[CmdletBinding()]
param(
    # Build\Firmware\<name>, e.g. MU1329. Its profile must carry the same Name.
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_]+$')]
    [string]$Firmware,

    # Optional package name suffix, e.g. a trial number such as mu1329nfc15.
    [ValidatePattern('^[A-Za-z0-9]*$')]
    [string]$Label = '',

    # Commit to build; resolved locally in the fork without fetching.
    [string]$Ref = 'HEAD',

    [string]$CarRoot = '',
    [string]$RepoRoot = '',
    [string]$OutputRoot = '',
    [string]$JavaHome = '',
    [string]$ExpectedToolchainImageId = '',
    [switch]$ForceRebuild,
    [switch]$ArmRollback
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if (-not $CarRoot) { $CarRoot = Split-Path -Parent $PSScriptRoot }
if (-not $RepoRoot) { $RepoRoot = Join-Path $CarRoot 'Repositories\mib2q-carplay-rgi-nonfpk' }
if (-not $OutputRoot) { $OutputRoot = Join-Path $CarRoot 'Packages' }
$FirmwareRoot = Join-Path $PSScriptRoot ('Firmware\' + $Firmware)
$Dependencies = Join-Path $PSScriptRoot 'Dependencies'
$HostTestImage = 'carplay-rgi-host-tests:local'

$builder = Join-Path $RepoRoot 'packaging\Build-Package.ps1'
if (-not (Test-Path -LiteralPath $builder -PathType Leaf)) { throw "Fork package builder not found: $builder" }
$profilePath = Join-Path $FirmwareRoot 'Firmware.psd1'
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) { throw "Firmware profile not found: $profilePath" }
$profileName = (Import-PowerShellDataFile -LiteralPath $profilePath).Name
if ($profileName -cne $Firmware) { throw "Build\Firmware\$Firmware holds the profile for '$profileName'." }

& docker image inspect $HostTestImage *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker image $HostTestImage is missing. Build it once in the fork: docker build -t $HostTestImage -f tests/Dockerfile.host ."
}

$git = @('-c', ('safe.directory=' + $RepoRoot.Replace('\', '/')), '-C', $RepoRoot)
$branch = (& git @git branch --show-current)
$WorkRoot = Join-Path ([IO.Path]::GetTempPath()) ('carplay-rgi-build-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $WorkRoot | Out-Null
$logPath = Join-Path $WorkRoot 'build-log.txt'
$log = New-Object System.Collections.Generic.List[string]
$clock = [Diagnostics.Stopwatch]::StartNew()
$stamp = { param([string]$Line) $log.Add(('[{0:mm\:ss}] ' -f $clock.Elapsed) + $Line) }
& $stamp "Fork: $RepoRoot ($branch), building $Ref for $Firmware"
& $stamp "Scratch: $WorkRoot"
Write-Host "Fork: $RepoRoot ($branch), building $Ref for $Firmware"

# The builder streams native build and test output; every stream is shown and logged.
# Its last output line is the published package path.
$package = $null
$succeeded = $false
try {
    & $builder -FirmwareRoot $FirmwareRoot -Dependencies $Dependencies -WorkRoot $WorkRoot `
        -OutputRoot $OutputRoot -Ref $Ref -JavaHome $JavaHome -ExpectedToolchainImageId $ExpectedToolchainImageId `
        -HostTestImage $HostTestImage -Label $Label -ForceRebuild:$ForceRebuild -ArmRollback:$ArmRollback *>&1 |
        ForEach-Object {
            foreach ($line in (($_ | Out-String) -split "\r?\n")) { if ($line) { & $stamp $line } }
            if ($_ -is [string]) { $package = $_ }
            $_
        }
    $succeeded = $true
}
catch {
    & $stamp "FAILED: $_"
    throw
}
finally {
    & $stamp ('Finished after {0:mm\:ss}' -f $clock.Elapsed)
    [IO.File]::WriteAllLines($logPath, $log, (New-Object Text.UTF8Encoding($false)))
    if ($succeeded -and $package -and (Test-Path -LiteralPath $package -PathType Container)) {
        Copy-Item -LiteralPath $logPath -Destination (Join-Path $package 'build-log.txt')
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force
        Write-Host "Build log: $(Join-Path $package 'build-log.txt')"
    } else {
        Write-Host "Build did not complete; scratch and build-log.txt kept in $WorkRoot"
    }
}
