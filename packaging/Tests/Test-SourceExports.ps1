#requires -version 7.0
# Exercise the public builder with real temporary Git repositories and a small
# worker that records which committed inputs it actually consumed. No Docker.
param([string]$TestRootParent = [IO.Path]::GetTempPath())
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/../PackageTools.ps1"
. "$PSScriptRoot/../SourceExports.ps1"
$root = Join-Path $TestRootParent ('source exports ' + [guid]::NewGuid().ToString('N'))
$app = Join-Path $root 'arbitrary application name'
$tools = Join-Path $root 'arbitrary tooling name'
foreach ($path in @($app, "$tools/packaging", "$root/firmware", "$root/deps")) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
$git = (Get-Command git).Source
function GitAt([string]$repo, [string[]]$arguments) {
    Invoke-Native -Exe $git -Arguments (@('-c',('safe.directory=' + $repo.Replace('\','/')),'-c','user.name=Build Fixture','-c','user.email=fixture@example.invalid','-C',$repo) + $arguments) -Capture
}
function Commit([string]$repo, [string]$message) {
    GitAt $repo @('add','--all') | Out-Null
    GitAt $repo @('commit','-m',$message) | Out-Null
    return @(GitAt $repo @('rev-parse','HEAD'))[0]
}
$checks = 0
function Check([bool]$condition, [string]$message) {
    if (-not $condition) { throw "FAIL: $message" }
    $script:checks++; Write-Host "PASS: $message"
}
function Refuses([scriptblock]$action, [string]$pattern, [string]$message) {
    $failure = ''
    try { & $action | Out-Null } catch { $failure = $_.ToString() }
    Check ($failure -match $pattern) "$message ($failure)"
}
foreach ($repo in @($app,$tools)) { GitAt $repo @('init','-q') | Out-Null }
Write-LfUtf8 "$app/value.txt" "application A`n"
$appA = Commit $app 'application A'
Write-LfUtf8 "$app/value.txt" "application B`n"
$appB = Commit $app 'application B'
foreach ($name in @('Build-Package.ps1','PackageTools.ps1','SourceExports.ps1')) { Copy-Item -LiteralPath "$PSScriptRoot/../$name" -Destination "$tools/packaging/$name" }
$worker = @'
param($SourceRoot,$ToolingRoot,$Commit,$ToolingCommit,$FirmwareRoot,$Firmware,$Dependencies,$ScratchRoot,$ReleaseDirectory,$JavaImage,$ExpectedToolchainImageId,$HostTestImage,[switch]$ArmRollback)
$ErrorActionPreference = 'Stop'
$record = [ordered]@{
    sourceCommit=$Commit; toolingCommit=$ToolingCommit
    application=(Get-Content -Raw -LiteralPath "$SourceRoot/value.txt").Trim()
    template=(Get-Content -Raw -LiteralPath "$ToolingRoot/template.txt").Trim()
    worker='worker A'
}
$record | ConvertTo-Json | Set-Content -LiteralPath "$ReleaseDirectory/PACKAGE-VALIDATION.json"
'@
Write-LfUtf8 "$tools/packaging/Build-Snapshot.ps1" $worker
Write-LfUtf8 "$tools/template.txt" "template A`n"
$toolsA = Commit $tools 'tooling A'
Write-LfUtf8 "$tools/template.txt" "template B`n"
Write-LfUtf8 "$tools/packaging/Build-Snapshot.ps1" ($worker.Replace('worker A','worker B'))
$toolsB = Commit $tools 'tooling B'
Write-LfUtf8 "$root/firmware/Firmware.psd1" "@{ Name='FIXTURE' }`n"
$build = "$tools/packaging/Build-Package.ps1"
$settings = @{ SourceRepository=$app; FirmwareRoot="$root/firmware"; Dependencies="$root/deps"; WorkRoot="$root/work"; OutputRoot="$root/packages"; Ref=$appA; ToolingRef=$toolsA }
$first = & $build @settings | Select-Object -Last 1
$record = Get-Content -Raw -LiteralPath "$first/PACKAGE-VALIDATION.json" | ConvertFrom-Json
Check ($record.application -ceq 'application A' -and $record.sourceCommit -ceq $appA) 'selected application commit, not live HEAD, supplies source'
Check ($record.template -ceq 'template A' -and $record.worker -ceq 'worker A' -and $record.toolingCommit -ceq $toolsA) 'selected tooling supplies worker and template, not live HEAD'
$settings.ToolingRef = $toolsB
$second = & $build @settings | Select-Object -Last 1
Check ($first -ne $second) 'different tooling commits give different package names'
$archived = Join-Path "$root/packages/Archive" (Split-Path -Leaf $first)
Check (Test-Path -LiteralPath "$archived/PACKAGE-VALIDATION.json") 'previous package is preserved in the archive'
$settings.ToolingRef = 'missing-tool-ref'
Refuses { & $build @settings } 'Tooling repository' 'missing tooling ref refused'
$settings.ToolingRef = $toolsB; $settings.Ref = 'missing-app-ref'
Refuses { & $build @settings } 'Application repository' 'missing application ref refused'
$settings.Ref = $appA
Write-LfUtf8 "$app/untracked.txt" 'dirty'
Refuses { & $build @settings } 'Application repository.*clean' 'untracked application source refused'
Remove-Item -LiteralPath "$app/untracked.txt"
Write-LfUtf8 "$app/value.txt" 'dirty tracked source'
Refuses { & $build @settings } 'Application repository.*clean' 'tracked application modification refused'
GitAt $app @('restore','--','value.txt') | Out-Null
Write-LfUtf8 "$tools/template.txt" 'dirty template'
Refuses { & $build @settings } 'Tooling repository.*clean' 'dirty tooling refused'
GitAt $tools @('restore','--','template.txt') | Out-Null
foreach ($repo in @($app,$tools)) {
    $settings.WorkRoot = Join-Path $repo 'scratch'
    Refuses { & $build @settings } 'paths must be separate' 'scratch inside a source repository refused'
}
$settings.WorkRoot = $root
Refuses { & $build @settings } 'paths must be separate' 'scratch owning both repositories refused'
$settings.WorkRoot = "$root/work"
$settings.OutputRoot = "$root/work/packages"
Refuses { & $build @settings } 'paths must be separate' 'output inside scratch refused'
if ($IsWindows) {
    $link = Join-Path $root 'linked workspace'
    New-Item -ItemType Junction -Path $link -Target $app | Out-Null
    $settings.OutputRoot = Join-Path $link 'packages'
    Refuses { & $build @settings } 'links or junctions' 'junction into a source checkout refused'
    Remove-Item -LiteralPath $link -Force
}
Write-Host "Source export contracts: $checks checks passed. Fixtures: $root"
