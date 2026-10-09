extends Node3D

# ---------- VARIABLES ---------- #

const LEVELS = ["res://Scenes/Level1.tscn", "res://Scenes/Level2.tscn"]
const WIN_SCENE = "res://Scenes/Win.tscn"

var score = 0 # Energy cells collected in the current level
var total = 0 # Energy cells placed in the current level
var level_index = 0
var deaths = 0

# ---------- FUNCTIONS ---------- #

func _process(_delta):
	show_mouse_cursor()

# Making Cursor visible using "mouse_visible" key which is assigned in Project Settings > Input Map
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func start_level(index, cell_count):
	level_index = index
	score = 0
	total = cell_count

func add_score():
	score += 1

func all_collected():
	return score >= total

func next_level():
	level_index += 1
	if level_index >= LEVELS.size():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file.call_deferred(WIN_SCENE)
	else:
		get_tree().change_scene_to_file.call_deferred(LEVELS[level_index])

func restart_game():
	level_index = 0
	deaths = 0
	get_tree().change_scene_to_file.call_deferred(LEVELS[0])
