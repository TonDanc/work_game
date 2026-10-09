extends Area3D

# Exit door: opens once every energy cell in the level is collected.

# ---------- VARIABLES ---------- #

@onready var label = $Label3D
@onready var light = $OmniLight3D

var opened = false

# ---------- FUNCTIONS ---------- #

func _ready():
	body_entered.connect(_on_body_entered)

func _process(_delta):
	if GameManager.all_collected():
		label.text = "ประตูเปิดแล้ว!\nเข้าไปเลย"
		label.modulate = Color(0.5, 1, 0.5)
		light.light_color = Color(0.3, 1, 0.4)
		# The player may already be standing in the doorway when the last cell arrives
		for body in get_overlapping_bodies():
			_on_body_entered(body)
	else:
		label.text = "เก็บพลังงานให้ครบ\n%d / %d" % [GameManager.score, GameManager.total]
		label.modulate = Color(1, 0.6, 0.4)
		light.light_color = Color(1, 0.3, 0.2)

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	if opened or not body.is_in_group("Player"):
		return
	if GameManager.all_collected():
		opened = true
		AudioManager.coin_sfx.play()
		body.celebrate()
		await get_tree().create_timer(1.2).timeout
		GameManager.next_level()
