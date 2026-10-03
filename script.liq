set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# Liest stur den Musikordner aus
my_music = playlist(mode="random", reload_mode="watch", "/home/radio/music")

# Der bewaehrte DJ-Mixer gegen Doppel-Bass
my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)

final_audio = mksafe(my_music)

output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
