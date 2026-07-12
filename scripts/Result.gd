# Result.gd
extends Control

@onready var result_label: Label = $VBox/ResultLabel
@onready var retry_button: Button = $VBox/Buttons/RetryButton
@onready var home_button: Button = $VBox/Buttons/HomeButton
@onready var chara_sprite: AnimatedSprite2D = $CharaSprite
@onready var bg: ColorRect = $ColorRect
@onready var comment_bubble: TextureRect = $CommentBubble

var winner: String = ""
var difficulty: String = "normal"
var audio_player: AudioStreamPlayer

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	_show_chara_comment()

	var gm = get_node("/root/GameManager")
	gm.apply_button_style(retry_button)
	gm.apply_button_style(home_button)

	if winner == "player":
		result_label.text = "勝利！"
		audio_player.stream = load("res://assets/SE/勝利.wav")
		chara_sprite.play("default")
		bg.top_color = Color(1.0, 0.8, 0.0, 1.0)
		bg.bottom_color = Color(0.8, 0.3, 0.0, 1.0)
	else:
		result_label.text = "敗北..."
		audio_player.stream = load("res://assets/SE/敗北.wav")
		chara_sprite.stop()
		chara_sprite.frame = 0
		bg.top_color = Color(0.2, 0.2, 0.2, 1.0)
		bg.bottom_color = Color(0.0, 0.0, 0.0, 1.0)
	
	bg.queue_redraw()
	audio_player.play()

	retry_button.pressed.connect(_on_retry_pressed)
	home_button.pressed.connect(_on_home_pressed)
	retry_button.pressed.connect(GameManager.play_button_se)
	home_button.pressed.connect(GameManager.play_button_se)

func _show_chara_comment() -> void:
	var win_comments = [
		"よっ！
		五行説マスター！",
		"連勝狙っちゃう？",
		"最高の一手だったね！",
	]
	var lose_comments = [
		"次勝とうな",
		"残念無念また来年",
		"まあ、相性もあるしな",
	]

	var comment_text = ""
	if winner == "player":
		comment_text = win_comments[randi() % win_comments.size()]
	else:
		comment_text = lose_comments[randi() % lose_comments.size()]

	var label = $CommentBubble/CommentLabel
	label.text = comment_text
	label.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))

func _on_retry_pressed() -> void:
	var gm = get_node("/root/GameManager")
	gm.setup(gm.max_hp, difficulty)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")