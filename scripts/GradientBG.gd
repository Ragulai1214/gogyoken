# GradientBG.gd
extends ColorRect

@export var top_color: Color = Color(0.5, 0.4, 0.0, 1.0)
@export var bottom_color: Color = Color(0.1, 0.05, 0.3, 1.0)

func _draw() -> void:
	var steps = 50
	for i in steps:
		var t = float(i) / steps
		var grad_color = top_color.lerp(bottom_color, t)
		var y = size.y * t
		var h = size.y / steps + 1
		draw_rect(Rect2(0, y, size.x, h), grad_color)