extends Node
## Shared game state, autoloaded as `Game`.
##
## Both the runner (slice/) and the visual novel (vn/) read and write this, so
## neither scene needs to know about the other. Register in project.godot:
##     [autoload]
##     Game="*res://autoload/game.gd"

var stats := {
	"hype": 0,
	"sympathy": 0,
	"bloodlust": 0,
	"drama": 0,
	"patriotism": 0,
}
var followers := 0
var money := 0
var day := 1
var flags := {}

## The player character's name. Empty until the player enters it.
## Until then, Chip's nickname "Blockhead" is used.
var player_name := ""


func display_name() -> String:
	var n := player_name.strip_edges()
	return n if n != "" else "Blockhead"


func set_player_name(raw: String) -> void:
	var n := raw.strip_edges()
	player_name = n if n != "" else "Commander"

## Story order. The VN walks these; add scenes here as you write them.
var chapters: Array[String] = [
	"res://vn/dialogue/01_intro.txt",
	"res://vn/dialogue/02_stream.txt",
	"res://vn/dialogue/03_car.txt",
	"res://vn/dialogue/04_mission_clear.txt",
]
var chapter_index := 0


func current_chapter() -> String:
	if chapter_index >= 0 and chapter_index < chapters.size():
		return chapters[chapter_index]
	return ""


func advance_chapter() -> bool:
	chapter_index += 1
	return chapter_index < chapters.size()


func add_stat(key: String, amount: int) -> void:
	stats[key] = int(stats.get(key, 0)) + amount


func get_stat(key: String) -> int:
	return int(stats.get(key, 0))


func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value


func has_flag(key: String) -> bool:
	return bool(flags.get(key, false))


func reset() -> void:
	for k in stats.keys():
		stats[k] = 0
	followers = 0
	money = 0
	day = 1
	flags.clear()


func debug_line() -> String:
	return "day %d | followers %d | money %d | stats %s | flags %s" % [
		day, followers, money, str(stats), str(flags)
	]
