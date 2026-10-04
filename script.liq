set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# Modus auf "normal" gestellt - so laeuft die Liste sauber von oben nach unten durch
my_music = playlist(mode="normal", reload_mode="watch", "/home/radio/music")

# Der unbestechliche Rotations-Waerter: Er mischt die gesamte Liste einmalig kräftig durch. 
# Ein Track kommt erst wieder dran, wenn alle anderen Lieder einmal gespielt wurden!
my_music = shuffle(my_music)

# Der bewaehrte DJ-Mixer gegen Doppel-Bass
my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)

final_audio = mksafe(my_music)

output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
