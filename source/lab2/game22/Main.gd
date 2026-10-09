extends Node

@export var mob_scene: PackedScene
var score
var best = 0

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	score = 0
	$MobTimer.wait_time = 0.5
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score, best)
	$HUD.show_message("เตรียมตัว...")
	get_tree().call_group("mobs", "queue_free")
	$Music.play()

func _on_mob_timer_timeout():
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Mobs get faster as the score rises.
	var velocity = Vector2(randf_range(150.0, 250.0) + score * 4, 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)

func _on_score_timer_timeout():
	score += 1
	best = max(best, score)
	$HUD.update_score(score, best)
	# Spawn more often over time.
	$MobTimer.wait_time = max(0.25, 0.5 - score * 0.005)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
