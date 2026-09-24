# Send test MIDI to the loopMIDI port. Usage: pwsh midisend.ps1 -Type Note|CC -Number 60 [-Channel 1] [-Count 3] [-HoldMs 300] [-GapMs 1500]
param([ValidateSet('Note','CC')][string]$Type='Note',[int]$Number=60,[int]$Channel=1,[int]$Count=3,[int]$HoldMs=300,[int]$GapMs=1500,[string]$Port='VirtualDJ_to_SoundSwitch')
$code=@'
using System;
using System.Runtime.InteropServices;
public class MidiSend {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
  public struct MIDIOUTCAPS { public ushort wMid; public ushort wPid; public uint vDriverVersion; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string szPname; public ushort wTechnology; public ushort wVoices; public ushort wNotes; public ushort wChannelMask; public uint dwSupport; }
  [DllImport("winmm.dll")] static extern uint midiOutGetNumDevs();
  [DllImport("winmm.dll", CharSet=CharSet.Auto)] static extern uint midiOutGetDevCaps(UIntPtr id, ref MIDIOUTCAPS c, uint sz);
  [DllImport("winmm.dll")] static extern uint midiOutOpen(out IntPtr h, uint id, IntPtr cb, IntPtr inst, uint flags);
  [DllImport("winmm.dll")] static extern uint midiOutShortMsg(IntPtr h, uint msg);
  [DllImport("winmm.dll")] static extern uint midiOutClose(IntPtr h);
  static IntPtr h;
  public static string Open(string name){ uint n=midiOutGetNumDevs(); for(uint i=0;i<n;i++){ var c=new MIDIOUTCAPS(); midiOutGetDevCaps((UIntPtr)i, ref c, (uint)Marshal.SizeOf(c)); if(c.szPname==name){ uint r=midiOutOpen(out h,i,IntPtr.Zero,IntPtr.Zero,0); return r==0?"OK":"midiOutOpen failed: "+r; } } return "port not found: "+name; }
  public static void Send(byte st, byte a, byte b){ midiOutShortMsg(h, (uint)(st | (a<<8) | (b<<16))); }
  public static void Close(){ midiOutClose(h); }
}
'@
Add-Type -TypeDefinition $code
$r=[MidiSend]::Open($Port); if($r -ne 'OK'){ "SENDER: $r"; exit 2 }
$ch=$Channel-1
for($i=1;$i -le $Count;$i++){
  if($Type -eq 'Note'){ [MidiSend]::Send([byte](0x90+$ch),[byte]$Number,127); "SENDER: $i/$Count NoteOn ch$Channel note $Number"; Start-Sleep -Milliseconds $HoldMs; [MidiSend]::Send([byte](0x80+$ch),[byte]$Number,0) }
  else { [MidiSend]::Send([byte](0xB0+$ch),[byte]$Number,127); "SENDER: $i/$Count CC ch$Channel cc $Number = 127"; Start-Sleep -Milliseconds $HoldMs; [MidiSend]::Send([byte](0xB0+$ch),[byte]$Number,0) }
  Start-Sleep -Milliseconds $GapMs
}
[MidiSend]::Close(); "SENDER: done."
