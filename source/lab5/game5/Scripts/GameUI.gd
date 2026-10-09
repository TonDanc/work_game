extends Control

# ---------- VARIABLES ---------- #

@onready var coinsLabel = $CoinsLabel
@onready var levelLabel = $LevelLabel
@onready var messageLabel = $MessageLabel

# ---------- FUNCTIONS ---------- #

func _process(_delta):
	coinsLabel.text = "%d / %d" % [GameManager.score, GameManager.total] # Energy cells collected

func show_title(text):
	levelLabel.text = text
	messageLabel.text = text
	messageLabel.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(messageLabel, "modulate:a", 0.0, 1.0)
