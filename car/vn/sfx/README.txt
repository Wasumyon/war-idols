Sound files for the visual novel live here.

NAME CONVENTION
  A directive `@ sfx gunshot` loads, in order:
      vn/sfx/gunshot.ogg
      vn/sfx/gunshot.wav
      vn/sfx/gunshot.mp3
  So just drop a file named after the sound and use that name in the script.

  `@ music tense` uses the same lookup and loops until changed.
  `@ music stop` stops the music.

  You can also give a full path: `@ sfx res://vn/sfx/explosion.ogg`.

  A missing file does not crash - it logs a warning and plays nothing.

SUPPORTED FORMATS
  .ogg (recommended for music), .wav, .mp3
