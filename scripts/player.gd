extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -550.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

	var jump_pressed := Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("jump")
	if jump_pressed and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := clampf(Input.get_axis("ui_left", "ui_right") + Input.get_axis("move_left", "move_right"), -1.0, 1.0)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
