extends Node
## Sends projectiles in from all four edges of the arena. A steady stream of
## single projectiles grows denser each level, and periodic volleys (walls,
## aimed fans, corner bursts) unlock as levels go up.

const ARENA := Vector2(960, 540)
const MARGIN := 10.0
const COLORS := {
	"stream": Color(0.62, 0.62, 0.64),  # grey stone
	"wall": Color(0.7, 0.55, 0.38),  # sandstone
	"aimed": Color(0.72, 0.38, 0.3),  # red clay
	"burst": Color(0.42, 0.44, 0.52),  # slate
}

var level: int
var difficulty: float
var speed_mult: float
var stream_rate: float
var volley_interval: float

## Set by the main scene via setup().
var bullets: Node2D
var player: Node2D

var stream_timer := 0.0
var volley_timer := 0.0
var active := false
## During boss fights the edges only send a light stream, no volleys.
var boss_level := false


func setup(level_number: int, bullet_layer: Node2D, target: Node2D) -> void:
	level = level_number
	bullets = bullet_layer
	player = target
	difficulty = clampf((level - 1) / 14.0, 0.0, 1.0)
	speed_mult = minf(0.85 + 0.04 * (level - 1), 1.5) * pow(0.92, GameState.stacks("slow_motion"))
	boss_level = GameState.is_boss_level(level)
	stream_rate = minf(2.0 + 1.5 * (level - 1), 40.0) * (0.35 if boss_level else 1.0)
	volley_interval = lerpf(5.0, 1.2, difficulty)
	volley_timer = volley_interval


func start() -> void:
	active = true


func stop() -> void:
	active = false


func _physics_process(delta: float) -> void:
	if not active:
		return

	stream_timer -= delta
	while stream_timer <= 0.0:
		_spawn_stream()
		stream_timer += 1.0 / stream_rate

	if level >= 2 and not boss_level:
		volley_timer -= delta
		if volley_timer <= 0.0:
			volley_timer = volley_interval
			_spawn_volley()


func unlocked_volleys() -> Array:
	var volleys := ["wall"]
	if level >= 4:
		volleys.append("aimed")
	if level >= 5:
		volleys.append("burst")
	return volleys


## One projectile from a random edge, heading across the arena.
func _spawn_stream() -> void:
	var from := _random_edge_point(randi() % 4)
	var target := Vector2(randf_range(0.15, 0.85) * ARENA.x, randf_range(0.15, 0.85) * ARENA.y)
	_spawn(from, (target - from).normalized() * randf_range(60, 100), 6.0, COLORS.stream)


func _spawn_volley() -> void:
	var volleys := unlocked_volleys()
	match volleys[randi() % volleys.size()]:
		"wall":
			_spawn_wall(randi() % 4)
		"aimed":
			var from := _random_edge_point(randi() % 4)
			var dir := (player.position - from).normalized()
			var side := 1 + int(difficulty * 2.99)
			for i in range(-side, side + 1):
				_spawn(from, dir.rotated(i * 0.2) * 110.0, 6.0, COLORS.aimed)
		"burst":
			var corner := Vector2(ARENA.x * (randi() % 2), ARENA.y * (randi() % 2))
			var toward_center := (ARENA / 2.0 - corner).angle()
			var count := int(lerpf(8, 16, difficulty))
			for i in count:
				var angle := toward_center + lerpf(-0.7, 0.7, i / float(count - 1))
				_spawn(corner, Vector2.from_angle(angle) * 85.0, 7.0, COLORS.burst)


## A line of projectiles marching in from one edge, with a gap to slip through.
func _spawn_wall(edge: int) -> void:
	var horizontal := edge < 2  # top/bottom edges produce a horizontal line
	var length := ARENA.x if horizontal else ARENA.y
	var gap_center := randf_range(0.2, 0.8) * length
	var gap_half := lerpf(90, 50, difficulty)
	var dir: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][edge]
	var t := 15.0
	while t < length:
		if absf(t - gap_center) > gap_half:
			var from := _edge_point(edge, t)
			_spawn(from, dir * 70.0, 7.0, COLORS.wall)
		t += 30.0


## Edges: 0 = top, 1 = bottom, 2 = left, 3 = right.
func _edge_point(edge: int, t: float) -> Vector2:
	match edge:
		0:
			return Vector2(t, -MARGIN)
		1:
			return Vector2(t, ARENA.y + MARGIN)
		2:
			return Vector2(-MARGIN, t)
		_:
			return Vector2(ARENA.x + MARGIN, t)


func _random_edge_point(edge: int) -> Vector2:
	return _edge_point(edge, randf() * (ARENA.x if edge < 2 else ARENA.y))


func _spawn(pos: Vector2, vel: Vector2, radius: float, color: Color) -> void:
	bullets.spawn(pos, vel * speed_mult, radius, color)
