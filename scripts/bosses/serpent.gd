extends Boss
## Horned viking sea serpent. Its long body snakes around the arena and every
## segment hurts to touch. Spits aimed rocks, fires rocks sideways out of its
## scales, or coils up and bursts a ring from its head.

const SEGMENTS := 14
const SPACING := 16.0
const TURN_RATE := 2.2
const SPIT_STONE := Color(0.45, 0.55, 0.5)
const SCALE_STONE := Color(0.35, 0.45, 0.48)
const RING_STONE := Color(0.5, 0.5, 0.56)

var segments: Array[Vector2] = []
var heading := PI / 2.0
var scale_wave := 0


func _init() -> void:
	display_name = "World Serpent"
	radius = 16.0
	move_speed = 110.0


func _on_setup() -> void:
	position = Vector2(480, 60)
	# The body starts trailing off the top of the screen and slithers in.
	for i in SEGMENTS:
		segments.append(position + Vector2(0, -SPACING * (i + 1)))


func segment_radius(i: int) -> float:
	return lerpf(14.0, 6.0, i / float(SEGMENTS - 1))


func _attacks() -> Array:
	return ["spit", "scales", "coil"]


func _move(delta: float) -> void:
	if position.distance_to(target) < 40.0:
		target = pick_wander_target()
	heading = rotate_toward(heading, (target - position).angle(), TURN_RATE * delta)
	var wiggle := sin(time * 4.0) * 0.6
	position += Vector2.from_angle(heading + wiggle) * move_speed * delta

	# Each segment is pulled along behind the one in front of it.
	for i in SEGMENTS:
		var leader := position if i == 0 else segments[i - 1]
		var offset := segments[i] - leader
		if offset.length() > SPACING:
			segments[i] = leader + offset.normalized() * SPACING


func _touches(point: Vector2, other_radius: float) -> bool:
	if super._touches(point, other_radius):
		return true
	for i in SEGMENTS:
		if segments[i].distance_to(point) < segment_radius(i) + other_radius:
			return true
	return false


func _fire(attack_name: String) -> float:
	var d := difficulty
	match attack_name:
		"spit":
			fan(position, dir_to_player(position), 1 + int(d * 1.99), 0.22, lerpf(120, 170, d), 6.0, SPIT_STONE)
			return lerpf(0.8, 0.45, d)
		"scales":
			# A wave of rocks fired sideways from every third segment.
			scale_wave = (scale_wave + 1) % 3
			for i in range(scale_wave + 1, SEGMENTS, 3):
				var side := (segments[i - 1] - segments[i]).orthogonal().normalized()
				var speed := lerpf(60, 95, d)
				shoot(segments[i], side * speed, 5.0, SCALE_STONE)
				shoot(segments[i], -side * speed, 5.0, SCALE_STONE)
			return lerpf(0.6, 0.35, d)
		"coil":
			ring(position, int(lerpf(10, 20, d)), lerpf(80, 120, d), 6.0, RING_STONE)
			return lerpf(1.0, 0.6, d)
	return 1.0


func _draw() -> void:
	var scale_a := Color(0.2, 0.5, 0.45)
	var scale_b := Color(0.16, 0.42, 0.4)
	var belly := Color(0.75, 0.8, 0.55)
	var outline := Color(0.06, 0.15, 0.14)

	# Body, tail first so the head sits on top.
	for i in range(SEGMENTS - 1, -1, -1):
		var p := segments[i] - position
		var r := segment_radius(i)
		draw_circle(p, r + 1.5, outline)
		draw_circle(p, r, scale_a if i % 2 == 0 else scale_b)
		draw_circle(p, r * 0.4, belly)
	# Tail fin
	var tail := segments[SEGMENTS - 1] - position
	var tail_dir := (segments[SEGMENTS - 1] - segments[SEGMENTS - 2]).normalized()
	draw_colored_polygon(PackedVector2Array([
		tail + tail_dir.orthogonal() * 7, tail + tail_dir * 16, tail - tail_dir.orthogonal() * 7]), scale_b)

	# Head, pointing along its heading
	var mouth_open := attack in ["spit", "coil"] and fire_timer > 0.3
	draw_set_transform(Vector2.ZERO, heading)
	# Viking horns sweeping back
	var horn := Color(0.95, 0.9, 0.75)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -12), Vector2(-20, -24), Vector2(-10, -12), Vector2(-4, -8)]), horn)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 12), Vector2(-20, 24), Vector2(-10, 12), Vector2(-4, 8)]), horn)
	draw_circle(Vector2.ZERO, 17.5, outline)
	draw_circle(Vector2.ZERO, 16.0, scale_a)
	draw_circle(Vector2(12, 0), 11.5, outline)
	draw_circle(Vector2(12, 0), 10.0, scale_a)
	if mouth_open:
		draw_colored_polygon(PackedVector2Array([Vector2(12, -5), Vector2(24, -8), Vector2(24, 8), Vector2(12, 5)]), Color(0.6, 0.1, 0.12))
	# Fangs
	draw_colored_polygon(PackedVector2Array([Vector2(17, -5), Vector2(21, -5), Vector2(19, 0)]), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(17, 5), Vector2(21, 5), Vector2(19, 0)]), Color(1, 1, 1))
	# Nostrils and slit-pupil eyes
	draw_circle(Vector2(19, -3), 1.2, outline)
	draw_circle(Vector2(19, 3), 1.2, outline)
	var glow := Color(1, 0.85, 0.2) if is_attacking() else Color(0.85, 0.75, 0.3)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(3, 8 * side), 4.0, glow)
		draw_line(Vector2(3, 8 * side - 3), Vector2(3, 8 * side + 3), outline, 1.5)
		draw_line(Vector2(-2, 12 * side), Vector2(7, 5 * side), outline, 2.0)
	draw_set_transform(Vector2.ZERO)
