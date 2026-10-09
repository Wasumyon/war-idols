extends Control
## Kinetic-VN driver. Reads a plain-text script - no JSON, no build step.
##
## LINE TYPES
##   Name: text      dialogue  -> bottom box, name label, typewriter
##   text            narration -> full screen, no name, one line added per click
##   ? choice text   a branch under the line above
##   + stat n        effect for the branch/line above (e.g. + hype 5)
##   -> label        jump to a label; blank ends the scene
##   == label        a named beat to jump to
##   # comment       ignored
##
## DIRECTIVES - two kinds:
##
##   MODE (STICKY) - sets a state that lasts until changed. Add "off" to undo.
##     @ fullscreen / @ fullscreen off
##     @ box                     (shorthand for @ fullscreen off)
##     @ center / @ center off
##     @ right  / @ right off
##     @ small  / @ small off
##     @ large  / @ large off
##     @ narration / @ narration off   (alias of @ fullscreen: line-by-line
##                                      prose, no text box, no name)
##
##   EVENT (ONE-SHOT) - happens on the line it is attached to, then gone.
##     @ stage <text>            stage direction -> italic line above
##     @ sfx <name>              play vn/sfx/<name> (one-shot)
##     @ music <name>            swap looping music; "@ music stop"
##     @ shake                   brief shake of the text area
##     @ glitch [seconds]        brief full-screen glitch (feed failing)
##     @ page                    start a new page (break the narration block)
##     @ input_name              open the name-entry panel
##     @ call <scene>            hand off to another scene (not wired yet)
##
## A line is dialogue ONLY if the text before the first ":" is one word.
## So "Chip: hi" is dialogue, but "Our contract: split 50/50" is narration.
##
## "Player:" resolves to Game.display_name() - "Blockhead" until the player
## enters a name, then that name. "{player}" in text expands the same way.

const CHARS_PER_SEC := 45.0
const SFX_DIR := "res://vn/sfx/"
const SFX_EXTS := ["ogg", "wav", "mp3"]
const MODE_VERBS := ["fullscreen", "narration", "box", "center", "right", "small", "large"]

## Leave blank to play through Game.chapters in order; set a path to test one file.
@export var chapter_file := ""

var _nodes := {}
var _node_id := ""
var _revealing := false
var _char_timer := 0.0
var _char_count := 0
var _narr_lines := PackedStringArray()
var _narr_shown := 0
var _narr_page_start := 0   # index of the first line on the current page

@onready var box: ColorRect = $Box
@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $Box/Name
@onready var text_label: RichTextLabel = $Box/Text
@onready var narration_label: RichTextLabel = $Narration
@onready var choices: VBoxContainer = $Choices
@onready var hint: Label = $Hint
@onready var name_panel: PanelContainer = $NamePanel
@onready var name_input: LineEdit = $NamePanel/VBox/NameInput
@onready var sfx_player: AudioStreamPlayer = $Sfx
@onready var music_player: AudioStreamPlayer = $Music
@onready var glitch: ColorRect = $Glitch


