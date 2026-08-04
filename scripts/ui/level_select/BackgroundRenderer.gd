extends Control

var _stars: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 1907
	for index in range(72):
		_stars.append(Vector3(rng.randf(), rng.randf_range(0.05, 0.64), rng.randf_range(0.18, 0.8)))
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var viewport_size := size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.012, 0.018, 0.025, 1.0))

	var glow_center := Vector2(viewport_size.x * 0.52, viewport_size.y * 0.43)
	for radius in range(460, 40, -16):
		var ratio := float(radius) / 460.0
		draw_circle(glow_center, radius, Color(0.16, 0.26, 0.31, 0.0028 * (1.0 - ratio)))

	for star: Vector3 in _stars:
		var point := Vector2(star.x * viewport_size.x, star.y * viewport_size.y)
		draw_circle(point, 0.7 + star.z, Color(0.63, 0.75, 0.79, star.z * 0.24))

	var horizon := viewport_size.y * 0.66
	var vanishing := Vector2(viewport_size.x * 0.52, horizon)
	for column in range(-11, 12):
		var bottom_x := viewport_size.x * 0.5 + float(column) * viewport_size.x * 0.09
		draw_line(vanishing, Vector2(bottom_x, viewport_size.y), Color(0.34, 0.49, 0.54, 0.09), 1.0)

	for row in range(13):
		var ratio := float(row) / 12.0
		var y := lerpf(horizon, viewport_size.y, pow(ratio, 2.2))
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(0.34, 0.49, 0.54, 0.075 + ratio * 0.04), 1.0)

	draw_line(Vector2(0, horizon), Vector2(viewport_size.x, horizon), Color(0.78, 0.61, 0.34, 0.16), 1.0)
