extends Control
## Row of hearts showing the barbarian's health.

const SPACING := 28.0
const FULL := Color(0.9, 0.15, 0.2)
const EMPTY := Color(0.25, 0.1, 0.12, 0.7)
const OUTLINE := Color(0.1, 0.02, 0.04)

var health := 3
var max_health := 3


func set_health(current: int, maximum: int) -> void:
	health = current
	max_health = maximum
	queue_redraw()


func _draw() -> void:
	for i in max_health:
		var center := Vector2(12 + i * SPACING, 12)
		_draw_heart(center, 1.15, OUTLINE)
		_draw_heart(center, 1.0, FULL if i < health else EMPTY)
		if i < health:
			draw_circle(center + Vector2(-4.5, -4), 1.8, Color(1, 1, 1, 0.7))


func _draw_heart(center: Vector2, scale_factor: float, color: Color) -> void:
	var s := scale_factor
	draw_circle(center + Vector2(-5, -3) * s, 6.0 * s, color)
	draw_circle(center + Vector2(5, -3) * s, 6.0 * s, color)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-10.6, -1) * s,
		center + Vector2(10.6, -1) * s,
		center + Vector2(0, 11) * s]), color)
