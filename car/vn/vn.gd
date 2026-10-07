extends Control
## Kinetic-VN driver. Reads a plain-text script - no JSON, no build step.
##
## FORMAT
##   == label          start a labelled beat (a jump target)
##   Name: line        a dialogue or narration line (BBCode allowed)
##   ? choice text     a branch under the line above
##   + stat n          effect for the branch above (or the beat, if no branch yet)
##   -> label          jump to a label; leave blank to end the scene
##   # comment         ignored
##
## Lines with no "== / ? / + / -> " prefix that look like "Name: text" are
## dialogue. Beats flow top-to-bottom unless a "-> " jumps elsewhere.

const CHARS_PER_SEC := 45.0

## Leave blank to play through Game.chapters in order; set a path to test one file.
@export var chapter_file := ""

var _nodes := {}
var _node_id := ""
var _revealing := false
var _char_timer := 0.0
var _char_count := 0

@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $Box/Name
@onready var text_label: RichTextLabel = $Box/Text
@onready var choices: VBoxContainer = $Choices
@onready var hint: Label = $Hint


func _ready() -> void:
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
			var i := line.find(":")
			if i < 0:
				continue
			cur = {
				"label": pending_label,
				"speaker": line.substr(0, i).strip_edges(),
				"text": line.substr(i + 1).strip_edges(),
				"effects": {},
				"choices": [],
				"next_label": "",
				"force_end": false,
			}
			pending_label = ""
			last_choice = null
			blocks.append(cur)

	# label -> block index
	for i in blocks.size():
		var lbl: String = str(blocks[i]["label"])
		if lbl != "":
			labels[lbl] = i

	# blocks -> runtime nodes
	var nodes := {}
	for i in blocks.size():
		var b: Dictionary = blocks[i]
		var node := {
			"speaker": b["speaker"],
			"text": b["text"],
			"effects": b["effects"],
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

	name_label.text = str(node.get("speaker", ""))
	text_label.text = str(node.get("text", ""))
	text_label.visible_characters = 0
	_char_count = text_label.get_total_character_count()
	_char_timer = 0.0
	_revealing = true

	_clear_choices()
	hint.text = ""


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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_advance()


func _advance() -> void:
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
