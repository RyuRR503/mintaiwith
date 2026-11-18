# Post-processes `forge flatten` output: drops leftover imports, removes source sections that were
# inlined twice under different paths, and shortens absolute local paths in the section headers.
param([string[]]$Files)

foreach ($file in $Files) {
    $lines = Get-Content $file
    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    $skip = $false
    foreach ($line in $lines) {
        if ($line -match '^// (\S+\.sol)$') {
            $path = $Matches[1] -replace '\\', '/'
            $key = $path -replace '^.*?/(lib|src)/', '$1/'
            if ($path -notmatch '^src/') { $key = 'dep:' + $key } else { $key = 'own:' + $path }
            $skip = $seen.ContainsKey($key)
            $seen[$key] = $true
            if (-not $skip) {
                $short = $path -replace '^.*?/contracts/fomo-countdown/', '../fomo-countdown/'
                $out.Add("// $short")
            }
            continue
        }
        if ($skip) { continue }
        if ($line -match '^\s*import\s') { continue }
        $out.Add($line)
    }
    [IO.File]::WriteAllLines((Resolve-Path $file), $out)
}
