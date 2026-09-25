extends Node2D

const BOSSES := [
	preload("res://scripts/bosses/bear.gd"),
	preload("res://scripts/bosses/dark_barbarian.gd"),
	preload("res://scripts/bosses/serpent.gd"),
]

const BACKGROUND_COLOR := Color(0.08, 0.06, 0.12)
const LEVEL_DURATION := 15.0
const BOSS_LEVEL_DURATION := LEVEL_DURATION * 1.5

@onready var spawner: Node = $Spawner
@onready var player: Node2D = $Player
@onready var bullets: Node2D = $Bullets
@onready var time_bar: ProgressBar = $UI/TimeBar
@onready var message_label: Label = $UI/MessageLabel
@onready var message_timer: Timer = $UI/MessageTimer
@onready var hearts: Control = $UI/Hearts
@onready var level_label: Label = $UI/LevelLabel
@onready var powerups_label: Label = $UI/PowerupsLabel

var boss_level := GameState.is_boss_level(GameState.level)
var boss: Boss
var time_left := BOSS_LEVEL_DURATION if boss_level else LEVEL_DURATION
var shield_charges := 0
var level_over := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(BACKGROUND_COLOR)
	message_timer.timeout.connect(_on_message_timer_timeout)

	spawner.setup(GameState.level, bullets, player)
	bullets.player = player
	bullets.player_hit.connect(_on_player_hit)
	shield_charges = GameState.stacks("shield")

	time_bar.max_value = time_left
	time_bar.value = time_left
	update_hud()
	show_message("BOSS FIGHT!" if boss_level else "Level %d" % GameState.level)
	await get_tree().create_timer(1.0, false).timeout
	spawner.start()
	if boss_level:
		boss = _pick_boss().new()
		boss.setup(GameState.level, bullets, player)
		boss.touched_player.connect(_on_player_hit)
		add_child(boss)
		move_child(boss, bullets.get_index())
		show_message("%s appears!" % boss.display_name)


## Random boss, never the same one as last time.
func _pick_boss() -> GDScript:
	var options := range(BOSSES.size())
	options.erase(GameState.last_boss)
	GameState.last_boss = options.pick_random()
	return BOSSES[GameState.last_boss]


func _physics_process(delta: float) -> void:
	if level_over or not spawner.active:
		return
	time_left -= delta
	time_bar.value = time_left
	if time_left <= 0.0:
		complete_level()


func _on_player_hit() -> void:
	if level_over:
		return
	if shield_charges > 0:
		shield_charges -= 1
		update_hud()
		show_message("Shield blocked a hit!")
		player.make_invulnerable(1.5)
		return
	GameState.health -= 1
	update_hud()
	if GameState.health > 0:
		player.make_invulnerable(1.5)
		return

	level_over = true
	player.hide()
	show_message("You Died on level %d" % GameState.level)
	get_tree().paused = true
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = false
	GameState.reset_run()
	get_tree().reload_current_scene()


func complete_level() -> void:
	level_over = true
	spawner.stop()
	bullets.clear_all()
	if boss:
		boss.queue_free()
	show_message("Boss survived!" if boss_level else "Level %d survived!" % GameState.level)
	await get_tree().create_timer(1.0).timeout
	if boss_level:
		show_powerup_choice()
	else:
		GameState.level += 1
		get_tree().reload_current_scene()


func show_powerup_choice() -> void:
	get_tree().paused = true
	message_label.visible = false

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


func update_hud() -> void:
	hearts.set_health(GameState.health, GameState.max_health())
	level_label.text = "Level %d - BOSS" % GameState.level if boss_level else "Level %d" % GameState.level
	var lines: Array[String] = []
	for id in GameState.powerups:
		var count := GameState.stacks(id)
		var powerup_name: String = GameState.POWERUPS[id].name
		lines.append(powerup_name if count == 1 else "%s x%d" % [powerup_name, count])
	if GameState.stacks("shield") > 0:
		lines.append("Shield charges: %d" % shield_charges)
	powerups_label.text = "\n".join(lines)


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.visible = false
