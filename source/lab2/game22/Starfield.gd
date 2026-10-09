extends Node2D

# Scrolling starfield background drawn in code.
const STAR_COUNT = 120
var stars = []
var size

func _ready():
	size = get_viewport_rect().size
	for i in STAR_COUNT:
		stars.append({
			"pos": Vector2(randf() * size.x, randf() * size.y),
			"speed": randf_range(20.0, 120.0),
			"r": randf_range(0.6, 2.2),
		})

func _process(delta):
	for s in stars:
		s.pos.y += s.speed * delta
		if s.pos.y > size.y:
			s.pos = Vector2(randf() * size.x, 0)
	queue_redraw()

func _draw():
	draw_circle(Vector2(400, 120), 60, Color(0.85, 0.45, 0.3))
	draw_circle(Vector2(385, 105), 18, Color(0.75, 0.38, 0.25))
	draw_circle(Vector2(70, 240), 28, Color(0.4, 0.6, 0.95, 0.8))
	for s in stars:
		draw_circle(s.pos, s.r, Color(1, 1, 1, clamp(s.speed / 120.0, 0.3, 1.0)))
