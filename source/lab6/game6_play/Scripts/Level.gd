extends Node3D

# Root script of each level: registers the level with the GameManager.

@export var level_index := 0
@export var level_title := "ด่าน 1"

func _ready():
	# Children are ready first, so every energy cell is already in the "coins" group
	GameManager.start_level(level_index, get_tree().get_nodes_in_group("coins").size())
	$UserInterface/GameUI.show_title(level_title)
