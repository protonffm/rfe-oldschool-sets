settings.init.allow_root.set(true)

music = playlist(mode="randomize", reload_mode="watch", "/home/radio/music")
music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, music)
radio = mksafe(music)

# Schreibt das Audiosignal als schlanke MP3-Datei, die NIEMALS verstopft!
output.file(
  %mp3(bitrate=128),
  append=false,
  "/tmp/stream/live.mp3",
  radio
)
