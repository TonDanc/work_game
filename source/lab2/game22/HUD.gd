extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game

func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()

func show_game_over():
	show_message("ยานแตก! Game Over")
	await $MessageTimer.timeout
	$Message.text = "SPACE DODGE\nหลบให้รอด!"
	$Message.show()
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

func update_score(score, best):
	$ScoreLabel.text = str(score)
	$BestLabel.text = "Best: " + str(best)

func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout():
	$Message.hide()

func _unhandled_input(event):
	if $StartButton.visible and event.is_action_pressed("ui_accept"):
		_on_start_button_pressed()
