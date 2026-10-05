settings.init.allow_root.set(true)

# Unendlicher Loop im Zufallsmodus
music = playlist(
  mode="randomize", 
  reload_mode="watch", 
  loop=true, 
  "/home/radio/music"
)

music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, music)
radio = mksafe(music)

# 'fallible=true' sorgt dafür, dass Liquidsoap NICHT abstürzt, wenn die Pipe kurz zuckt!
output.file(
  %mp3(bitrate=128),
  append=true,
  fallible=true,
  on_stop={echo("Pipe closed, waiting for FFmpeg reconnect...")},
  "/tmp/stream/live.mp3",
  radio
)
