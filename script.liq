set("init.allow_root", true)

set("decoder.priorities", ["ffmpeg", "mad"])

set("root.sync.buffer", 2.0)

# ------------------------------------------------------------
# MUSIK
# ------------------------------------------------------------

my_music = playlist(
    mode="normal",
    reload_mode="watch",
    "/home/radio/music"
)

# Zufällige Reihenfolge
my_music = shuffle(my_music)

# ------------------------------------------------------------
# CROSSFADE
# ------------------------------------------------------------

my_music = crossfade(
    smart=true,
    duration=3.0,
    fade_out=2.5,
    fade_in=1.5,
    my_music
)

# ------------------------------------------------------------
# ABSICHERUNG
# ------------------------------------------------------------

final_audio = mksafe(my_music)

# ------------------------------------------------------------
# RAW PCM AUDIO FÜR FFMPEG
# ------------------------------------------------------------

output.file(
    %wav(
        stereo=true,
        channels=2,
        samplesize=16,
        header=false
    ),
    append=false,
    "/home/radio/live.pipe",
    final_audio
)
