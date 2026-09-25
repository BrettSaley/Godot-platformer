extends Node2D
## Grassy meadow background, scattered fresh each level. Drawn once.

const ARENA := Vector2(960, 540)
const GRASS := Color(0.36, 0.58, 0.27)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ARENA), GRASS)

	# Soft light and dark patches so the field isn't flat.
	for i in 40:
		var shade := GRASS.lightened(0.07) if randf() < 0.5 else GRASS.darkened(0.08)
		_draw_blob(_random_point(), randf_range(30, 80), shade)

	# Grass tufts
	for i in 260:
		var p := _random_point()
		var color := GRASS.darkened(randf_range(0.15, 0.3)) if randf() < 0.6 else GRASS.lightened(0.2)
		for blade in [-1.0, 0.0, 1.0]:
			draw_line(p, p + Vector2(blade * 2.5 + randf_range(-1, 1), -randf_range(4, 7)), color, 1.2)

	# Little flowers
	var petals := [Color(1, 1, 1), Color(1, 0.85, 0.3), Color(1, 0.6, 0.75)]
	for i in 45:
		var p := _random_point()
		var petal: Color = petals[randi() % petals.size()]
		for k in 5:
			draw_circle(p + Vector2.from_angle(TAU * k / 5.0) * 2.2, 1.6, petal)
		draw_circle(p, 1.2, Color(0.95, 0.7, 0.2))


func _draw_blob(center: Vector2, radius: float, color: Color) -> void:
	draw_set_transform(center, randf() * TAU, Vector2(1.0, randf_range(0.5, 0.9)))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO)


func _random_point() -> Vector2:
	return Vector2(randf() * ARENA.x, randf() * ARENA.y)
