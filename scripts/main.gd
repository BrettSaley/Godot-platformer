extends Node2D

const KILL_Y = 650.0

@onready var player: CharacterBody2D = $Player
@onready var start_position: Marker2D = $StartPosition
@onready var message_label: Label = $UI/MessageLabel
@onready var message_timer: Timer = $UI/MessageTimer


func _ready() -> void:
	$Star.body_entered.connect(_on_star_body_entered)
	message_timer.timeout.connect(_on_message_timer_timeout)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > KILL_Y:
		die()


func die() -> void:
	show_message("You Died")
	respawn_player()


func _on_star_body_entered(body: Node) -> void:
	if body == player:
		show_message("Star Collected!")
		respawn_player()


func respawn_player() -> void:
	player.global_position = start_position.global_position
	player.velocity = Vector2.ZERO


func show_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer.start()


func _on_message_timer_timeout() -> void:
	message_label.visible = false
