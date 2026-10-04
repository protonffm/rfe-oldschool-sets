set("init.allow_root", true)

music = playlist(mode="randomize", reload_mode="watch", "/home/radio/music")
music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, music)
radio = mksafe(music)

# Schreibt das Audiosignal als unendlichen Rohdaten-Stream in den RAM
output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=true,
  "/tmp/stream/live.raw",
  radio
)
