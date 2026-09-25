extends Boss
## Grizzly bear. Plants its feet and slams the ground (rings of rocks),
## hurls big boulders at the player, or winds up and charges, scattering
## rocks wherever it skids to a stop.

const STONE := Color(0.58, 0.5, 0.42)
const BOULDER := Color(0.5, 0.45, 0.4)
const CHARGE_WINDUP := 0.45

var charge_target: Vector2
var windup_timer := 0.0
var slam_anim := 0.0
var facing := 1.0


func _init() -> void:
	display_name = "Grizzly Bear"
	radius = 30.0
	move_speed = 70.0


func _attacks() -> Array:
	return ["slam", "boulders", "charge"]


func _on_attack_started(attack_name: String) -> void:
	if attack_name == "charge":
		_aim_charge()


func _aim_charge() -> void:
	# Aim a little past the player so standing still isn't safe.
	var past := player.position + dir_to_player(position) * 60.0
	charge_target = past.clamp(ARENA_MIN, ARENA_MAX)
	windup_timer = CHARGE_WINDUP


func _move(delta: float) -> void:
	slam_anim = maxf(slam_anim - delta * 4.0, 0.0)
	var before := position
	match attack:
		"slam":
			pass  # feet planted
		"charge":
			if windup_timer > 0.0:
				windup_timer -= delta
			else:
				position = position.move_toward(charge_target, move_speed * 3.2 * delta)
				if position.distance_to(charge_target) < 4.0:
					slam_anim = 1.0
					ring(position, int(lerpf(6, 12, difficulty)), lerpf(80, 120, difficulty), 6.0, STONE)
					_aim_charge()
		_:
			super._move(delta)
	if absf(position.x - before.x) > 0.1:
		facing = signf(position.x - before.x)


func _fire(attack_name: String) -> float:
	var d := difficulty
	match attack_name:
		"slam":
			slam_anim = 1.0
			ring(position, int(lerpf(12, 24, d)), lerpf(80, 130, d), 7.0, STONE)
			return lerpf(1.1, 0.6, d)
		"boulders":
			fan(position, dir_to_player(position), int(d * 1.99), 0.3, lerpf(100, 140, d), 11.0, BOULDER)
			return lerpf(0.9, 0.55, d)
	return 99.0  # charge fires on landing instead


func _draw() -> void:
	var fur := Color(0.45, 0.29, 0.17)
	var fur_dark := Color(0.33, 0.2, 0.11)
	var tan := Color(0.72, 0.55, 0.36)
	var dark := Color(0.12, 0.07, 0.05)

	draw_set_transform(Vector2(0, 34), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.3))

	var shake := Vector2(randf_range(-2, 2), 0) if windup_timer > 0.0 else Vector2.ZERO
	var squash := Vector2(facing * (1.0 + slam_anim * 0.15), 1.0 - slam_anim * 0.12)
	draw_set_transform(shake + Vector2(0, slam_anim * 3.0), 0.0, squash)

	# Feet and body
	draw_circle(Vector2(-12, 30), 7.0, fur_dark)
	draw_circle(Vector2(12, 30), 7.0, fur_dark)
	draw_circle(Vector2(0, 12), 22.0, fur)
	draw_circle(Vector2(0, 16), 13.0, tan)
	# Paws with claws, raised during a slam
	var paw_y := 14.0 - slam_anim * 10.0
	for side in [-1.0, 1.0]:
		var paw := Vector2(side * 22, paw_y)
		draw_circle(paw, 8.0, fur_dark)
		for c in 3:
			var claw := paw + Vector2((c - 1) * 3.5, 6)
			draw_line(claw, claw + Vector2(0, 3.5), Color(0.95, 0.92, 0.85), 1.6)

	# Ears and head
	draw_circle(Vector2(-16, -24), 8.0, fur)
	draw_circle(Vector2(16, -24), 8.0, fur)
	draw_circle(Vector2(-16, -24), 4.0, Color(0.6, 0.4, 0.35))
	draw_circle(Vector2(16, -24), 4.0, Color(0.6, 0.4, 0.35))
	draw_circle(Vector2(0, -10), 19.0, fur)
	# Muzzle, nose and snarl
	draw_circle(Vector2(0, -2), 9.0, tan)
	draw_set_transform(shake + Vector2(0, slam_anim * 3.0) + Vector2(0, -6) * squash, 0.0, squash * Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, 4.5, dark)
	draw_set_transform(shake + Vector2(0, slam_anim * 3.0), 0.0, squash)
	draw_line(Vector2(-5, 3), Vector2(5, 3), dark, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 3), Vector2(-2, 3), Vector2(-3, 6.5)]), Color(1, 1, 1))
	draw_colored_polygon(PackedVector2Array([Vector2(2, 3), Vector2(4, 3), Vector2(3, 6.5)]), Color(1, 1, 1))
	# Eyes glow red while attacking, under angry brows
	var eye := Color(0.9, 0.15, 0.1) if is_attacking() else dark
	draw_circle(Vector2(-8, -15), 3.0, eye)
	draw_circle(Vector2(8, -15), 3.0, eye)
	draw_line(Vector2(-13, -21), Vector2(-4, -17), dark, 2.5)
	draw_line(Vector2(13, -21), Vector2(4, -17), dark, 2.5)
	# Scar across one eye
	draw_line(Vector2(5, -22), Vector2(11, -9), Color(0.75, 0.5, 0.45), 1.5)
	draw_set_transform(Vector2.ZERO)
