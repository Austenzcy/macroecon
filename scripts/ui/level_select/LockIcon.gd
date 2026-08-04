extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	var center_x := size.x * 0.5
	var line_color := Color(0.83, 0.85, 0.87, 0.94)
	var shadow_color := Color(0.035, 0.04, 0.045, 0.42)
	draw_circle(Vector2(center_x, 55.0), 44.0, shadow_color)
	draw_arc(Vector2(center_x, 43.0), 18.0, PI, TAU, 32, line_color, 5.0, true)
	draw_line(Vector2(center_x - 18.0, 43.0), Vector2(center_x - 18.0, 51.0), line_color, 5.0, true)
	draw_line(Vector2(center_x + 18.0, 43.0), Vector2(center_x + 18.0, 51.0), line_color, 5.0, true)
	draw_rect(Rect2(center_x - 25.0, 50.0, 50.0, 37.0), line_color, false, 5.0, true)
	draw_circle(Vector2(center_x, 66.0), 4.5, line_color)
	draw_line(Vector2(center_x, 69.0), Vector2(center_x, 77.0), line_color, 4.0, true)
