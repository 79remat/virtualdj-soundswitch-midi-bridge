<#
.SYNOPSIS
  Generates vdj-files/Pads/DMX - Static Scenes.xml from the $pads table below.

.WHY THIS EXISTS
  Each pad's VDJScript action has to explicitly list every *other* pad's
  MIDI code to be able to clear it on press (SoundSwitch 2.11 made static
  scenes stackable instead of auto-exclusive, so VDJ has to enforce
  one-at-a-time itself now). VDJScript doesn't support building a value
  like "01004" dynamically from a variable at runtime -- every attempt at
  that failed or is undocumented -- so the N-way branch per pad is
  generated here instead of hand-written/hand-edited in the XML.

  Never hand-edit the generated XML directly. Add/change pads in the
  $pads table below and re-run this script.

.HOW THE ACTION IS STRUCTURED (per pad X)
  1. Outermost guard: if $sceneLock is set, do nothing. This debounces
     fast/overlapping pad presses -- without it, a second press fired
     while the first press's ~550ms action is still running can read a
     stale $activeScene and clear the wrong pad. See commit history for
     the bug this fixed.
  2. If $activeScene == X: this pad is already active, so just turn it
     off (pulse its own code once).
  3. Else, one branch per other pad O: if $activeScene == O, activate X
     first (pulse X's code), THEN clear O (pulse O's code). New-before-old
     ordering matters -- clearing old first leaves a visible gap where
     SoundSwitch falls back to the running autoloop before the new scene
     appears.
  4. Default (nothing was active): just activate X.
  Every ternary branch is a flat &-chain of simple actions with no
  trailing continuation after a nested ternary -- that's the one pattern
  confirmed safe in VDJScript; anything cleverer than that broke in
  practice.

.USAGE
  pwsh -File tools/build-static-scenes-page.ps1
  Then run tools/install.ps1 as usual to deploy into VirtualDJ.
#>

$pads = @(
  @{n=1; name="White Out"; color="white"},
  @{n=2; name="Red Alert"; color="red"},
  @{n=3; name="UV"; color="violet"},
  @{n=4; name="Blackout"; color="white"},
  @{n=5; name="Fade"; color="marine"},
  @{n=6; name="Home"; color="Orange"},
  @{n=7; name=""; color="yellow"},
  @{n=8; name="Blackout"; color="red"}
)

function Pulse($code) {
  $c = "0100$code"
  return "set '`$midiVariable' $c & wait 250ms & set '`$midiVariable' 0"
}

function BuildAction($x) {
  $others = $pads.n | Where-Object { $_ -ne $x }
  $lockOn = "set '`$sceneLock' 1 & "
  $lockOff = " & set '`$sceneLock' 0"

  # self-press while already active -> just turn it off
  $expr = "var '`$activeScene' $x ? $lockOn set '`$activeScene' 0 & $(Pulse $x)$lockOff : "

  # one branch per other pad: activate X first, then clear whichever was active
  $chain = ""
  foreach ($o in $others) {
    $chain += "var '`$activeScene' $o ? $lockOn $(Pulse $x) & set '`$activeScene' $x & $(Pulse $o)$lockOff : "
  }

  # default: nothing was active, just activate X
  $chain += "$lockOn $(Pulse $x) & set '`$activeScene' $x$lockOff"

  # outermost debounce guard
  return "var '`$sceneLock' 1 ? nothing : $expr$chain"
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<page name="DMX - Static Scenes">')
foreach ($p in $pads) {
  $action = BuildAction $p.n
  $actionEsc = [System.Security.SecurityElement]::Escape($action)
  $colorExpr = "var '`$activeScene' $($p.n) ? color '$($p.color)' : color 50% '$($p.color)'"
  $colorEsc = [System.Security.SecurityElement]::Escape($colorExpr)
  $nameAttr = if ($p.name) { " name=`"$($p.name)`"" } else { "" }
  [void]$sb.AppendLine("`t<pad$($p.n)$nameAttr color=`"$colorEsc`" autodim=`"false`">$actionEsc</pad$($p.n)>")
}
[void]$sb.AppendLine("`t<menu>DMX Scenes =[os2l_info]</menu>")
[void]$sb.AppendLine('</page>')

$repoRoot = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $repoRoot "vdj-files\Pads\DMX - Static Scenes.xml"
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
"Wrote $outPath"

[xml]$check = Get-Content -LiteralPath $outPath -Raw
"XML parses OK, pad count: $($check.page.ChildNodes.Count)"
