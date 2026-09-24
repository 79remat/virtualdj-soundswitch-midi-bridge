# VirtualDJ → SoundSwitch MIDI Bridge

![VirtualDJ DMX pads → loopMIDI → SoundSwitch scenes and autoloops](assets/banner-chat.png)

Trigger SoundSwitch static looks and autoloops from VirtualDJ pads, over a
plain virtual MIDI cable. Includes 2 ready-made pad pages (8 static looks and
8 autoloops), plus a guide to making buttons on your own DJ controller
fire lights too.

## What's in here

```
vdj-files/
  Devices/loopMidi 1.xml              the virtual MIDI device definition
  Mappers/loopMidi1_mapper.xml        translates variable changes into MIDI notes
  Pads/DMX - Static Scenes.xml        8 pads for SoundSwitch static looks
  Pads/DMX - Autoloops.xml            8 pads for SoundSwitch autoloops
tools/
  midimon.ps1                         listens on the MIDI port, prints what arrives
  midisend.ps1                        sends test MIDI notes on demand
  install.ps1                         copies vdj-files/ into your VirtualDJ folder
```

---

## Easy way: use Claude Code

Install [Claude Code](https://claude.com/product/claude-code), open it in this
repo's folder, and paste in the prompt below. Claude will do the setup for you.

Here's a prompt to get Claude to do it for you:

```
Set up this repo so my VirtualDJ pads can trigger SoundSwitch lighting
scenes and autoloops over MIDI. Read README.md first so you know how it works.

Do it in this order:

1. Find my VirtualDJ data folder (usually %LOCALAPPDATA%\VirtualDJ). Tell me
   the path you found.
2. Check whether loopMIDI is installed and has a port named exactly
   "VirtualDJ_to_SoundSwitch" (case-sensitive). If it doesn't, tell me how to
   install loopMIDI and create the port.
3. Build the three VirtualDJ files by following the "Build the files
   yourself" section of README.md, using the files in vdj-files/ as the
   reference:
   - a device file in Devices/ for the VirtualDJ_to_SoundSwitch port
   - a mapper in Mappers/ that sends a MIDI note when $midiVariable
     changes
   - the "DMX - Static Scenes" and "DMX - Autoloops" pad pages in Pads/
   If a file with the same name already exists, back it up first. Explain
   what each file does as you write it.
4. Tell me what to click in VirtualDJ (Settings > Controllers) so the
   loopMidi1_mapper is assigned to the VirtualDJ_to_SoundSwitch device, and
   how to put the "DMX - Static Scenes" and "DMX - Autoloops" pad pages on
   a deck.
5. Run tools/midimon.ps1 and have me press one pad in VirtualDJ. Confirm a
   Note On/Off really comes through. If nothing arrives, help me fix it
   before moving on.
6. Walk me through enabling VirtualDJ_to_SoundSwitch as a MIDI input in
   SoundSwitch and MIDI-learning pad 1 onto a static look and one autoloop
   pad onto an autoloop. Then I'll do the other pads myself.
7. Ask me if I want any buttons on my DJ controller to fire lights too. If I
   do, follow "Adding MIDI to a controller button you already use" in
   README.md: add the new note to the loopMIDI device and mapper first,
   then walk me through editing that button in Settings > Controllers so
   it keeps its normal job.

Don't make up VirtualDJ script actions. If you're not sure about one, check
the files in this repo.
```

## Script way

`tools/install.ps1` copies the files from `vdj-files/` into your VirtualDJ
folder. It's about 25 lines. **Read it before you run it.** You should do
that with any script from the internet, including this one. It only
copies files. If any of them already exist it copies nothing and lists
them instead, unless you add `-Force`.

```powershell
cd tools
.\install.ps1                                   # uses %LOCALAPPDATA%\VirtualDJ
.\install.ps1 -VdjFolder "D:\My VirtualDJ"       # if yours is somewhere else
```

It doesn't install loopMIDI or change any settings. After it finishes, do
steps 1 and 3–7 from the manual guide below.

## Manual way (step by step)

**Step 1: Install loopMIDI and create the port**
1. Download and install [loopMIDI](https://www.tobias-erichsen.de/software/loopmidi.html).
2. Open it, type `VirtualDJ_to_SoundSwitch` in the "New port-name" box, and
   click **+**. The name has to match exactly, including capital letters,
   because the device file is hard-wired to it.
3. Leave loopMIDI running. The port only exists while it's open.

**Step 2: Copy the files into VirtualDJ**

(Want to understand them, or build them from scratch? See
[Build the files yourself](#build-the-files-yourself).)

Open your VirtualDJ folder (paste `%LOCALAPPDATA%\VirtualDJ` into File
Explorer's address bar) and copy:

| From this repo | Into |
|---|---|
| `vdj-files/Devices/loopMidi 1.xml` | `VirtualDJ\Devices\` |
| `vdj-files/Mappers/loopMidi1_mapper.xml` | `VirtualDJ\Mappers\` |
| both files in `vdj-files/Pads/` | `VirtualDJ\Pads\` |

If Windows asks to replace a file, back up the old one first.

**Step 3: Check the controller in VirtualDJ**
1. Start (or restart) VirtualDJ.
2. Go to **Settings → Controllers**.
3. `VirtualDJ_to_SoundSwitch` should be in the list with `loopMidi1_mapper`
   selected. If it isn't selected, pick it from the dropdown.

**Step 4: Show the pads**
1. On a deck's pad panel, open the pad-page dropdown.
2. Pick `DMX - Static Scenes` for static looks, or `DMX - Autoloops` for
   autoloops.

**Step 5: Test that MIDI is coming out**

Do this before you open SoundSwitch, so you know VirtualDJ is working.
1. Open PowerShell in the `tools/` folder and run `.\midimon.ps1`.
2. Press a pad in VirtualDJ.
3. You should see a `NoteOn` line followed by a `NoteOff` line. If nothing
   shows up, go back over steps 1–4. The problem is on the VirtualDJ side.

**Step 6: Turn on the MIDI input in SoundSwitch**

In SoundSwitch's MIDI settings, enable `VirtualDJ_to_SoundSwitch` as an
input device.

**Step 7: Map each pad**
1. In SoundSwitch, open the **Static Looks** tab and right-click a look to
   start MIDI Learn.
2. Press the pad you want for it on the `DMX - Static Scenes` page in
   VirtualDJ.
3. Check that SoundSwitch has learned it (the look stops blinking).
4. Do the same in the **Autoloops** tab, using the `DMX - Autoloops` pads.
5. Repeat for as many of the 16 pads as you want.

**Step 8 (optional): Controller buttons**

To make a button on your DJ controller fire lights too, see
[Adding MIDI to a controller button you already use](#adding-midi-to-a-controller-button-you-already-use).

## Build the files yourself

There are three parts. It helps to know one thing first: VirtualDJ has no
"send MIDI" script command. Instead, it sends a MIDI note out whenever an
**LED** on a device turns on or off. So you define a fake device whose
"LEDs" are really MIDI notes, and light them up from a pad.

```
pad pressed ─► $midiVariable = 01001 ─► mapper: LED_VAR01001 is now ON
            ─► VirtualDJ sends Note On 0x00 out of the loopMIDI port ─► SoundSwitch
```

### 1. The device file (`Devices/`)

This tells VirtualDJ the loopMIDI port exists and which notes it can send.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<device name="VirtualDJ_to_SoundSwitch" drivername="VirtualDJ_to_SoundSwitch"
        type="MIDI" output="yes" decks="2" version="802">
  <!-- inputs: notes that come back in on the port (loopMIDI echoes them) -->
  <button note="0x00" name="PAD1" channel="00"/>

  <!-- outputs: one LED per note you want to send -->
  <led note="0x00" name="LED_VAR01001" channel="00"/>
  <led note="0x01" name="LED_VAR01002" channel="00"/>
</device>
```

- `drivername` has to be **exactly** the loopMIDI port name.
- `output="yes"` lets VirtualDJ send on it.
- `channel="00"` is MIDI channel 1.
- Each `<led>` is one note. The name can be anything, but naming it after
  its value (`LED_VAR01001`) keeps things readable.

### 2. The mapper (`Mappers/`)

This says *when* each LED is on.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mapper device="VirtualDJ_to_SoundSwitch" version="850">
  <!-- ignore the echo, so it doesn't trigger anything on your decks -->
  <map value="PAD1" action="nothing" />

  <!-- LED is ON (note sent) while $midiVariable equals this value -->
  <map value="LED_VAR01001" action="var '$midiVariable' 01001" />
  <map value="LED_VAR01002" action="var '$midiVariable' 01002" />
</mapper>
```

- `device` must match the device file's `name`.
- An LED's action is checked constantly. When
  `var '$midiVariable' 01001` becomes true, VirtualDJ sends Note On 0x00.
  When it becomes false again, it sends Note Off.
- VirtualDJ writes `'` as `&apos;` when it saves the file. Both work.

### 3. The pad page (`Pads/`)

Each pad sets the variable, waits briefly, then clears it. That makes one
Note On/Off "press" that SoundSwitch can learn.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<page name="DMX - Static Scenes">
  <pad1 name="scene 1" color="color 'red'">set '$midiVariable' 01001 &amp; wait 250ms &amp; set '$midiVariable' 0</pad1>
  <pad2 name="scene 2" color="color 'blue'">set '$midiVariable' 01002 &amp; wait 250ms &amp; set '$midiVariable' 0</pad2>
  <!-- ...up to pad8 -->
</page>
```

`&` means "and then". Inside XML it has to be written as `&amp;`.

**To add a new trigger,** pick the next free value, then add it in all
three places: an `<led>` in the device file, a `<map>` in the mapper, and a
pad (or a controller button, see below) that sets that value. Restart
VirtualDJ afterwards.

### Note/value reference (all on MIDI channel 1)

| Note (dec) | Note (hex) | Value | Used by |
|---|---|---|---|
| 0–7 | `0x00`–`0x07` | `01001`–`01008` | `DMX - Static Scenes` pads 1–8 (static looks) |
| 8–15 | `0x08`–`0x0F` | `01009`–`01016` | `DMX - Autoloops` pads 1–8 (autoloops) |

The next free slot is `0x10` / `01017`.

## Adding MIDI to a controller button you already use

The DMX pads above only need the three files. A **physical button** on your
DJ controller is different: it already has a job in the controller's own
mapping, so you add the MIDI trigger *onto* that job instead of replacing
it.

It works with any controller VirtualDJ supports. The button keeps doing
what it did before, and also fires a MIDI note to SoundSwitch.

**Step 1: Reserve a note for the button**

Take the next free value (`0x10` / `01017` if you haven't added any yet)
and add an `<led>` to the loopMIDI device file and a matching `<map>` to
its mapper, the same as for a pad:

```xml
<!-- Devices/loopMidi 1.xml -->
<led note="0x10" name="LED_VAR01017" channel="00"/>

<!-- Mappers/loopMidi1_mapper.xml -->
<map value="LED_VAR01017" action="var '$midiVariable' 01017" />
```

**Step 2: Find the button in VirtualDJ**
1. Go to **Settings → Controllers** and select your DJ controller (not
   `VirtualDJ_to_SoundSwitch`).
2. Press the button on the hardware. VirtualDJ highlights its key in the
   list. You can also type the key name in the search box.

**Step 3: Add the trigger to its action**

Click the action and add this to the **end**. Don't replace what's there:

```
& set '$midiVariable' 01017 & wait 250ms & set '$midiVariable' 0
```

So an action like `<existing action>` becomes:

```
<existing action> & set '$midiVariable' 01017 & wait 250ms & set '$midiVariable' 0
```

**Step 4: Save it as a custom mapping**

VirtualDJ saves your edit as a new mapping in `Mappers/`, next to the stock
one, so the original stays untouched. Keep that custom mapping selected for
your controller.

**Step 5: Test it**

Run `tools/midimon.ps1` and press the button. You should see Note On/Off
for its note, and the button should still do its normal job. Then
MIDI-learn it in SoundSwitch like a pad.

**Tips**
- If the button does different things in different modes, the trigger
  only fires in the mode whose action you edited. That's handy if you
  only want lights from it in one mode.
- Pick a button you don't need for anything critical mid-mix. The trigger
  fires every time you press it.

## Known limitations

- **VirtualDJ can't read SoundSwitch's state back.** If you build on/off
  toggle logic in VirtualDJ (see `DMX - Static Scenes.xml` for an example
  using a `$activeScene` variable), it's VirtualDJ's own memory of what you
  last pressed, not something confirmed by SoundSwitch. If a look changes by
  mouse inside SoundSwitch, VirtualDJ won't know.
- **Editing a pad's color through VirtualDJ's own Pads Editor UI** replaces
  the whole `color` script with a plain literal, silently deleting any
  conditional (dim/lit) logic that was there. If a pad gets stuck permanently
  lit after a color change, this is why.
- **loopMIDI is a loopback** — notes VirtualDJ sends come back in on the same
  port's MIDI input. If VirtualDJ has that port auto-assigned to a deck, add
  `nothing` maps for the device's button names (see `loopMidi1_mapper.xml`)
  so it doesn't fire hotcues/pads on your deck every time a light triggers.
