# Rule.gd
# ルール説明画面

extends Control

@onready var back_button: Button = $BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.pressed.connect(GameManager.play_button_se)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
