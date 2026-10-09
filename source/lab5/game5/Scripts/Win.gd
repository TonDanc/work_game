extends Control

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Center/VBox/Stats.text = "พลาดไปทั้งหมด %d ครั้ง" % GameManager.deaths
	$Center/VBox/Restart.grab_focus()

func _on_restart_pressed():
	GameManager.restart_game()
