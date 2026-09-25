extends Node
## Holds the state of the current run. Survives scene reloads as an autoload,
## and is wiped by reset_run() when the player dies.

const POWERUPS := {
	"double_jump": {"name": "Double Jump", "desc": "+1 jump in mid-air"},
	"spring_legs": {"name": "Spring Legs", "desc": "Jump 8% higher"},
	"swift_feet": {"name": "Swift Feet", "desc": "Run 12% faster"},
	"feather": {"name": "Feather", "desc": "8% lower gravity"},
	"coyote": {"name": "Coyote Time", "desc": "Jump a moment after leaving a ledge"},
	"extra_life": {"name": "Extra Life", "desc": "Survive one death (restart the level)"},
}

var level := 1
## Power-up id -> number of stacks collected this run.
var powerups := {}

# Meta-progression (persists across runs) will live here later.


func stacks(id: String) -> int:
	return powerups.get(id, 0)


func add_powerup(id: String) -> void:
	powerups[id] = stacks(id) + 1


func consume_powerup(id: String) -> void:
	powerups[id] = stacks(id) - 1
	if powerups[id] <= 0:
		powerups.erase(id)


func random_choices(count: int) -> Array:
	var ids := POWERUPS.keys()
	ids.shuffle()
	return ids.slice(0, count)


func reset_run() -> void:
	level = 1
	powerups.clear()
