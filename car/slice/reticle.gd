extends Control
## Camera viewfinder reticle: a fixed-aspect 16:9 rectangle centred on the
## cursor (drawn where the game tells it to). Colour = subject tier. A small
## multiplier tag rides above it when locked.

const ASPECT := 16.0 / 9.0

var _pos := Vector2.ZERO
var _tier := 0
var _mult := 1.0
var _half := Vector2(60.0, 60.0 / (16.0 / 9.0))


## Called every frame by slice.gd.
func set_state(pos: Vector2, tier: int, mult: float, width: float) -> void:
	_pos = pos
	_tier = tier
	_mult = mult
	var h: float = width / ASPECT
	_half = Vector2(width * 0.5, h * 0.5)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var col := _tier_color(_tier)
	var tl := _pos - _half
	var br := _pos + _half
	var r := Rect2(tl, br - tl)

	draw_rect(r, col, false, 2.0, true)

	# Corner brackets (viewfinder feel)
	var b := 14.0
	var w := 3.0
	draw_line(tl, tl + Vector2(b, 0), col, w, true)
	draw_line(tl, tl + Vector2(0, b), col, w, true)
	draw_line(Vector2(br.x, tl.y), Vector2(br.x - b, tl.y), col, w, true)
	draw_line(Vector2(br.x, tl.y), Vector2(br.x, tl.y + b), col, w, true)
	draw_line(Vector2(tl.x, br.y), Vector2(tl.x + b, br.y), col, w, true)
	draw_line(Vector2(tl.x, br.y), Vector2(tl.x, br.y - b), col, w, true)
	draw_line(br, br - Vector2(b, 0), col, w, true)
	draw_line(br, br - Vector2(0, b), col, w, true)

	if _tier > 0:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(tl.x, tl.y - 8.0), "x%.1f" % _mult,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)


func _tier_color(tier: int) -> Color:
	match tier:
		1: return Color(1.0, 0.9, 0.2)    # yellow - idle subject
		2: return Color(1.0, 0.55, 0.1)   # orange - attacking
		3: return Color(1.0, 0.2, 0.15)   # red    - destruction / fast
		4: return Color(1.0, 0.85, 0.3)   # gold   - money shot
		_: return Color(1, 1, 1, 0.55)    # grey   - nothing
