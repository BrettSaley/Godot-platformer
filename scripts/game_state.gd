extends Node
## Holds the state of the current run. Survives scene reloads as an autoload,
## and is wiped by reset_run() when the player dies.

const BASE_MAX_HEALTH := 3

const POWERUPS := {
	"swift_feet": {"name": "Swift Feet", "desc": "Move 12% faster"},
	"steady_focus": {"name": "Steady Focus", "desc": "Move 25% faster while holding Shift"},
	"small_target": {"name": "Small Target", "desc": "Hitbox 15% smaller"},
	"slow_motion": {"name": "Slow Motion", "desc": "Projectiles move 8% slower"},
	"shield": {"name": "Shield", "desc": "Block the first hit of every level"},
	"tough_hide": {"name": "Tough Hide", "desc": "+1 max heart"},
	"hearty_meal": {"name": "Hearty Meal", "desc": "Refill all hearts"},
}

var level := 1
## Power-up id -> number of stacks collected this run.
var powerups := {}
## Health carries over between levels and refills only with power-ups.
var health := BASE_MAX_HEALTH
## Index into the main scene's boss list of the last boss fought, so the
## same boss never appears twice in a row (kept across runs too).
var last_boss := -1

# Meta-progression (persists across runs) will live here later.


## Every third level is a boss fight, and only boss fights award power-ups.
func is_boss_level(level_number: int) -> bool:
	return level_number % 3 == 0


func max_health() -> int:
	return BASE_MAX_HEALTH + stacks("tough_hide")


func stacks(id: String) -> int:
	return powerups.get(id, 0)


func add_powerup(id: String) -> void:
	match id:
		"hearty_meal":
			health = max_health()
		"tough_hide":
			powerups[id] = stacks(id) + 1
			health += 1
		_:
			powerups[id] = stacks(id) + 1


func random_choices(count: int) -> Array:
	var ids := POWERUPS.keys()
	if health >= max_health():
		ids.erase("hearty_meal")
	ids.shuffle()
	return ids.slice(0, count)


func reset_run() -> void:
	level = 1
	powerups.clear()
	health = BASE_MAX_HEALTH
