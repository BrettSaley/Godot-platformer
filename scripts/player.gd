extends Node2D
## Top-down barbarian. Moves with WASD/arrows; hold Shift to move slowly for
## precise dodging (which also reveals the hitbox).

const BASE_SPEED := 260.0
const FOCUS_SPEED_MULT := 0.45
const BASE_HITBOX_RADIUS := 5.0
const ARENA_MIN := Vector2(16, 24)
const ARENA_MAX := Vector2(944, 516)

var speed: float
var focus_speed: float
var hitbox_radius: float

var invulnerable_timer := 0.0
var hitbox: Polygon2D
var facing := 1.0
var walk_time := 0.0
var moving := false


func _ready() -> void:
	speed = BASE_SPEED * (1.0 + 0.12 * GameState.stacks("swift_feet"))
	focus_speed = speed * FOCUS_SPEED_MULT * (1.0 + 0.25 * GameState.stacks("steady_focus"))
	hitbox_radius = BASE_HITBOX_RADIUS * pow(0.85, GameState.stacks("small_target"))
	_add_hitbox_marker()


func _physics_process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("move_left", "move_right") + Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("move_up", "move_down") + Input.get_axis("ui_up", "ui_down")
	).limit_length(1.0)
	var focused := Input.is_action_pressed("focus")
	position += input * (focus_speed if focused else speed) * delta
	position = position.clamp(ARENA_MIN, ARENA_MAX)
	hitbox.visible = focused

	moving = input != Vector2.ZERO
	if input.x != 0.0:
		facing = signf(input.x)
	walk_time = walk_time + delta if moving else 0.0
	queue_redraw()

	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
		modulate.a = 0.35 if int(invulnerable_timer * 12.0) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0


func can_be_hit() -> bool:
	return invulnerable_timer <= 0.0


func make_invulnerable(duration: float) -> void:
	invulnerable_timer = duration


## Bobs and waddles while moving, and faces the way it last moved.
func _draw() -> void:
	var bob := -absf(sin(walk_time * 14.0)) * 2.5 if moving else sin(Time.get_ticks_msec() / 400.0) * 0.6
	var waddle := sin(walk_time * 14.0) * 0.08 if moving else 0.0
	BarbarianArt.draw(self, BarbarianArt.HERO, bob, waddle, facing)


## A small dot showing the real hitbox, shown while focusing (Shift).
func _add_hitbox_marker() -> void:
	hitbox = Polygon2D.new()
	var points := PackedVector2Array()
	for i in 16:
		points.append(Vector2.from_angle(TAU * i / 16.0) * hitbox_radius)
	hitbox.polygon = points
	hitbox.color = Color(1, 1, 1)
	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 1.5
	outline.default_color = Color(0.8, 0.1, 0.1)
	hitbox.add_child(outline)
	add_child(hitbox)
