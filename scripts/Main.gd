# Main.gd
# ホーム画面：難易度選択・HP設定・ゲーム開始

extends Control

# =====================
# ノード参照
# =====================
@onready var difficulty_buttons: HBoxContainer = $VBox/DifficultyButtons
@onready var hp_slider: HSlider = $VBox/HPSlider
@onready var hp_label: Label = $VBox/HPLabel
@onready var start_button: Button = $VBox/StartButton

# =====================
# 状態変数
# =====================
var selected_difficulty: String = "normal"

# =====================
# 初期化
# =====================
func _ready() -> void:
	# HP スライダー設定
	hp_slider.min_value = 20
	hp_slider.max_value = 300
	hp_slider.step = 20
	hp_slider.value = 100
	hp_label.text = "HP: 100"

	hp_slider.value_changed.connect(_on_hp_changed)
	start_button.pressed.connect(_on_start_pressed)

	# 難易度ボタン生成
	_setup_difficulty_buttons()
	# ルールボタン（シーンツリー上のButtonノードを取得）
	var rule_button = get_node("Button")
	rule_button.text = "ルール説明"
	rule_button.pressed.connect(_on_rule_pressed)

	start_button.pressed.connect(GameManager.play_button_se)
	for btn in difficulty_buttons.get_children():
		btn.pressed.connect(GameManager.play_button_se)

# =====================
# 難易度ボタンを動的生成
# =====================
func _setup_difficulty_buttons() -> void:
	var difficulties = ["easy", "normal", "hard"]
	var labels = ["Easy", "Normal", "Hard"]

	for i in difficulties.size():
		var btn = Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = Vector2(100, 50)
		btn.toggle_mode = true
		btn.pressed.connect(_on_difficulty_selected.bind(difficulties[i]))
		difficulty_buttons.add_child(btn)

		# デフォルトはNormalを選択状態に
		if difficulties[i] == "normal":
			btn.button_pressed = true

# =====================
# 難易度選択
# =====================
func _on_difficulty_selected(difficulty: String) -> void:
	selected_difficulty = difficulty

	# 他のボタンの選択を解除
	for btn in difficulty_buttons.get_children():
		btn.button_pressed = false

	# 選択したボタンだけ選択状態に
	var idx = ["easy", "normal", "hard"].find(difficulty)
	difficulty_buttons.get_child(idx).button_pressed = true

# =====================
# HPスライダー変化
# =====================
func _on_hp_changed(value: float) -> void:
	hp_label.text = "HP: %d" % int(value)

# =====================
# ゲーム開始
# =====================
func _on_start_pressed() -> void:
	var gm = get_node("/root/GameManager")
	gm.setup(int(hp_slider.value), selected_difficulty)
	get_tree().change_scene_to_file("res://scenes/Battle.tscn")

func _on_rule_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Rule.tscn")