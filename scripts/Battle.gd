# Battle.gd
extends Control

@onready var player_hp_bar: ProgressBar = $VBox/BattleArea/PlayerSide/PlayerHPBar
@onready var cpu_hp_bar: ProgressBar = $VBox/BattleArea/CPUSide/CPUHPBar
@onready var player_hp_label: Label = $VBox/BattleArea/PlayerSide/PlayerHPLabel
@onready var cpu_hp_label: Label = $VBox/BattleArea/CPUSide/CPUHPLabel
@onready var player_prime_label: Label = $VBox/BattleArea/PlayerSide/PlayerPrimeLabel
@onready var cpu_prime_label: Label = $VBox/BattleArea/CPUSide/CPUPrimeLabel
@onready var result_label: Label = $VBox/ResultLabel
@onready var hand_buttons: HBoxContainer = $VBox/HandButtons
@onready var cpu_hand_label: Label = $VBox/BattleArea/CPUSide/CPUHandLabel
@onready var player_hand_icon: TextureRect = $PlayerHandIcon
@onready var cpu_hand_icon: TextureRect = $CPUHandIcon
@onready var prime_effect: AnimatedSprite2D = $PrimeEffect
var hand_button_list: Array = [] 

const ELEMENT_JP = {
	"wood":  "木",
	"fire":  "火",
	"earth": "土",
	"metal": "金",
	"water": "水",
}

const OUTCOME_JP = {
	"win":    "勝ち！",
	"lose":   "負け...",
	"draw":   "引き分け",
	"sousei": "相生",
	"clash":  "相打ち",
}

const ELEMENT_ICON = {
	"wood":  "res://assets/sprite/icons/battle/wood.png",
	"fire":  "res://assets/sprite/icons/battle/fire.png",
	"earth": "res://assets/sprite/icons/battle/earth.png",
	"metal": "res://assets/sprite/icons/battle/metal.png",
	"water": "res://assets/sprite/icons/battle/water.png",
}

var game_manager: Node
var audio_player: AudioStreamPlayer

func _ready() -> void:
	game_manager = get_node("/root/GameManager")
	game_manager.turn_resolved.connect(_on_turn_resolved)
	game_manager.hp_changed.connect(_on_hp_changed)
	game_manager.battle_ended.connect(_on_battle_ended)
	_setup_hand_buttons()
	_refresh_ui()
	var home_button = get_node("Button")
	home_button.text = "ホームに戻る"
	home_button.pressed.connect(_on_home_pressed)
	prime_effect.animation_finished.connect(_on_prime_effect_finished)
	prime_effect.visible = false
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	home_button.pressed.connect(GameManager.play_button_se)
	var gm = get_node("/root/GameManager")
	gm.apply_button_style(get_node("Button"))
	# 既存のコードの後に追加
	_reposition_icons()

func _reposition_icons() -> void:
	var viewport_size = get_viewport_rect().size
	player_hand_icon.position = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.35)
	cpu_hand_icon.position = Vector2(viewport_size.x * 0.75, viewport_size.y * 0.35)

func play_prime_effect(pos: Vector2) -> void:
	prime_effect.stop()
	prime_effect.position = pos
	prime_effect.visible = true
	prime_effect.frame = 0
	prime_effect.play("default")

func _on_prime_effect_finished() -> void:
	prime_effect.visible = false

func play_se(filename: String) -> void:
	audio_player.stream = load("res://assets/SE/" + filename)
	audio_player.play()

func _setup_hand_buttons() -> void:
	for element in GameManager.ELEMENTS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(60, 60)
		var tex = load(ELEMENT_ICON[element])
		btn.icon = tex
		btn.expand_icon = true
		btn.pressed.connect(_on_hand_selected.bind(element))
		hand_buttons.add_child(btn)
		hand_button_list.append(btn)

func _refresh_ui() -> void:
	var max_hp = game_manager.max_hp
	player_hp_bar.max_value = max_hp
	cpu_hp_bar.max_value = max_hp
	player_hp_bar.value = game_manager.player_hp
	cpu_hp_bar.value = game_manager.cpu_hp
	player_hp_label.text = "HP: %d" % game_manager.player_hp
	cpu_hp_label.text = "HP: %d" % game_manager.cpu_hp
	_update_prime_labels(game_manager.player_primes, game_manager.cpu_primes)
	result_label.text = ""
	cpu_hand_label.text = "CPU: ?"

func _update_prime_labels(player_primes: Array, cpu_primes: Array) -> void:
	if player_primes.size() == 0:
		player_prime_label.text = "プライム: なし"
	else:
		var jp = player_primes.map(func(e): return ELEMENT_JP[e])
		player_prime_label.text = "プライム: " + ", ".join(jp)
	if cpu_primes.size() == 0:
		cpu_prime_label.text = "プライム: なし"
	else:
		var jp = cpu_primes.map(func(e): return ELEMENT_JP[e])
		cpu_prime_label.text = "プライム: " + ", ".join(jp)

