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
@onready var player_damage_effect: AnimatedSprite2D = $PlayerDamageEffect
@onready var cpu_damage_effect: AnimatedSprite2D = $CPUDamageEffect
@onready var difficulty_label: Label = $DifficultyLabel

var hand_button_list: Array = []
var game_manager: Node
var audio_player: AudioStreamPlayer
var result_cache: Dictionary = {}

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
	home_button.pressed.connect(GameManager.play_button_se)
	var gm = get_node("/root/GameManager")
	gm.apply_button_style(get_node("Button"))
	prime_effect.animation_finished.connect(_on_prime_effect_finished)
	prime_effect.visible = false
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	_reposition_icons()
	player_damage_effect.visible = false
	cpu_damage_effect.visible = false
	player_damage_effect.animation_finished.connect(func(): player_damage_effect.visible = false)
	cpu_damage_effect.animation_finished.connect(func(): cpu_damage_effect.visible = false)

func _reposition_icons() -> void:
	var viewport_size = get_viewport_rect().size
	player_hand_icon.position = Vector2(viewport_size.x * 0.2, viewport_size.y * 0.35)
	cpu_hand_icon.position = Vector2(viewport_size.x * 0.75, viewport_size.y * 0.35)

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
	_update_hp_bar_color(player_hp_bar, game_manager.player_hp)
	_update_hp_bar_color(cpu_hp_bar, game_manager.cpu_hp)
	var diff_jp = {"easy": "Easy", "normal": "Normal", "hard": "Hard"}
	var diff_color = {"easy": Color(0.0, 0.8, 0.0, 1.0), "normal": Color(1.0, 1.0, 1.0, 1.0), "hard": Color(1.0, 0.0, 0.0, 1.0)}
	difficulty_label.text = "難易度: " + diff_jp[game_manager.difficulty]
	difficulty_label.add_theme_color_override("font_color", diff_color[game_manager.difficulty])

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
	result_cache = result
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
	_update_button_prime_style(result.player_primes)
	if result.outcome == "win":
		show_damage(result.damage, "cpu")
		play_damage_effect("cpu")
	elif result.outcome == "lose":
		show_damage(result.damage, "player")
		play_damage_effect("player")
		shake_screen()
	elif result.outcome == "clash":
		show_damage(10, "cpu")
		show_damage(10, "player")
		shake_screen()
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

func play_prime_effect(pos: Vector2) -> void:
	prime_effect.stop()
	prime_effect.position = pos
	prime_effect.visible = true
	prime_effect.frame = 0
	prime_effect.play("default")

func _on_prime_effect_finished() -> void:
	prime_effect.visible = false

func play_damage_effect(target: String) -> void:
	if target == "player":
		player_damage_effect.position = player_hand_icon.position + player_hand_icon.size / 2
		player_damage_effect.visible = true
		player_damage_effect.frame = 0
		player_damage_effect.play("default")
	else:
		cpu_damage_effect.position = cpu_hand_icon.position + cpu_hand_icon.size / 2
		cpu_damage_effect.visible = true
		cpu_damage_effect.frame = 0
		cpu_damage_effect.play("default")

func play_se(filename: String) -> void:
	audio_player.stream = load("res://assets/SE/" + filename)
	audio_player.play()

func shake_screen() -> void:
	var original_pos = get_viewport().canvas_transform.origin
	var tween = create_tween()
	tween.tween_method(func(offset: float):
		get_viewport().canvas_transform.origin = original_pos + Vector2(randf_range(-offset, offset), randf_range(-offset, offset)),
		8.0, 0.0, 0.3)

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
			if element in result_cache.get("new_player_primes", []):
				_bounce_button(btn)
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")

func _bounce_button(btn: Button) -> void:
	var original_scale = btn.scale
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(btn, "scale", original_scale, 0.08)

func _update_hp_bar_color(bar: ProgressBar, new_hp: int) -> void:
	var ratio = float(new_hp) / float(game_manager.max_hp)
	var stylebox = StyleBoxFlat.new()
	if ratio <= 0.2:
		stylebox.bg_color = Color(1.0, 0.0, 0.0, 1.0)
	elif ratio <= 0.4:
		stylebox.bg_color = Color(1.0, 0.8, 0.0, 1.0)
	else:
		stylebox.bg_color = Color(0.0, 0.8, 0.0, 1.0)
	bar.add_theme_stylebox_override("fill", stylebox)

func _on_hp_changed(target: String, new_hp: int) -> void:
	if target == "player":
		var tween = create_tween()
		tween.tween_property(player_hp_bar, "value", new_hp, 0.3)
		player_hp_label.text = "HP: %d" % new_hp
		_update_hp_bar_color(player_hp_bar, new_hp)
	else:
		var tween = create_tween()
		tween.tween_property(cpu_hp_bar, "value", new_hp, 0.3)
		cpu_hp_label.text = "HP: %d" % new_hp
		_update_hp_bar_color(cpu_hp_bar, new_hp)

func _on_battle_ended(winner: String) -> void:
	_set_buttons_disabled(true)
	await _slow_shake()
	var result_scene = load("res://scenes/Result.tscn").instantiate()
	result_scene.winner = winner
	result_scene.difficulty = game_manager.difficulty
	get_tree().root.add_child(result_scene)
	await get_tree().process_frame
	get_tree().current_scene = result_scene
	queue_free()

func _slow_shake() -> void:
	var original_pos = get_viewport().canvas_transform.origin
	var tween = create_tween()
	tween.tween_method(func(offset: float):
		get_viewport().canvas_transform.origin = original_pos + Vector2(randf_range(-offset, offset), randf_range(-offset, offset)),
		12.0, 0.0, 1.5)
	await tween.finished
	get_viewport().canvas_transform.origin = original_pos

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in hand_buttons.get_children():
		btn.disabled = disabled

func _on_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func show_damage(damage: int, target: String) -> void:
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
	if target == "player":
		container.position = player_hand_icon.position + Vector2(player_hand_icon.size.x / 2 - 16, -30)
	else:
		container.position = cpu_hand_icon.position + Vector2(cpu_hand_icon.size.x / 2 - 16, -30)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - 60, 0.8)
	tween.tween_property(container, "modulate:a", 0.0, 0.8)
	var shake = create_tween()
	shake.tween_property(container, "position:x", container.position.x + 8, 0.1)
	shake.tween_property(container, "position:x", container.position.x - 8, 0.1)
	shake.tween_property(container, "position:x", container.position.x + 6, 0.1)
	shake.tween_property(container, "position:x", container.position.x - 6, 0.1)
	shake.tween_property(container, "position:x", container.position.x, 0.1)
	await tween.finished
	container.queue_free()