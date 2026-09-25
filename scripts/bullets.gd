extends Node2D
## Every projectile lives in these arrays instead of being its own node,
## so the screen can fill up without slowing the game down.
## Projectiles are drawn as tumbling rocks; collision is still a circle.

signal player_hit

const BOUNDS := Rect2(-40, -40, 1040, 620)
const ROCK_SHAPES := 4
const OUTLINE := Color(0.16, 0.13, 0.1)

var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var radii := PackedFloat32Array()
var colors := PackedColorArray()
var angles := PackedFloat32Array()
var spins := PackedFloat32Array()
var shapes := PackedInt32Array()

## Set by the main scene.
var player: Node2D

## Lumpy unit-radius outlines, picked at random for each rock.
var rock_shapes: Array[PackedVector2Array] = []


func _ready() -> void:
	for s in ROCK_SHAPES:
		var points := PackedVector2Array()
		var corners := randi_range(6, 8)
		for i in corners:
			var angle := TAU * i / corners + randf_range(-0.25, 0.25)
			points.append(Vector2.from_angle(angle) * randf_range(0.8, 1.15))
		rock_shapes.append(points)


func spawn(pos: Vector2, vel: Vector2, radius := 6.0, color := Color(0.6, 0.6, 0.62)) -> void:
	positions.append(pos)
	velocities.append(vel)
	radii.append(radius)
	colors.append(color)
	angles.append(randf() * TAU)
	spins.append(randf_range(-4.0, 4.0))
	shapes.append(randi() % ROCK_SHAPES)


func clear_all() -> void:
	positions.clear()
	velocities.clear()
	radii.clear()
	colors.clear()
	angles.clear()
	spins.clear()
	shapes.clear()
	queue_redraw()


func _physics_process(delta: float) -> void:
	var hit := false
	var i := positions.size() - 1
	while i >= 0:
		positions[i] += velocities[i] * delta
		angles[i] += spins[i] * delta
		if not BOUNDS.has_point(positions[i]):
			_remove(i)
		elif not hit and player.can_be_hit() \
				and positions[i].distance_to(player.position) < radii[i] + player.hitbox_radius:
			_remove(i)
			hit = true
		i -= 1
	queue_redraw()
	if hit:
		player_hit.emit()


func _remove(i: int) -> void:
	var last := positions.size() - 1
	positions[i] = positions[last]
	velocities[i] = velocities[last]
	radii[i] = radii[last]
	colors[i] = colors[last]
	angles[i] = angles[last]
	spins[i] = spins[last]
	shapes[i] = shapes[last]
	positions.resize(last)
	velocities.resize(last)
	radii.resize(last)
	colors.resize(last)
	angles.resize(last)
	spins.resize(last)
	shapes.resize(last)


func _draw() -> void:
	for i in positions.size():
		var r := radii[i] * 1.15
		var shape := rock_shapes[shapes[i]]
		var color := colors[i]
		draw_set_transform(positions[i], angles[i], Vector2(r + 1.5, r + 1.5))
		draw_colored_polygon(shape, OUTLINE)
		draw_set_transform(positions[i], angles[i], Vector2(r, r))
		draw_colored_polygon(shape, color)
		# Lighting stays fixed (top-left) while the rock spins.
		draw_set_transform(positions[i], 0.0, Vector2(r, r))
		draw_circle(Vector2(-0.3, -0.3), 0.35, color.lightened(0.35))
		draw_circle(Vector2(0.35, 0.4), 0.2, color.darkened(0.3))
	draw_set_transform(Vector2.ZERO)
