settings.init.allow_root.set(true)

music = playlist(mode="randomize", reload_mode="watch", "/home/radio/music")
music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, music)
radio = mksafe(music)

# Schreibt den Ton als fortlaufenden MP3-Stream direkt in die RAM-Pipe
output.file(
  %mp3(bitrate=128),
  append=true,
  "/tmp/stream/live.mp3",
  radio
)
