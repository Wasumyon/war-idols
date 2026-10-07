extends Control
## Crosshair. Two independent channels:
##   COLOR  = subject tier   (0 grey / 1 yellow / 2 orange / 3 red / 4 gold)
##   RADIUS = value multiplier (grows as the subject gets closer)
## Gold (4) is reserved for the money-shot later.

const BASE_RADIUS := 12.0
const MAX_EXTRA := 8.0
const MAX_MULT := 3.0

var _tier := 0
var _mult := 1.0


func set_state(tier: int, mult: float) -> void:
	_tier = tier
	_mult = mult


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var p := get_local_mouse_position()
	var col := _tier_color(_tier)
	var extra: float = clamp((_mult - 1.0) / (MAX_MULT - 1.0), 0.0, 1.0)
	var r := BASE_RADIUS + MAX_EXTRA * extra
	var w := 2.0 + 1.5 * extra

	draw_arc(p, r, 0.0, TAU, 48, col, w, true)
	draw_line(p + Vector2(-r - 10, 0), p + Vector2(-r - 3, 0), col, w, true)
	draw_line(p + Vector2(r + 3, 0), p + Vector2(r + 10, 0), col, w, true)
	draw_line(p + Vector2(0, -r - 10), p + Vector2(0, -r - 3), col, w, true)
	draw_line(p + Vector2(0, r + 3), p + Vector2(0, r + 10), col, w, true)

	if _tier > 0:
		draw_circle(p, 2.5, col)


func _tier_color(tier: int) -> Color:
	match tier:
		1: return Color(1.0, 0.9, 0.2)    # yellow - idle subject
		2: return Color(1.0, 0.55, 0.1)   # orange - attacking
		3: return Color(1.0, 0.2, 0.15)   # red    - destruction
		4: return Color(1.0, 0.85, 0.3)   # gold   - money shot
		_: return Color(1, 1, 1, 0.6)     # grey   - nothing
