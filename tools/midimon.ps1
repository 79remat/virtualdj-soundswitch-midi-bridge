# Passive MIDI listener for the loopMIDI port. Usage: pwsh midimon.ps1 [-Seconds 30] [-Port 'VirtualDJ_to_SoundSwitch']
param([int]$Seconds = 30, [string]$Port = 'VirtualDJ_to_SoundSwitch')
$code = @'
using System;
using System.Collections.Concurrent;
using System.Runtime.InteropServices;
public class MidiMon {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
  public struct MIDIINCAPS { public ushort wMid; public ushort wPid; public uint vDriverVersion; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string szPname; public uint dwSupport; }
  public delegate void MidiInProc(IntPtr h, uint msg, UIntPtr inst, UIntPtr p1, UIntPtr p2);
  [DllImport("winmm.dll")] static extern uint midiInGetNumDevs();
  [DllImport("winmm.dll", CharSet=CharSet.Auto)] static extern uint midiInGetDevCaps(UIntPtr id, ref MIDIINCAPS c, uint sz);
  [DllImport("winmm.dll")] static extern uint midiInOpen(out IntPtr h, uint id, MidiInProc cb, UIntPtr inst, uint flags);
  [DllImport("winmm.dll")] static extern uint midiInStart(IntPtr h);
  [DllImport("winmm.dll")] static extern uint midiInStop(IntPtr h);
  [DllImport("winmm.dll")] static extern uint midiInClose(IntPtr h);
  public static ConcurrentQueue<string> Q = new ConcurrentQueue<string>();
  static MidiInProc cb = OnMsg; static IntPtr h;
  static void OnMsg(IntPtr hh, uint msg, UIntPtr inst, UIntPtr p1, UIntPtr p2) {
    if (msg != 0x3C3) return; // MIM_DATA
    uint d = (uint)p1; byte st = (byte)(d & 0xFF), a = (byte)((d >> 8) & 0xFF), b = (byte)((d >> 16) & 0xFF);
    if (st >= 0xF8) return; // ignore realtime clock
    string kind = (st & 0xF0) == 0x90 ? (b == 0 ? "NoteOff(v0)" : "NoteOn") : (st & 0xF0) == 0x80 ? "NoteOff" : (st & 0xF0) == 0xB0 ? "CC" : "Other";
    Q.Enqueue(string.Format("{0:HH:mm:ss.fff}  {1,-11} ch{2} data1={3} data2={4}   (raw {5:X2} {6:X2} {7:X2})", DateTime.Now, kind, (st & 0x0F) + 1, a, b, st, a, b));
  }
  public static string Open(string name) {
    uint n = midiInGetNumDevs();
    for (uint i = 0; i < n; i++) { var c = new MIDIINCAPS(); midiInGetDevCaps((UIntPtr)i, ref c, (uint)Marshal.SizeOf(c));
      if (c.szPname == name) { uint r = midiInOpen(out h, i, cb, UIntPtr.Zero, 0x30000); if (r != 0) return "midiInOpen failed: " + r; midiInStart(h); return "OK"; } }
    return "port not found: " + name;
  }
  public static void Close() { midiInStop(h); midiInClose(h); }
}
'@
Add-Type -TypeDefinition $code
$r = [MidiMon]::Open($Port)
if ($r -ne 'OK') { "LISTENER: $r"; exit 2 }
"LISTENER: open on '$Port' for $Seconds s. Waiting for MIDI..."
$end = (Get-Date).AddSeconds($Seconds); $count = 0
while ((Get-Date) -lt $end) { $s = $null; while ([MidiMon]::Q.TryDequeue([ref]$s)) { $s; $count++ }; Start-Sleep -Milliseconds 20 }
[MidiMon]::Close()
"LISTENER: done. $count message(s) captured."
