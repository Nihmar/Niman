# Runs the suite and reports only what is NOT already known to fail here.
#
# Windows fails a fixed set of tests for reasons that have nothing to do
# with the code (path separators, temp-dir cleanup, a 10k-note fixture
# that times out). Reading a raw run means re-deciding every time which
# of ~25 red lines matter. This compares against scripts/known-failures.txt
# and prints the difference, so "no new failures" is one line instead of a
# judgement call.
#
#   pwsh scripts/newfail.ps1            run everything
#   pwsh scripts/newfail.ps1 test/widget  run a subset
#   pwsh scripts/newfail.ps1 -Update     rewrite the baseline from this run
#
# Exit code 0 when nothing new failed, 1 otherwise.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Paths,
    [switch] $Update
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$baselineFile = Join-Path $PSScriptRoot 'known-failures.txt'
$logDir = Join-Path $env:TEMP 'copist'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir 'copist-newfail.log'

Push-Location $root
try {
    $args = @('test', '--reporter', 'failures-only') + $Paths
    & flutter @args 2>&1 | Out-File $log -Encoding utf8
} finally {
    Pop-Location
}

# A failure line ends in "[E]" and names the file and the test. Keep both,
# since the same test name can exist in two files.
#
# The reporter prefixes each line with a running "+N -M: " counter, and
# omits the file path when the run covers a single file. Strip the counter
# either way; a line left without a path is matched by its tail below.
$failed = Select-String -Path $log -Pattern '\[E\]$' |
    ForEach-Object {
        ($_.Line -replace '^.*?Copist[/\\]', '' -replace '^\s*\+\d+(\s+-\d+)?:\s*', '').Trim()
    } |
    Sort-Object -Unique

$summary = (Get-Content $log | Where-Object { $_ -match '^\s*\+\d+' } | Select-Object -Last 1)
if ($summary) { Write-Host $summary.Trim() }

# Baseline lines: '#' is a comment, '~' marks a test that fails only
# sometimes (a flake). Both survive -Update, since a run where the flake
# happened to pass would otherwise drop it and the next flake would be
# reported as a regression.
$kept = @()
if (Test-Path $baselineFile) {
    $kept = Get-Content $baselineFile |
        Where-Object { $_.StartsWith('#') -or $_.StartsWith('~') }
}

if ($Update) {
    $steady = @($failed | Where-Object { "~$_" -notin $kept })
    ($kept + $steady) | Set-Content $baselineFile -Encoding utf8
    $flakyCount = ($kept | Where-Object { $_.StartsWith('~') }).Count
    Write-Host "baseline updated: $($steady.Count) steady + $flakyCount flaky"
    exit 0
}

$known = @()
if (Test-Path $baselineFile) {
    $known = Get-Content $baselineFile |
        Where-Object { $_.Trim() -ne '' -and -not $_.StartsWith('#') } |
        ForEach-Object { $_.TrimStart('~') }
}

# A single-file run reports the test without its path, so a baseline entry
# matches when it ends with the reported line.
$new = @($failed | Where-Object {
    $line = $_
    -not ($known | Where-Object { $_ -eq $line -or $_.EndsWith(": $line") })
})
# Only meaningful on a full run: a subset never exercises the rest.
$fixed = @()
if (-not $Paths) {
    $steadyKnown = @(
        Get-Content $baselineFile |
            Where-Object { $_.Trim() -ne '' -and -not ($_.StartsWith('#') -or $_.StartsWith('~')) }
    )
    $fixed = @($steadyKnown | Where-Object { $failed -notcontains $_ })
}

if ($new.Count -gt 0) {
    Write-Host ''
    Write-Host "NEW FAILURES ($($new.Count)):"
    $new | ForEach-Object { Write-Host "  $_" }
}
if ($fixed.Count -gt 0) {
    Write-Host ''
    Write-Host "known failures that passed this run ($($fixed.Count)):"
    $fixed | ForEach-Object { Write-Host "  $_" }
}
if ($new.Count -eq 0) {
    Write-Host ''
    Write-Host 'No new failures.'
}
Write-Host "full log: $log"
exit ($(if ($new.Count -gt 0) { 1 } else { 0 }))
