extends CharacterBody2D

const BASE_SPEED = 300.0
const BASE_JUMP_VELOCITY = -550.0

var speed: float
var jump_velocity: float
var gravity: float
var max_air_jumps: int
var coyote_time: float

var air_jumps_left := 0
var coyote_timer := 0.0


func _ready() -> void:
	speed = BASE_SPEED * (1.0 + 0.12 * GameState.stacks("swift_feet"))
	jump_velocity = BASE_JUMP_VELOCITY * (1.0 + 0.08 * GameState.stacks("spring_legs"))
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * pow(0.92, GameState.stacks("feather"))
	max_air_jumps = GameState.stacks("double_jump")
	coyote_time = 0.1 * GameState.stacks("coyote")


func _physics_process(delta: float) -> void:
	if is_on_floor():
		air_jumps_left = max_air_jumps
		coyote_timer = coyote_time
	else:
		velocity.y += gravity * delta
		coyote_timer -= delta

	var jump_pressed := Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("jump")
	if jump_pressed:
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = jump_velocity
			coyote_timer = 0.0
		elif air_jumps_left > 0:
			velocity.y = jump_velocity
			air_jumps_left -= 1

	var direction := clampf(Input.get_axis("ui_left", "ui_right") + Input.get_axis("move_left", "move_right"), -1.0, 1.0)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
