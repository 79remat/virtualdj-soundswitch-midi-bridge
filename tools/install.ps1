# Copies the VirtualDJ files from vdj-files/ into your VirtualDJ folder.
# It only copies files. It never overwrites anything unless you pass -Force.
# Usage: pwsh install.ps1 [-VdjFolder 'C:\Users\<you>\AppData\Local\VirtualDJ'] [-Force]
param([string]$VdjFolder = "$env:LOCALAPPDATA\VirtualDJ", [switch]$Force)

$src = Join-Path $PSScriptRoot '..\vdj-files'
if (-not (Test-Path $VdjFolder)) { "VirtualDJ folder not found: $VdjFolder  (pass -VdjFolder to point at it)"; exit 1 }

$files = Get-ChildItem $src -Recurse -File
$clashes = $files | Where-Object { Test-Path (Join-Path $VdjFolder $_.FullName.Substring((Resolve-Path $src).Path.Length + 1)) }
if ($clashes -and -not $Force) {
  "These files already exist in your VirtualDJ folder. Nothing was copied:"
  $clashes | ForEach-Object { "  " + $_.Name }
  "Back them up, then run again with -Force to overwrite."
  exit 1
}

foreach ($f in $files) {
  $rel = $f.FullName.Substring((Resolve-Path $src).Path.Length + 1)
  $dest = Join-Path $VdjFolder $rel
  New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
  Copy-Item $f.FullName $dest -Force
  "copied  $rel"
}
""
"Done. Next: make sure loopMIDI has a port named exactly 'VirtualDJ_to_SoundSwitch', then restart VirtualDJ."
