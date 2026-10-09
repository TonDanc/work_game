extends Node3D

# Character showcase: plays animations from the Open Animation Libraries
# (MeleeLib / ShooterLib) on the Blender-made character.

const LIBRARIES = {
	"melee": "res://Libraries/MeleeLib.res",
	"shooter": "res://Libraries/ShooterLib.res",
}

# Curated in-place animations shown as buttons: [label, library/animation]
const MOVES = {
	"ท่าพื้นฐาน": [
		["ยืนพัก", "shooter/idle"],
		["เดิน", "shooter/walk"],
		["วิ่ง", "melee/LightRunning"],
		["วิ่งเร็ว", "melee/Sprint"],
		["กระโดด", "melee/Jump"],
		["กลิ้งหลบ", "melee/Roll"],
		["ย่อตัวเดิน", "shooter/crouch-walk"],
		["คลาน", "shooter/prone-crawl"],
		["ปีนข้าม", "shooter/vault-1m"],
	],
	"Melee": [
		["ฟัน 1", "melee/Slash1"],
		["ฟัน 2", "melee/Slash2"],
		["ฟัน 3", "melee/Slash3"],
		["ฟันหนัก", "melee/Heavy1"],
		["หมุนฟัน", "melee/HeavySpin"],
		["อัปเปอร์คัต", "melee/SlashUppercut"],
		["กระแทกโล่", "melee/ShieldBash"],
		["ตั้งการ์ด", "melee/Guarding"],
		["ขว้างของ", "melee/ThrowR"],
		["ดื่มยา", "melee/UsePotion"],
		["เปิดหีบ", "melee/OpenChest"],
	],
	"Shooter": [
		["เล็งปืน", "shooter/aim-rifle"],
		["ยิงปืน", "shooter/shoot-rifle-light"],
		["รีโหลด", "shooter/reload-rifle"],
		["ต่อย", "shooter/punch1"],
		["เตะ", "shooter/kick1"],
		["ยกมือยอม", "shooter/handsup-idle"],
		["ยักไหล่", "shooter/search-shrug"],
		["ตกใจ", "shooter/search-surprise"],
		["โดนตี", "shooter/hurt1"],
		["ล้ม", "shooter/die1"],
	],
}

@onready var anim: AnimationPlayer = $Student/AnimationPlayer
@onready var pivot: Node3D = $CameraPivot
@onready var now_playing: Label = $UI/NowPlaying
@onready var tabs: TabContainer = $UI/Panel/Tabs

var dragging := false
var auto_spin := true

func _ready():
	for lib_name in LIBRARIES:
		anim.add_animation_library(lib_name, load(LIBRARIES[lib_name]))
	for group in MOVES:
		var grid := GridContainer.new()
		grid.name = group
		grid.columns = 2
		tabs.add_child(grid)
		for move in MOVES[group]:
			if not anim.has_animation(move[1]):
				push_warning("missing animation " + move[1])
				continue
			var b := Button.new()
			b.text = move[0]
			b.custom_minimum_size = Vector2(150, 44)
			b.add_theme_font_size_override("font_size", 20)
			b.pressed.connect(play.bind(move[0], move[1]))
			grid.add_child(b)
	play("ยืนพัก", "shooter/idle")

func play(label: String, anim_name: String):
	var a := anim.get_animation(anim_name)
	# Loop locomotion/idle clips, play actions once and then return to idle
	var looping := anim_name.contains("idle") or anim_name.contains("walk") or anim_name.contains("Running") \
		or anim_name.contains("Sprint") or anim_name.contains("crawl") or anim_name == "melee/Guarding"
	a.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	anim.play(anim_name, 0.25)
	now_playing.text = "ท่า: %s  (%s)" % [label, anim_name]
	if not looping:
		await anim.animation_finished
		if anim.current_animation == "" or anim.current_animation == anim_name:
			play("ยืนพัก", "shooter/idle")

func _process(delta):
	if auto_spin:
		pivot.rotation.y += delta * 0.3

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			auto_spin = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			$CameraPivot/Camera3D.position.z = max(1.5, $CameraPivot/Camera3D.position.z - 0.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			$CameraPivot/Camera3D.position.z = min(6.0, $CameraPivot/Camera3D.position.z + 0.2)
	elif event is InputEventMouseMotion and dragging:
		pivot.rotation.y -= event.relative.x * 0.01
		pivot.rotation.x = clamp(pivot.rotation.x - event.relative.y * 0.005, -0.8, 0.3)

func _on_spin_toggled(on: bool):
	auto_spin = on
