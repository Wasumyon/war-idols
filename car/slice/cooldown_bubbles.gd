extends Control
## Two big cooldown bubbles, bottom-left. Each is a ring that unwinds like a
## clock: a dark arc covers the remaining cooldown and sweeps away as it
## becomes ready.

const READY := Color(0.25, 0.9, 1.0)
const COOL := Color(0.25, 0.3, 0.35)
const RADIUS := 28.0
const SPACING := 92.0

var _snap := {"rem": 0.0, "total": 5.0}
var _dash := {"rem": 0.0, "total": 4.5}


func set_cooldowns(snap_rem: float, snap_total: float, dash_rem: float, dash_total: float) -> void:
	_snap["rem"] = snap_rem
	_snap["total"] = max(snap_total, 0.001)
	_dash["rem"] = dash_rem
	_dash["total"] = max(dash_total, 0.001)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var y := size.y - 62.0
	_draw_bubble(Vector2(62.0, y), _snap, "SNAP", "LMB")
	_draw_bubble(Vector2(62.0 + SPACING, y), _dash, "DASH", "SHIFT")


func _draw_bubble(c: Vector2, item: Dictionary, label: String, key: String) -> void:
	var rem: float = item["rem"]
	var total: float = item["total"]
	var ready := rem <= 0.0

	draw_circle(c, RADIUS, Color(0, 0, 0, 0.55))
	draw_arc(c, RADIUS, 0.0, TAU, 48, (READY if ready else COOL), 4.0, true)

	if not ready:
		var frac: float = clamp(rem / total, 0.0, 1.0)
		# dark wedge from the top, clockwise, sized by remaining cooldown
		draw_arc(c, RADIUS - 2.0, -PI / 2.0, -PI / 2.0 + frac * TAU, 48,
			Color(0.0, 0.0, 0.0, 0.65), 9.0, true)
		draw_string(ThemeDB.fallback_font, c + Vector2(-RADIUS, 6.0),
			"%.1f" % rem, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 18, Color(1, 1, 1, 0.9))
	else:
		draw_string(ThemeDB.fallback_font, c + Vector2(-RADIUS, 6.0),
			label, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 14, Color(1, 1, 1, 0.95))

	draw_string(ThemeDB.fallback_font, c + Vector2(-RADIUS, RADIUS + 18.0),
		key, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 12, Color(1, 1, 1, 0.5))