func _ready() -> void:
	name_input.text_submitted.connect(_on_name_submitted)
	$NamePanel/VBox/Confirm.pressed.connect(_confirm_name)
	var path := chapter_file if chapter_file != "" else Game.current_chapter()
	_load(path)
	_goto(str(_nodes.get("start", "")))


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------
func _load(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("VN: cannot open " + path)
		return
	_parse(f.get_as_text())


func _parse(text: String) -> void:
	var blocks: Array = []
	var labels := {}
	var pending_label := ""
	var pending_staging: Array[String] = []   # EVENT directives only
	var pending_mode := false                 # did a MODE directive just appear?
	var pending_page := false                 # did "@ page" just force a page break?
	var modes := {"fullscreen": false, "align": "left", "size": "normal"}
	var cur = null
	var last_choice = null

	for raw in text.split("\n"):
		var line: String = raw.strip_edges()
		if line == "" or line.begins_with("#"):
			continue

		if line.begins_with("=="):
			pending_label = line.substr(2).strip_edges()
			last_choice = null
			continue

		if line.begins_with("@"):
			var d := line.substr(1).strip_edges()
			var dp := d.split(" ", true, 1)
			var verb := str(dp[0])
			var arg := str(dp[1]).strip_edges() if dp.size() > 1 else ""
			if verb == "page":
				pending_page = true
			elif MODE_VERBS.has(verb):
				_apply_mode(modes, verb, arg)
				pending_mode = true
			else:
				pending_staging.append(d)
			continue

		if line.begins_with("?"):
			if cur == null:
				continue
			var ch := {"text": line.substr(1).strip_edges(), "effects": {}, "goto": "", "force_end": false}
			cur["choices"].append(ch)
			last_choice = ch
		elif line.begins_with("+"):
			if cur == null:
				continue
			var parts := line.substr(1).strip_edges().split(" ")
			if parts.size() >= 2:
				var key := parts[0]
				var amt := int(parts[1])
				var bag: Dictionary = last_choice["effects"] if last_choice != null else cur["effects"]
				bag[key] = int(bag.get(key, 0)) + amt
		elif line.begins_with("->"):
			if cur == null:
				continue
			var lbl := line.substr(2).strip_edges()
			if last_choice != null:
				last_choice["goto"] = lbl
				last_choice["force_end"] = (lbl == "")
			else:
				cur["next_label"] = lbl
				cur["force_end"] = (lbl == "")
		else:
			var spk := ""
			var body := line
			var i := line.find(":")
			if i > 0:
				var prefix := line.substr(0, i).strip_edges()
				if prefix != "" and not prefix.contains(" ") and prefix.length() <= 24:
					spk = prefix
					body = line.substr(i + 1).strip_edges()
			var is_narr: bool = spk == "" or spk == "Narrator" or spk == "~"

			# Merge consecutive narration into one block. Only a clean,
			# directive-free narration line merges, so a mode change or an
			# event starts a fresh block.
			if is_narr and pending_staging.is_empty() and not pending_mode and not pending_page and not blocks.is_empty():
				var prev: Dictionary = blocks[blocks.size() - 1]
				if prev["narration"] and prev["staging"].is_empty() and prev["choices"].is_empty() and prev["next_label"] == "" and not prev["force_end"]:
					prev["text"] = str(prev["text"]) + "\n" + body
					cur = prev
					last_choice = null
					continue

			cur = {
				"label": pending_label,
				"speaker": spk,
				"text": body,
				"narration": is_narr,
				"modes": modes.duplicate(),
				"effects": {},
				"choices": [],
				"next_label": "",
				"force_end": false,
				"staging": pending_staging.duplicate(),
			}
			pending_label = ""
			pending_staging.clear()
			pending_mode = false
			pending_page = false
			last_choice = null
			blocks.append(cur)

	# staging that trailed the last line (e.g. a closing "@ call").
	if not pending_staging.is_empty() and not blocks.is_empty():
		var last: Dictionary = blocks[blocks.size() - 1]
		last["staging"] = Array(last["staging"]) + Array(pending_staging)

	for i in blocks.size():
		var lbl: String = str(blocks[i]["label"])
		if lbl != "":
			labels[lbl] = i

	var nodes := {}
	for i in blocks.size():
		var b: Dictionary = blocks[i]
		var node := {
			"speaker": b["speaker"],
			"text": b["text"],
			"narration": b["narration"],
			"modes": b["modes"],
			"effects": b["effects"],
			"staging": b["staging"],
			"next": _resolve(str(b["next_label"]), bool(b["force_end"]), i, blocks, labels),
			"choices": [],
		}
		for c in b["choices"]:
			node["choices"].append({
				"text": c["text"],
				"effects": c["effects"],
				"goto": _resolve(str(c["goto"]), bool(c["force_end"]), i, blocks, labels),
			})
		nodes[str(i)] = node

	_nodes = {"start": "0", "nodes": nodes}


func _apply_mode(modes: Dictionary, verb: String, arg: String) -> void:
	var on := arg != "off"
	match verb:
		"fullscreen", "narration":
			modes["fullscreen"] = on
		"box":
			modes["fullscreen"] = false
		"center":
			if on:
				modes["align"] = "center"
			elif modes["align"] == "center":
				modes["align"] = "left"
		"right":
			if on:
				modes["align"] = "right"
			elif modes["align"] == "right":
				modes["align"] = "left"
		"small":
			modes["size"] = "small" if on else "normal"
		"large":
			modes["size"] = "large" if on else "normal"


func _resolve(label: String, force_end: bool, index: int, blocks: Array, labels: Dictionary) -> String:
	if force_end:
		return ""
	if label != "":
		if labels.has(label):
			return str(labels[label])
		push_error("VN: unknown label '%s'" % label)
		return ""
	if index + 1 < blocks.size():
		return str(index + 1)
	return ""


# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
func _goto(id: String) -> void:
	if id == "" or not _nodes.get("nodes", {}).has(id):
		_finish()
		return
	_node_id = id
	var node: Dictionary = _nodes["nodes"][id]
	_apply_effects(node.get("effects", {}))
	_handle_audio(node)
	if _has_staging(node, "shake"):
		_shake()
	if _has_staging(node, "glitch"):
		var ga := _staging_arg(node, "glitch")
		_start_glitch(float(ga) if ga != "" else 0.4)

	_clear_choices()
	hint.text = ""

	var modes: Dictionary = node.get("modes", {})
	var fullscreen: bool = bool(node.get("narration", false)) or bool(modes.get("fullscreen", false))

	var body := _compose_text(node)
	if fullscreen and not bool(node.get("narration", false)):
		var spk := _speaker_name(node)
		if spk != "":
			body = "[b]%s[/b]\n%s" % [spk, body]

	if fullscreen:
		box.visible = false
		portrait.visible = false
		narration_label.visible = true
		_narr_lines = body.split("\n")
		_narr_shown = 1 if _narr_lines.size() > 0 else 0
		_narr_page_start = 0
		_render_narration()
		_revealing = false
		_present_choices()
	else:
		narration_label.visible = false
		box.visible = true
		portrait.visible = true
		name_label.text = _speaker_name(node)
		text_label.text = body
		text_label.visible_characters = 0
		_char_count = text_label.get_total_character_count()
		_char_timer = 0.0
		_revealing = true

	if _has_staging(node, "input_name"):
		_show_name_input()


func _render_narration() -> void:
	var out := PackedStringArray()
	for i in range(_narr_page_start, _narr_shown):
		out.append(_narr_lines[i])
	narration_label.text = "\n".join(out)


## True when the lines on the current page fit inside the visible area.
func _narration_fits() -> bool:
	return narration_label.size.y <= 0.0 or narration_label.get_content_height() <= narration_label.size.y


## The just-revealed line made the page overflow. Rather than scroll or clip,
## start a fresh page ending at the newest line - keeping the previous line
## too when it still fits, so the transition has one line of context.
func _reflow_narration_page() -> void:
	var newest := _narr_shown - 1
	if newest < 0:
		return
	_narr_page_start = newest
	_render_narration()
	if newest - 1 >= 0:
		_narr_page_start = newest - 1
		_render_narration()
		if not _narration_fits():
			_narr_page_start = newest
			_render_narration()


## EVENT: a brief shake of the visible text areas.
func _shake() -> void:
	var targets: Array[Control] = [box, narration_label]
	for n in targets:
		if not n.visible:
			continue
		var base: Vector2 = n.position
		var tw := create_tween()
		for i in 5:
			tw.tween_property(n, "position", base + Vector2(randf_range(-9.0, 9.0), randf_range(-7.0, 7.0)), 0.03)
		tw.tween_property(n, "position", base, 0.06)


func _speaker_name(node: Dictionary) -> String:
	var spk := str(node.get("speaker", ""))
	if spk == "Player" or spk == "{player}":
		return Game.display_name()
	return spk


## Displayed text: "@ stage" directions become an italic block on top, and the
## node's sticky MODES add alignment / size via BBCode.
func _compose_text(node: Dictionary) -> String:
	var shown: Array[String] = []
	for d in node.get("staging", []):
		var parts := str(d).split(" ", true, 1)
		if parts.size() == 2 and parts[0] == "stage":
			shown.append("(%s)" % parts[1])
	var t := str(node.get("text", "")).replace("{player}", Game.display_name())
	if not shown.is_empty():
		t = "[i]%s[/i]\n%s" % ["\n".join(shown), t]

	var modes: Dictionary = node.get("modes", {})
	match str(modes.get("align", "left")):
		"center":
			t = "[center]%s[/center]" % t
		"right":
			t = "[right]%s[/right]" % t
	match str(modes.get("size", "normal")):
		"small":
			t = "[font_size=22]%s[/font_size]" % t
		"large":
			t = "[font_size=40]%s[/font_size]" % t
	return t


func _has_staging(node: Dictionary, verb: String) -> bool:
	for d in node.get("staging", []):
		var parts := str(d).split(" ", true, 1)
		if parts.size() >= 1 and parts[0] == verb:
			return true
	return false


func _staging_arg(node: Dictionary, verb: String) -> String:
	for d in node.get("staging", []):
		var parts := str(d).split(" ", true, 1)
		if str(parts[0]) == verb:
			return str(parts[1]).strip_edges() if parts.size() > 1 else ""
	return ""


## EVENT: a brief screen glitch - distorts the whole frame (feed failing).
func _start_glitch(duration: float) -> void:
	if glitch == null or glitch.material == null:
		return
	var tw := create_tween()
	tw.tween_method(_set_glitch, 1.0, 0.0, duration)


func _set_glitch(v: float) -> void:
	glitch.material.set_shader_parameter("intensity", v)


## Plays any @ sfx / @ music directives attached to this line.
func _handle_audio(node: Dictionary) -> void:
	for d in node.get("staging", []):
		var parts := str(d).split(" ", true, 1)
		if parts.size() < 2:
			continue
		if parts[0] == "sfx":
			_play_sfx(parts[1].strip_edges())
		elif parts[0] == "music":
			_play_music(parts[1].strip_edges())


func _load_sound(name: String) -> AudioStream:
	if name == "":
		return null
	if name.begins_with("res://"):
		return load(name) as AudioStream
	for ext in SFX_EXTS:
		var p := "%s%s.%s" % [SFX_DIR, name, ext]
		if ResourceLoader.exists(p):
			return load(p) as AudioStream
	return null


func _play_sfx(name: String) -> void:
	var s := _load_sound(name)
	if s == null:
		push_warning("VN: missing sfx '%s' (expected %s%s.ogg|wav|mp3)" % [name, SFX_DIR, name])
		return
	sfx_player.stream = s
	sfx_player.play()


func _play_music(name: String) -> void:
	if name == "" or name == "stop":
		music_player.stop()
		return
	var s := _load_sound(name)
	if s == null:
		push_warning("VN: missing music '%s' (expected %s%s.ogg|wav|mp3)" % [name, SFX_DIR, name])
		return
	if music_player.stream == s and music_player.playing:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	elif s is AudioStreamMP3:
		s.loop = true
	elif s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.stream = s
	music_player.play()


func _show_name_input() -> void:
	name_panel.visible = true
	name_input.text = Game.player_name
	name_input.grab_focus()


func _on_name_submitted(_text: String) -> void:
	_confirm_name()


func _confirm_name() -> void:
	Game.set_player_name(name_input.text)
	name_panel.visible = false
	name_label.text = _speaker_name(_nodes["nodes"][_node_id])


func _clear_choices() -> void:
	for c in choices.get_children():
		c.queue_free()


func _process(delta: float) -> void:
	if not _revealing:
		return
	_char_timer += delta * CHARS_PER_SEC
	text_label.visible_characters = int(_char_timer)
	if text_label.visible_characters >= _char_count:
		text_label.visible_characters = -1
		_revealing = false
		_present_choices()


func _present_choices() -> void:
	var node: Dictionary = _nodes["nodes"][_node_id]
	var opts: Array = node.get("choices", [])
	if opts.is_empty():
		hint.text = "click / space"
		return
	for o in opts:
		var b := Button.new()
		b.text = str(o.get("text", "..."))
		b.pressed.connect(_choose.bind(o))
		choices.add_child(b)


func _choose(option: Dictionary) -> void:
	_apply_effects(option.get("effects", {}))
	_goto(str(option.get("goto", "")))


func _apply_effects(effects: Dictionary) -> void:
	for k in effects.keys():
		Game.add_stat(str(k), int(effects[k]))


func _unhandled_input(event: InputEvent) -> void:
	if name_panel.visible:
		return   # name entry is modal
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_advance()


func _advance() -> void:
	if name_panel.visible:
		return
	# Narration reveals one line per click; when a page would overflow it
	# flushes to a fresh page instead of scrolling or clipping.
	if narration_label.visible and _narr_shown < _narr_lines.size():
		_narr_shown += 1
		_render_narration()
		if not _narration_fits():
			_reflow_narration_page()
		return
	if _revealing:
		text_label.visible_characters = -1
		_revealing = false
		_present_choices()
		return
	var node: Dictionary = _nodes["nodes"][_node_id]
	if node.has("choices") and not node["choices"].is_empty():
		return   # a choice is required
	var nxt := str(node.get("next", ""))
	if nxt == "":
		_finish()
	else:
		_goto(nxt)


func _finish() -> void:
	if chapter_file == "" and Game.advance_chapter():
		_load(Game.current_chapter())
		_goto(str(_nodes.get("start", "")))
		return
	print("VN end. ", Game.debug_line())
	hint.text = "— end —"
