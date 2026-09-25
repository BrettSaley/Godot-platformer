extends Boss
## A huge, evil version of the player's barbarian. Whirls in place flinging a
## spiral of rocks, throws aimed volleys, or flies into a rage and chases the
## player while rocks burst off him.

const STONE := Color(0.42, 0.4, 0.45)
const RAGE_STONE := Color(0.62, 0.33, 0.28)
const SIZE := 2.4

var spin_angle := 0.0
var facing := -1.0


func _init() -> void:
	display_name = "Dark Barbarian"
	radius = 26.0
	move_speed = 90.0


func _attacks() -> Array:
	return ["whirl", "volley", "rage"]


func _move(delta: float) -> void:
	var before := position
	match attack:
		"rage":
			# Slower than the player, but relentless.
			position = position.move_toward(player.position, move_speed * 1.4 * delta)
		"whirl":
			pass  # spins in place
		_:
			super._move(delta)
	if absf(position.x - before.x) > 0.1:
		facing = signf(position.x - before.x)


func _fire(attack_name: String) -> float:
	var d := difficulty
	match attack_name:
		"whirl":
			spin_angle += 0.35
			var arms := 3 + int(d * 2.99)
			for i in arms:
				shoot(position, Vector2.from_angle(spin_angle + TAU * i / arms) * lerpf(90, 130, d), 6.0, STONE)
			return lerpf(0.13, 0.08, d)
		"volley":
			fan(position, dir_to_player(position), 1 + int(d * 2.99), 0.16, lerpf(130, 180, d), 6.0, STONE)
			return lerpf(0.9, 0.5, d)
		"rage":
			ring(position, int(lerpf(6, 12, d)), lerpf(70, 110, d), 6.0, RAGE_STONE)
			return lerpf(0.8, 0.5, d)
	return 1.0


func _draw() -> void:
	if attack == "rage":
		var pulse := 0.2 + sin(time * 10.0) * 0.08
		draw_circle(Vector2(0, -4), 44.0, Color(1, 0.15, 0.05, pulse))
	var tilt := 0.0
	if attack == "whirl":
		tilt = sin(time * 25.0) * 0.25
	var bob := -absf(sin(time * 8.0)) * 1.5
	BarbarianArt.draw(self, BarbarianArt.VILLAIN, bob, tilt, facing, SIZE)
