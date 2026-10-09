extends Area3D

# Trap / obstacle: touching it sends the player back to the spawn point.

# ---------- VARIABLES ---------- #

@export var spin_speed := Vector3.ZERO # Degrees per second applied to the Visual node
@export var move_offset := Vector3.ZERO # Ping-pong movement relative to the start position
@export var move_time := 2.0
@export var face_movement := false # Turn the model toward where it walks (patrolling robot)

@onready var visual = $Visual

var last_position := Vector3.ZERO

# ---------- FUNCTIONS ---------- #

func _ready():
	body_entered.connect(_on_body_entered)
	last_position = position
	if move_offset != Vector3.ZERO:
		var tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "position", position + move_offset, move_time)
		tween.tween_property(self, "position", position, move_time)

func _process(delta):
	if spin_speed != Vector3.ZERO:
		visual.rotation_degrees += spin_speed * delta
	if face_movement:
		var step = position - last_position
		if step.length() > 0.001:
			visual.rotation.y = lerp_angle(visual.rotation.y, Vector2(step.z, step.x).angle(), delta * 10)
	last_position = position

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.respawn()
