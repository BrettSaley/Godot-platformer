class_name Boss
extends Node2D
## Base for the bosses that appear every third level. Handles the attack cycle
## (attack for a few seconds, rest, pick another attack), touch damage, and
## firing helpers. Each boss in scripts/bosses/ overrides:
##   _attacks()   which attack names it can use
##   _fire(name)  fire one volley, return seconds until the next
##   _move(delta) how it moves (defaults to wandering)
##   _draw()      how it looks
## Later bosses (higher boss_number) move faster and fire denser patterns.

signal touched_player

const ARENA_MIN := Vector2(60, 60)
const ARENA_MAX := Vector2(900, 480)
const ATTACK_DURATION := 3.0

var display_name := "Boss"
var radius := 30.0
var boss_number: int
var difficulty: float
## Projectile and movement speed multiplier (includes Slow Motion power-up).
var speed_mult: float
var move_speed := 80.0

## Set by the main scene via setup().
var bullets: Node2D
var player: Node2D

var target: Vector2
var attack := ""
var attack_timer := 0.0
var rest_timer := 1.0
var fire_timer := 0.0
var time := 0.0


func setup(level: int, bullet_layer: Node2D, target_player: Node2D) -> void:
	boss_number = level / 3
	bullets = bullet_layer
	player = target_player
	difficulty = clampf((boss_number - 1) / 6.0, 0.0, 1.0)
	speed_mult = pow(0.92, GameState.stacks("slow_motion"))
	move_speed *= lerpf(1.0, 1.8, difficulty) * speed_mult
	position = Vector2(480, 90)
	target = pick_wander_target()
	_on_setup()


func is_attacking() -> bool:
	return rest_timer <= 0.0 and attack_timer > 0.0


func _physics_process(delta: float) -> void:
	time += delta
	queue_redraw()
	_move(delta)

	if player.can_be_hit() and _touches(player.position, player.hitbox_radius):
		touched_player.emit()

	if rest_timer > 0.0:
		rest_timer -= delta
		if rest_timer <= 0.0:
			var options := _attacks()
			attack = options[randi() % options.size()]
			attack_timer = ATTACK_DURATION
			fire_timer = 0.0
			_on_attack_started(attack)
		return

	attack_timer -= delta
	if attack_timer <= 0.0:
		rest_timer = lerpf(1.2, 0.5, difficulty)
		attack = ""
		return

	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = _fire(attack)


# --- Overridable hooks ---

func _on_setup() -> void:
	pass


func _attacks() -> Array:
	return ["ring"]


func _on_attack_started(_name: String) -> void:
	pass


func _fire(_name: String) -> float:
	return 1.0


## Default movement: drift between random points away from the player.
func _move(delta: float) -> void:
	position = position.move_toward(target, move_speed * delta)
	if position.distance_to(target) < 4.0:
		target = pick_wander_target()


func _touches(point: Vector2, other_radius: float) -> bool:
	return position.distance_to(point) < radius + other_radius


# --- Helpers ---

func pick_wander_target() -> Vector2:
	for attempt in 10:
		var point := Vector2(randf_range(ARENA_MIN.x, ARENA_MAX.x), randf_range(ARENA_MIN.y, ARENA_MAX.y))
		if point.distance_to(player.position) > 180.0:
			return point
	return Vector2(480, 90)


func shoot(from: Vector2, velocity: Vector2, size: float, color: Color) -> void:
	bullets.spawn(from, velocity * speed_mult, size, color)


func ring(from: Vector2, count: int, speed: float, size: float, color: Color) -> void:
	var offset := randf() * TAU
	for i in count:
		shoot(from, Vector2.from_angle(offset + TAU * i / count) * speed, size, color)


## A spread of `2 * side + 1` projectiles centred on `dir`.
func fan(from: Vector2, dir: Vector2, side: int, spread: float, speed: float, size: float, color: Color) -> void:
	for i in range(-side, side + 1):
		shoot(from, dir.rotated(i * spread) * speed, size, color)


func dir_to_player(from: Vector2) -> Vector2:
	return (player.position - from).normalized()
