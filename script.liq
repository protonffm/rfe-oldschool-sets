set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

my_music = playlist(mode="normal", reload_mode="watch", "/home/radio/music")
my_music = shuffle(my_music)

my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)
final_audio = mksafe(my_music)

# Streaming direkt in das interne Netzwerk statt in eine verstopfte Pipe!
output.harbor(%mp3(bitrate=128), port=8000, mount="live.mp3", final_audio)
