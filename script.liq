set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# Musik zufällig abspielen per randomize
music = playlist(
  mode="randomize",
  reload_mode="watch",
  "/home/radio/music"
)

# Saubere Übergänge zwischen den Titeln
music = crossfade(
  smart=true,
  duration=3.0,
  fade_out=2.5,
  fade_in=1.5,
  music
)

# Niemals ohne Audio ausfallen
radio = mksafe(music)

# Ausgabe an den lokalen Icecast-Server
output.icecast(
  %mp3(bitrate=128),
  host="127.0.0.1",
  port=8000,
  mount="/live.mp3",
  password="radio_source_password",
  name="Radio Freies Eurasien",
  genre="Underground HipHop",
  radio
)
