# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #

extends CharacterBody3D

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 6
@export var jump_force : float = 5
@export var follow_lerp_factor : float = 4
@export var jump_limit : int = 2

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)

# The Lab 6 character (made in Blender, retargeted with Mixamo BoneMap.tres) gets its
# animations from the Open Animation Libraries; they are mapped onto the kit's set.
const LIBRARIES = {
	"melee": "res://Libraries/MeleeLib.res",
	"shooter": "res://Libraries/ShooterLib.res",
}
const ANIMATION_MAP = {
	"Idle": "shooter/idle",
	"Run": "melee/LightRunning",
	"Jump": "melee/Jump",
	"Flip": "melee/Roll",
	"Hurt": "melee/Hurt1",
	"Wave": "shooter/handsup-idle",
}
const LOOPING = ["Idle", "Run", "Wave"]

# Booleans
var is_grounded = false
var can_double_jump = false
var is_locked = false # Input disabled while respawning / celebrating

# Onready Variables
@onready var model = $Student
@onready var animation = $Student/AnimationPlayer
@onready var spring_arm = %Gimbal

@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

# ---------- FUNCTIONS ---------- #

func _ready():
	setup_animations()

# Load the animation libraries and copy the needed clips under the starter kit's names
func setup_animations():
	for lib_name in LIBRARIES:
		animation.add_animation_library(lib_name, load(LIBRARIES[lib_name]))
	var library = AnimationLibrary.new()
	for kit_name in ANIMATION_MAP:
		var anim: Animation = animation.get_animation(ANIMATION_MAP[kit_name]).duplicate()
		anim.loop_mode = Animation.LOOP_LINEAR if kit_name in LOOPING else Animation.LOOP_NONE
		library.add_animation(kit_name, anim)
	animation.add_animation_library("kit", library)
	play_anim("Idle")

func play_anim(anim_name, blend = -1.0, speed = 1.0):
	animation.play("kit/" + anim_name, blend, speed)

func _process(delta):
	player_animations()
	get_input(delta)

	# Smoothly follow player's position
	spring_arm.position = lerp(spring_arm.position, position, delta * follow_lerp_factor)

	# Player Rotation
	if is_moving():
		var look_direction = Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12)
		if spring_arm.auto_rotate:
			spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, look_direction.angle()-deg_to_rad(180), delta*0.4)
			spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, deg_to_rad(0), delta*0.4)

	# Check if player is grounded or not
	is_grounded = true if is_on_floor() else false

	# Handle Jumping
	if is_grounded:
		can_double_jump = true

	if Input.is_action_just_pressed("jump") and not is_locked:
		if is_on_floor():
			perform_jump()
		elif can_double_jump:
			if is_moving():
				perform_flip_jump()

	velocity.y -= gravity * delta

func perform_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 1.12

	jumpTween()
	play_anim("Jump")
	velocity.y = jump_force

func perform_flip_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 0.8
	play_anim("Flip", -1, 2)
	velocity.y = jump_force
	can_double_jump = false

func is_moving():
	return abs(velocity.z) > 0 || abs(velocity.x) > 0

func jumpTween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", jumpStretchSize, 0.1)
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.1)

# Get Player Input
func get_input(_delta):
	var move_direction := Vector3.ZERO
	if not is_locked:
		move_direction.x = Input.get_axis("move_left", "move_right")
		move_direction.z = Input.get_axis("move_forward", "move_back")

	# Move The player Towards Spring Arm/Camera Rotation
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity = Vector3(move_direction.x * move_speed, velocity.y, move_direction.z * move_speed)

	move_and_slide()

# Handle Player Animations
func player_animations():
	particle_trail.emitting = false
	footsteps.stream_paused = true
	if is_locked:
		return

	if is_on_floor():
		if is_moving(): # Checks if player is moving
			play_anim("Run", 0.5)
			particle_trail.emitting = true
			footsteps.stream_paused = false
		else:
			play_anim("Idle", 0.5)

# Called by traps and the dead zone: flash, then return to the spawn point
func respawn():
	if is_locked:
		return
	is_locked = true
	GameManager.deaths += 1
	play_anim("Hurt")
	await get_tree().create_timer(0.5).timeout
	var spawn = get_tree().get_first_node_in_group("Spawn")
	global_position = spawn.global_position
	velocity = Vector3.ZERO
	spring_arm.position = position
	is_locked = false

# Called by the door when the level is finished
func celebrate():
	is_locked = true
	play_anim("Wave")
