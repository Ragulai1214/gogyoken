# RadialGradient.gd
extends ColorRect

var edge_color: Color = Color(0.0, 0.0, 0.0, 1.0)

const COLORS = [
	Color(0.4, 0.0, 0.0, 1.0),   # 赤（火）
	Color(0.6, 0.6, 0.0, 1.0),   # 黄（土）
	Color(0.0, 0.4, 0.0, 1.0),   # 緑（木）
	Color(0.8, 0.8, 0.8, 1.0),   # 白 (金)
	Color(0.1, 0.1, 0.4, 1.0),   # 藍（水）
]

var current_color: Color = Color(0.4, 0.0, 0.0, 1.0)
var color_index: int = 0
var t: float = 0.0

func _ready() -> void:
	current_color = COLORS[0]

func _process(delta: float) -> void:
	t += delta * 0.3
	if t >= 1.0:
		t = 0.0
		color_index = (color_index + 1) % COLORS.size()
	var next_index = (color_index + 1) % COLORS.size()
	current_color = COLORS[color_index].lerp(COLORS[next_index], t)
	queue_redraw()

func _set_center_color(c: Color) -> void:
	current_color = c
	queue_redraw()

func _draw() -> void:
	var center = size / 2
	var radius = min(size.x, size.y) * 0.6
	var steps = 40
	for i in range(steps, 0, -1):
		var step_t = float(i) / steps
		var grad_color = current_color.lerp(edge_color, 1.0 - step_t)
		draw_circle(center, radius * step_t, grad_color)
