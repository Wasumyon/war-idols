PROTOTYPE - not maintained. AI-authored.
Do not merge into production; re-spec and reimplement instead.

This is a playtesting tool, not a shipping module. It exists so the designer
can write and playtest story without waiting on a programmer. If any of it
graduates, it goes out as a written spec, not as a merge.

WHAT THIS IS
  A custom visual-novel player. Scenes are plain text - no build step.

LAYOUT
  vn.tscn / vn.gd      the player (root Control + layer nodes)
  dialogue/*.txt       scenes, one file per scene (writer-owned content)
  img/                 full-screen illustrations (+ README manifest)
  sfx/                 sound + music (+ README manifest)

DEPENDS ON
  the `Game` autoload (car/autoload/game.gd) only.

DIRECTIVES
  see the header comment at the top of vn.gd for the full list.
