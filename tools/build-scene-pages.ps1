<#
.SYNOPSIS
  Generates all exclusive/debounced static-scene pad pages from the
  $pages table below.

.WHY THIS EXISTS
  See the header this replaced (build-static-scenes-page.ps1) for the
  full story. Short version: SoundSwitch 2.11 made static scenes
  stackable instead of auto-exclusive, VDJScript can't build a MIDI
  code dynamically from a variable at runtime, so each pad's action has
  to spell out every other pad's code by hand -- generated here instead
  of hand-edited in the XML.

  Each page gets its own $activeScene/$sceneLock variable pair so pages
  are independently exclusive (pressing a pad on one page never clears
  a pad on another page -- that's a known, accepted limitation, not a
  bug: VDJScript can't cheaply check all pads across all pages either).

  Never hand-edit the generated XML directly. Add/change pads or pages
  in the $pages table below and re-run this script.

.ACTION STRUCTURE (per pad X on a page)
  1. Outermost guard: if the page's $sceneLock is set, do nothing. This
     debounces fast/overlapping presses -- without it, a second press
     fired while the first press's ~550ms action is still running can
     read a stale $activeScene and clear the wrong pad.
  2. If $activeScene == X: already active, just turn it off.
  3. Else, one branch per other pad O: if $activeScene == O, activate X
     FIRST (pulse X), then clear O (pulse O). New-before-old ordering
     matters -- clearing old first leaves a visible gap where
     SoundSwitch falls back to the running autoloop before the new
     scene appears.
  4. Default (nothing was active): just activate X.
  Every ternary branch is a flat &-chain of simple actions with no
  trailing continuation after a nested ternary -- the one pattern
  confirmed safe in VDJScript.

.USAGE
  pwsh -File tools/build-scene-pages.ps1
  Then run tools/install.ps1 as usual to deploy into VirtualDJ.
#>

$pages = @(
  @{
    file = "DMX - Static Scenes.xml"
    name = "DMX - Static Scenes"
    varSuffix = ""   # uses $activeScene / $sceneLock
    pads = @(
      @{n=1; name="White Out"; color="white"},
      @{n=2; name="Red Alert"; color="red"},
      @{n=3; name="UV"; color="violet"},
      @{n=4; name="Blackout"; color="white"},
      @{n=5; name="Fade"; color="marine"},
      @{n=6; name="Home"; color="Orange"},
      @{n=7; name=""; color="yellow"},
      @{n=8; name="Blackout"; color="red"}
    )
    codeOffset = 0   # pad1 -> code 01001
  },
  @{
    file = "DMX - Performance Mode.xml"
    name = "DMX - Performance Mode"
    varSuffix = "Perf"   # uses $activeScenePerf / $sceneLockPerf
    pads = @(
      @{n=1; name="scene 9";  color="red"},
      @{n=2; name="scene 10"; color="blue"},
      @{n=3; name="scene 11"; color="green"},
      @{n=4; name="scene 12"; color="white"},
      @{n=5; name="scene 13"; color="cyan"},
      @{n=6; name="scene 14"; color="magenta"},
      @{n=7; name="scene 15"; color="yellow"},
      @{n=8; name="scene 16"; color="orange"}
    )
    codeOffset = 8   # pad1 -> code 01009
  }
)

function Pulse($varName, $padNum, $codeOffset) {
  $code = "0100{0}" -f ($padNum + $codeOffset)
  return "set '`$midiVariable' $code & wait 250ms & set '`$midiVariable' 0"
}

function BuildAction($pads, $x, $activeVar, $lockVar, $codeOffset) {
  $others = $pads.n | Where-Object { $_ -ne $x }
  $lockOn = "set '`$$lockVar' 1 & "
  $lockOff = " & set '`$$lockVar' 0"

  $expr = "var '`$$activeVar' $x ? $lockOn set '`$$activeVar' 0 & $(Pulse $activeVar $x $codeOffset)$lockOff : "

  $chain = ""
  foreach ($o in $others) {
    $chain += "var '`$$activeVar' $o ? $lockOn $(Pulse $activeVar $x $codeOffset) & set '`$$activeVar' $x & $(Pulse $activeVar $o $codeOffset)$lockOff : "
  }

  $chain += "$lockOn $(Pulse $activeVar $x $codeOffset) & set '`$$activeVar' $x$lockOff"

  return "var '`$$lockVar' 1 ? nothing : $expr$chain"
}

$repoRoot = Split-Path -Parent $PSScriptRoot

foreach ($page in $pages) {
  $activeVar = "activeScene$($page.varSuffix)"
  $lockVar = "sceneLock$($page.varSuffix)"

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
  [void]$sb.AppendLine("<page name=`"$($page.name)`">")
  foreach ($p in $page.pads) {
    $action = BuildAction $page.pads $p.n $activeVar $lockVar $page.codeOffset
    $actionEsc = [System.Security.SecurityElement]::Escape($action)
    $colorExpr = "var '`$$activeVar' $($p.n) ? color '$($p.color)' : color 50% '$($p.color)'"
    $colorEsc = [System.Security.SecurityElement]::Escape($colorExpr)
    $nameAttr = if ($p.name) { " name=`"$($p.name)`"" } else { "" }
    [void]$sb.AppendLine("`t<pad$($p.n)$nameAttr color=`"$colorEsc`" autodim=`"false`">$actionEsc</pad$($p.n)>")
  }
  [void]$sb.AppendLine("`t<menu>DMX Scenes =[os2l_info]</menu>")
  [void]$sb.AppendLine('</page>')

  $outPath = Join-Path $repoRoot "vdj-files\Pads\$($page.file)"
  [System.IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
  "Wrote $outPath"

  [xml]$check = Get-Content -LiteralPath $outPath -Raw
  "  XML parses OK, pad count: $($check.page.ChildNodes.Count)"
}