func _on_hand_selected(element: String) -> void:
	_set_buttons_disabled(true)
	game_manager.resolve_turn(element)

func _on_turn_resolved(result: Dictionary) -> void:
	player_hand_icon.texture = load(ELEMENT_ICON[result.player_hand])
	cpu_hand_icon.texture = load(ELEMENT_ICON[result.cpu_hand])
	cpu_hand_label.text = "CPU: " + ELEMENT_JP[result.cpu_hand]
	var outcome_text = OUTCOME_JP[result.outcome]
	if result.player_combo and result.outcome == "win":
		outcome_text = "コンボ勝ち！ ×2"
	elif result.cpu_combo and result.outcome == "lose":
		outcome_text = "負け...（CPUコンボ）"
	result_label.text = outcome_text
	_update_prime_labels(result.player_primes, result.cpu_primes)
	_set_buttons_disabled(false)
	if result.new_player_primes.size() > 0:
		var center = player_hand_icon.position + player_hand_icon.size / 2
		play_prime_effect(center)
	if result.new_cpu_primes.size() > 0:
		var center = cpu_hand_icon.position + cpu_hand_icon.size / 2
		play_prime_effect(center)
	# プライム状態のボタン背景を黄色に
	_update_button_prime_style(result.player_primes)
	# ダメージ数字表示
	if result.outcome == "win":
		show_damage(result.damage, "cpu")
	elif result.outcome == "lose":
		show_damage(result.damage, "player")
	elif result.outcome == "clash":
		show_damage(10, "cpu")
		show_damage(10, "player")
	
	# SE再生
	match result.outcome:
		"win":
			if result.player_combo:
				play_se("プライムコンボ.wav")
			else:
				play_se("勝ち.wav")
		"lose":
			play_se("負け.wav")
		"draw":
			play_se("引き分け.wav")
		"sousei":
			if result.new_player_primes.size() > 0:
				play_se("プライム獲得.wav")
			if result.new_cpu_primes.size() > 0:
				play_se("CPUプライム.wav")

func _update_button_prime_style(player_primes: Array) -> void:
	for i in GameManager.ELEMENTS.size():
		var btn = hand_button_list[i]
		var element = GameManager.ELEMENTS[i]
		if element in player_primes:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(1, 1, 0, 0.5)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")

func _on_hp_changed(target: String, new_hp: int) -> void:
	if target == "player":
		var tween = create_tween()
		tween.tween_property(player_hp_bar, "value", new_hp, 0.3)
		player_hp_label.text = "HP: %d" % new_hp
	else:
		var tween = create_tween()
		tween.tween_property(cpu_hp_bar, "value", new_hp, 0.3)
		cpu_hp_label.text = "HP: %d" % new_hp

func _on_battle_ended(winner: String) -> void:
	_set_buttons_disabled(true)
	var result_scene = load("res://scenes/Result.tscn").instantiate()
	result_scene.winner = winner
	result_scene.difficulty = game_manager.difficulty
	get_tree().root.add_child(result_scene)
	await get_tree().process_frame
	get_tree().current_scene = result_scene
	queue_free()

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in hand_buttons.get_children():
		btn.disabled = disabled

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func show_damage(damage: int, target: String) -> void:
	# 数字画像を組み合わせてHBoxContainerで表示
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 1)
	add_child(container)
	
	var damage_str = str(damage)
	for ch in damage_str:
		var tex_rect = TextureRect.new()
		tex_rect.texture = load("res://assets/sprite/numbers/" + ch + "-red.png")
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.add_child(tex_rect)
	
	# 表示位置
	if target == "player":
		container.position = player_hand_icon.position + Vector2(player_hand_icon.size.x / 2 - 16, -30)
	else:
		container.position = cpu_hand_icon.position + Vector2(cpu_hand_icon.size.x / 2 - 16, -30)
	
	# Tweenアニメーション：上に浮いて揺れて消える
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - 60, 0.8)
	tween.tween_property(container, "modulate:a", 0.0, 0.8)
	# 横揺れ
	var shake = create_tween()
	shake.tween_property(container, "position:x", container.position.x + 8, 0.1)
	shake.tween_property(container, "position:x", container.position.x - 8, 0.1)
	shake.tween_property(container, "position:x", container.position.x + 6, 0.1)
	shake.tween_property(container, "position:x", container.position.x - 6, 0.1)
	shake.tween_property(container, "position:x", container.position.x, 0.1)
	
	await tween.finished
	container.queue_free()
