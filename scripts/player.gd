extends CharacterBody2D

const SPEED = 300.0
const BASE_JUMP_VELOCITY = -400.0
const JUMP_VELOCITY_INCREMENT = -40.0
const MAX_JUMP_COMBO = 5
const JUMP_COMBO_RESET_TIME = 2.0

var jump_combo := 0
var time_since_last_jump := JUMP_COMBO_RESET_TIME + 1.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

	time_since_last_jump += delta

	var jump_pressed := Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("jump")
	if jump_pressed and is_on_floor():
		if time_since_last_jump > JUMP_COMBO_RESET_TIME:
			jump_combo = 0
		jump_combo = mini(jump_combo + 1, MAX_JUMP_COMBO)
		velocity.y = BASE_JUMP_VELOCITY + JUMP_VELOCITY_INCREMENT * (jump_combo - 1)
		time_since_last_jump = 0.0

	var direction := clampf(Input.get_axis("ui_left", "ui_right") + Input.get_axis("move_left", "move_right"), -1.0, 1.0)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
