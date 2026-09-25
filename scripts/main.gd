extends Node2D

const SKY_COLOR := Color(0.55, 0.8, 0.92)

@onready var level_root: Node2D = $Level
@onready var player: CharacterBody2D = $Player
@onready var message_label: Label = $UI/MessageLabel
@onready var message_timer: Timer = $UI/MessageTimer
@onready var level_label: Label = $UI/LevelLabel
@onready var powerups_label: Label = $UI/PowerupsLabel

var start_position: Vector2
var level_over := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(SKY_COLOR)
	message_timer.timeout.connect(_on_message_timer_timeout)

	var level := LevelGenerator.generate(level_root, GameState.level)
	start_position = level.start
	level.star.body_entered.connect(_on_star_body_entered)
	level.lava.body_entered.connect(_on_lava_body_entered)

	respawn_player()
	update_hud()
	show_message("Level %d" % GameState.level)


func _on_lava_body_entered(body: Node) -> void:
	if body == player and not level_over:
		die()


func die() -> void:
	if GameState.stacks("extra_life") > 0:
		GameState.consume_powerup("extra_life")
		update_hud()
		show_message("Extra Life used!")
		respawn_player()
		return

	level_over = true
	show_message("You Died on level %d" % GameState.level)
	player.hide()
	player.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	GameState.reset_run()
	get_tree().reload_current_scene()


func _on_star_body_entered(body: Node) -> void:
	if body == player and not level_over:
		level_over = true
		show_powerup_choice()


func show_powerup_choice() -> void:
	get_tree().paused = true

	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)

	var title := Label.new()
	title.text = "Level %d complete! Choose a power-up" % GameState.level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)

	var buttons: Array[Button] = []
	for id in GameState.random_choices(3):
		var info: Dictionary = GameState.POWERUPS[id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 140)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = "%s\n\n%s" % [info.name, info.desc]
		if GameState.stacks(id) > 0:
			button.text += "\n(have %d)" % GameState.stacks(id)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_on_powerup_chosen.bind(id))
		row.add_child(button)
		buttons.append(button)
	buttons[0].grab_focus()


func _on_powerup_chosen(id: String) -> void:
	GameState.add_powerup(id)
	GameState.level += 1
	get_tree().paused = false
	get_tree().reload_current_scene()


func respawn_player() -> void:
	player.global_position = start_position
	player.velocity = Vector2.ZERO


func update_hud() -> void:
	level_label.text = "Level %d" % GameState.level
	var lines: Array[String] = []
	for id in GameState.powerups:
		var count := GameState.stacks(id)
		var powerup_name: String = GameState.POWERUPS[id].name
		lines.append(powerup_name if count == 1 else "%s x%d" % [powerup_name, count])
	powerups_label.text = "\n".join(lines)


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.visible = false
