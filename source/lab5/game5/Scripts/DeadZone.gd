extends Area3D

# ---------- SIGNALS ---------- #

func _on_body_entered(body):
	# Checks if player fell into the dead zone & sends them back to the spawn point
	if body.is_in_group("Player"):
		body.respawn()
