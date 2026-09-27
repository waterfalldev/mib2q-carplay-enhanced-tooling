# Repository selection and exports; no compilation or network access.
function Get-BuildPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Build path must not be empty.' }
    $full = [IO.Path]::GetFullPath($Path)
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Build paths must not traverse links or junctions: $cursor"
            }
        }
        $cursor = Split-Path -Parent $cursor
    }
    return $full
}

function Assert-SeparateBuildPaths {
    param([string]$First, [string]$Second)
    $separator = [IO.Path]::DirectorySeparatorChar
    $a = (Get-BuildPath $First).TrimEnd($separator) + $separator
    $b = (Get-BuildPath $Second).TrimEnd($separator) + $separator
    $comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
    if ($a.StartsWith($b, $comparison) -or $b.StartsWith($a, $comparison)) {
        throw "Build paths must be separate (neither ancestors nor descendants): $First ; $Second"
    }
}

function Get-BuildRepository {
    param([string]$Path, [string]$Ref, [string]$Description)
    $path = Get-BuildPath $Path
    $git = (Get-Command git -ErrorAction Stop).Source
    $arguments = @('-c', ('safe.directory=' + $path.Replace('\','/')), '-C', $path)
    try {
        $root = @(Invoke-Native -Exe $git -Arguments ($arguments + @('rev-parse','--show-toplevel')) -Capture)[0]
        $root = Get-BuildPath $root
        if ($root -ne $path.TrimEnd([IO.Path]::DirectorySeparatorChar)) { throw 'Supply the repository root, not a subdirectory.' }
        $dirty = @(Invoke-Native -Exe $git -Arguments ($arguments + @('status','--porcelain','--untracked-files=normal')) -Capture)
        if ($dirty.Count) { throw 'Checkout must be clean before preparing a release package.' }
        $commit = @(Invoke-Native -Exe $git -Arguments ($arguments + @('rev-parse','--verify','--end-of-options',($Ref + '^{commit}'))) -Capture)[0].Trim()
        if ($commit -notmatch '^[0-9a-f]{40}$') { throw 'Ref did not resolve to a full Git commit.' }
        return [pscustomobject]@{ Root=$root; Commit=$commit; Git=$git; Arguments=$arguments }
    } catch { throw "$Description repository '$path' (ref '$Ref'): $_" }
}

function Export-BuildRepository {
    param($Repository, [string]$RunRoot, [string]$Name)
    if ($Name -notin @('application','tooling')) { throw 'Unknown source export name.' }
    $destination = Join-Path $RunRoot $Name
    Assert-SafeChildPath -Root $RunRoot -Candidate $destination -Description 'source export'
    New-Item -ItemType Directory -Path $destination | Out-Null
    $archive = Join-Path $RunRoot ($Name + '.tar')
    Invoke-Native -Exe $Repository.Git -Arguments ($Repository.Arguments + @('-c','core.autocrlf=false','archive','--format=tar',('--output=' + $archive),$Repository.Commit))
    $tar = (Get-Command tar -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    Push-Location -LiteralPath $RunRoot
    try { Invoke-Native -Exe $tar -Arguments @('-xf',($Name + '.tar'),'-C',$Name) } finally { Pop-Location }
    return $destination
}
