# [CS:GO] - Soundmixer

## What's this?

TL;DR: Keeping track of users `snd_stream` setting and plays sounds either as .wav or .mp3

CS:GO has [poor sound support](https://wiki.alliedmods.net/CSGO_Quirks#Playing_Custom_Sounds) but recently a protected client ConVar [`snd_stream` got added](http://blog.counter-strike.net/index.php/2018/02/20090/) to the game. Protected meaning a server can't set this ConVar for clients, only clients can change it for themselves.

But what does `snd_stream` do? It bypasses the audiocache (i.e. streaming from disk) and allows to play .wav sounds without
the need for clients to run `snd_rebuildaudiocache`.

Why would I want to do this? There are 3 total channels you can use for mp3s and only 2 are actually usable. There are, on
the other hand, way more channels for wavs resulting in the possibility of playing multiple sounds concurrently without
one sound stopping the other.

CS:GO Soundmixer will keep track of client's `snd_stream` setting and provides natives for other plugins to use. It doesn't expose any ConVars or commands nor will it do anything on its own (it will track client's `snd_stream` setting but nothing more).

**NOTE:** The obvious drawback is that all sounds must be provided and downloaded in both formats. When [Volvo removes the audiocache](https://www.reddit.com/r/GlobalOffensive/comments/7xwgte/question_about_the_new_convar_snd_stream/duda0k5/?context=3)
alltogether this plugins becomes useless but you then can force WAV only, see documentation for `SMix_ForceFormatAll`.


## Implementing

You will need to run `csgo_soundmixer.smx` plugin and then `#include <csgo_soundmixer>` in your plugin. Then use the natives
as documented below. Note that this plugin is only designed for CS:GO and you will need to make the usage of this plugin optional
if you intend to release a multi-game plugin.

As csgo_soundmixer is a required plugin for the usage in other plugins you may package it with your plugin (MIT license afterall).

Also take a look at the [testing plugin](https://github.com/2called-chaos/csgo_soundmixer/blob/master/addons/sourcemod/scripting/csgo_smix_test.sp).

### Forwards

* `void SMix_OnPlayerChange(int client, int oldValue, int newValue)`<br>
  Hook for client changes to `snd_stream` if, for whatever reason, you want to track client states yourself


### Natives

* `int SMix_ClientState(int client)`<br>
  Returns the current state of the client's `snd_stream` setting (-1 = unknown, 0 = disabled, 1 = enabled)

* `void SMix_ForceClientCheck(int client)`<br>
  Forces an update of the given client, plugin will check automatically OnClientPutInServer and every 10 seconds

* `void SMix_ForceFormatAll(int forceFormat)`<br>
  Forces all registered and newly added sounds to use given format (0 = remove format forcing, 1 = mp3 only, 2 = wav only).
  If you call this too late both versions might get downloaded/precached but only the forced version will ever be used.

* `void SMix_ClearAllSounds()`<br>
  Removes all registered sounds, no idea why one would do that but yeah

* `SMixSound SMix_CreateSound(char[] name, char[] sample, float volume = 1.0, bool precache = true, int forceFormat = 0)`<br>
  Registers a new sound with a name, sample should be `folder/file.mp3` or `folder/file.wav`, plugin will create the other
  version automatically. Don't include `sound/` prefix. Returns an `SMixSound` methodmap.

* `SMixSound SMix_FindSound(char[] name)`<br>
  Lookup a previously registered sound by name. Returns an `SMixSound` methodmap, to check if it actually found something
  check it's index like `if (snd.index > -1)`

* `SMixSound SMix_EmitSoundToAll(char[] name, <SNDARGS>)`<br>
  Plays a registered sound (by name) to all players. Does nothing if the sound can't be found (no need for index checking).

* `SMixSound SMix_EmitSoundToClient(int client, char[] name, <SNDARGS>)`<br>
  Plays a registered sound (by name) to given client. Does nothing if the sound can't be found (no need for index checking).

**The following natives are being used by the methodmap, you can use them directly but I would say use the methodmap**

* `void SMix_Sound_WavSample(int soundIndex, char[] sample, int length)`
* `void SMix_Sound_Mp3Sample(int soundIndex, char[] sample, int length)`
* `float SMix_Sound_Volume(int soundIndex)`
* `void SMix_Sound_SetVolume(int soundIndex, float newVolume)`
* `bool SMix_Sound_Precache(int soundIndex)`
* `void SMix_Sound_SetPrecache(int soundIndex, bool shouldPrecache)`
* `int SMix_Sound_ForceFormat(int soundIndex)`
* `void SMix_Sound_SetForceFormat(int soundIndex, int forceFormat)`


### SMixSound methodmap

CS:GO Soundmixer provides a methodmap for sounds making it easier to work with them:

```
SMixSound snd = SMix_FindSound("foo");
snd.EmitToClient(client);

// alternatively
SMix_Sound_EmitToClient(snd.index, client);

// or
SMix_EmitSoundToClient("foo", client);
```

The methodmap provides the following attributes and functions:

* ATTR_RO(int) `index`<br>
  Get sound index

* ATTR_RW(float) `Volume`<br>
  Get or set default sound volumme

* ATTR_RW(bool) `Precache`<br>
  Get or set precache behavior (0 = disabled, 1 = download/precache)

* ATTR_RW(int) `ForceFormat`<br>
  Get or set format forcing (0 = no format forcing, 1 = mp3 only, 2 = wav only)

* `void GetWavSample(char[] sample, int length)`<br>
  Copy WAV sample path to given char

* `void GetMp3Sample(char[] sample, int length)`<br>
  Copy MP3 sample path to given char

* `void EmitToAll(<SNDARGS>)`<br>
  Emit sound to all

* `void EmitToClient(client, <SNDARGS>)`<br>
  Emit sound to given client


## SNDARGS

For the sake of readability `<SNDARGS>` expand to (and are all optional):

* `int   entity = SOUND_FROM_PLAYER`
* `int   channel = SNDCHAN_AUTO`
* `int   level = SNDLEVEL_NORMAL`
* `int   flags = SND_NOFLAGS`
* `float volume = SNDVOL_NORMAL`
* `int   pitch = SNDPITCH_NORMAL`
* `int   speakerentity = -1`
* `float origin[3] = NULL_VECTOR`
* `float dir[3] = NULL_VECTOR`
* `bool  updatePos = true`
* `float soundtime = 0.0`

**Note:** If you don't provide a `volume` argument the configured "per sound default" will be used (which defaults to 1.0/100%)


## Contributing

  Contributions are very welcome! Either report errors, bugs and propose features or directly submit code:

  1. Fork it ( http://github.com/2called-chaos/csgo_soundmixer/fork )
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request


## Legal

* This repository is licensed under the MIT license.
