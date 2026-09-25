class_name LevelGenerator
extends RefCounted
## Builds a random run of platforms from the start platform to the star.
## Gaps are sized from the *base* player's jump arc, so every level is
## beatable without power-ups; difficulty pushes gaps toward that limit.

const GRAVITY := 980.0
const SPEED := 300.0
const JUMP_SPEED := 550.0

const START_X := 100.0
const START_TOP := 468.0
const START_WIDTH := 240.0
const PLATFORM_HEIGHT := 24.0
const FINAL_WIDTH := 160.0
const MIN_TOP := 150.0
const MAX_TOP := 480.0
const LAVA_TOP := 600.0
const HORIZON_TOP := 468.0

const DIRT := Color(0.35, 0.25, 0.15)
const GRASS := Color(0.42, 0.68, 0.28)


## Difficulty from 0.0 (level 1) to 1.0 (level 15 and beyond).
static func difficulty(level: int) -> float:
	return clampf((level - 1) / 14.0, 0.0, 1.0)


## How far the base player travels horizontally during a jump that lands
## `rise` pixels above the takeoff point (negative rise = landing lower).
static func horizontal_reach(rise: float) -> float:
	var disc := JUMP_SPEED * JUMP_SPEED - 2.0 * GRAVITY * rise
	if disc < 0.0:
		return 0.0
	return SPEED * (JUMP_SPEED + sqrt(disc)) / GRAVITY


## Populates `root` with the level and returns {"start": Vector2, "star": Area2D, "lava": Area2D}.
static func generate(root: Node2D, level: int) -> Dictionary:
	var d := difficulty(level)
	var platform_count := mini(4 + level, 20)
	var max_rise := JUMP_SPEED * JUMP_SPEED / (2.0 * GRAVITY)  # ~154px

	_add_platform(root, START_X, START_TOP, START_WIDTH, 64.0)
	var prev_right := START_X + START_WIDTH / 2.0
	var prev_top := START_TOP

	for i in platform_count:
		var is_final := i == platform_count - 1
		var rise := randf_range(-110.0, lerpf(50.0, max_rise * 0.8, d))
		var top := clampf(prev_top - rise, MIN_TOP, MAX_TOP)
		rise = prev_top - top

		var reach := horizontal_reach(rise)
		var gap := reach * randf_range(lerpf(0.3, 0.6, d), lerpf(0.55, 0.85, d))
		gap = maxf(gap, 40.0)

		var width := FINAL_WIDTH
		if not is_final:
			width = maxf(lerpf(150.0, 60.0, d) * randf_range(0.8, 1.2), 48.0)

		var center_x := prev_right + gap + width / 2.0
		_add_platform(root, center_x, top, width, PLATFORM_HEIGHT)
		prev_right = center_x + width / 2.0
		prev_top = top

	var level_right := prev_right
	var star := _add_star(root, Vector2(level_right - FINAL_WIDTH / 2.0, prev_top - 32.0))
	var lava := _add_lava(root, -600.0, level_right + 600.0)
	_add_scenery(root, -600.0, level_right + 600.0)

	return {"start": Vector2(START_X, START_TOP - 28.0), "star": star, "lava": lava}


static func _add_platform(root: Node2D, center_x: float, top: float, width: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(center_x, top + height / 2.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	body.add_child(shape)
	var hw := width / 2.0
	var hh := height / 2.0
	body.add_child(_poly(DIRT, [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]))
	body.add_child(_poly(GRASS, [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, -hh + 8), Vector2(-hw, -hh + 8)]))
	root.add_child(body)


static func _add_star(root: Node2D, pos: Vector2) -> Area2D:
	var star := Area2D.new()
	star.position = pos
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	star.add_child(shape)
	var points: Array[Vector2] = []
	for i in 10:
		var r := 16.0 if i % 2 == 0 else 6.5
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(Vector2(cos(angle), sin(angle)) * r)
	star.add_child(_poly(Color(1, 0.85, 0.2), points))
	root.add_child(star)
	return star


static func _add_lava(root: Node2D, left: float, right: float) -> Area2D:
	var lava := Area2D.new()
	var height := 300.0
	lava.position = Vector2((left + right) / 2.0, LAVA_TOP + height / 2.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, height)
	shape.shape = rect
	lava.add_child(shape)

	var hw := (right - left) / 2.0
	var hh := height / 2.0
	lava.add_child(_poly(Color(0.55, 0.08, 0.02), [Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)]))
	var glow: Array[Vector2] = []
	var x := -hw
	var up := true
	while x < hw:
		glow.append(Vector2(x, -hh + (0.0 if up else 14.0)))
		up = not up
		x += 145.0
	glow.append(Vector2(hw, -hh))
	glow.append(Vector2(hw, -hh + 40.0))
	glow.append(Vector2(-hw, -hh + 40.0))
	lava.add_child(_poly(Color(1, 0.55, 0.1), glow))
	root.add_child(lava)
	return lava


## Grass horizon and rolling hills behind the platforms.
static func _add_scenery(root: Node2D, left: float, right: float) -> void:
	var scenery := Node2D.new()
	scenery.z_index = -10
	scenery.add_child(_poly(Color(0.38, 0.6, 0.26), [
		Vector2(left, HORIZON_TOP), Vector2(right, HORIZON_TOP),
		Vector2(right, LAVA_TOP + 50.0), Vector2(left, LAVA_TOP + 50.0)]))
	var x := left
	while x < right:
		var w := randf_range(140.0, 220.0)
		var h := randf_range(50.0, 110.0)
		var shade := randf_range(0.0, 0.08)
		scenery.add_child(_poly(Color(0.32 + shade, 0.55 + shade, 0.24 + shade), [
			Vector2(x - w, HORIZON_TOP + 20), Vector2(x - w * 0.7, HORIZON_TOP - h * 0.5),
			Vector2(x - w * 0.35, HORIZON_TOP - h * 0.9), Vector2(x, HORIZON_TOP - h),
			Vector2(x + w * 0.35, HORIZON_TOP - h * 0.9), Vector2(x + w * 0.7, HORIZON_TOP - h * 0.5),
			Vector2(x + w, HORIZON_TOP + 20)]))
		x += randf_range(250.0, 450.0)
	root.add_child(scenery)


static func _poly(color: Color, points: Array) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array(points)
	return poly
