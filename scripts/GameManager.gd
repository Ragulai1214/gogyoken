# GameManager.gd
extends Node

signal turn_resolved(result: Dictionary)
signal hp_changed(target: String, new_hp: int)
signal battle_ended(winner: String)

const ELEMENTS = ["wood", "fire", "earth", "metal", "water"]

const BEATS = {
	"wood":  "earth",
	"earth": "water",
	"water": "fire",
	"fire":  "metal",
	"metal": "wood",
}

const GENERATES = {
	"wood":  "fire",
	"fire":  "earth",
	"earth": "metal",
	"metal": "water",
	"water": "wood",
}

const BASE_DAMAGE = 20

var player_hp: int = 100
var cpu_hp: int = 100
var max_hp: int = 100
var player_primes: Array = []
var cpu_primes: Array = []
var player_hand_history: Array = []
var difficulty: String = "normal"

func setup(p_max_hp: int, p_difficulty: String) -> void:
	max_hp = p_max_hp
	player_hp = max_hp
	cpu_hp = max_hp
	player_primes.clear()
	cpu_primes.clear()
	player_hand_history.clear()
	difficulty = p_difficulty

func resolve_turn(player_hand: String) -> void:
	# 1. CPUの手を決定
	var cpu_hand = CpuAI.choose(difficulty, cpu_primes, player_primes, player_hand_history)

	# 2. プライム消費判定
	var player_combo = player_hand in player_primes
	var cpu_combo    = cpu_hand in cpu_primes
	if player_combo:
		player_primes.erase(player_hand)
	if cpu_combo:
		cpu_primes.erase(cpu_hand)

	# 3. 勝敗判定
	var outcome = _judge(player_hand, cpu_hand)

	# 4. ダメージ確定
	var damage = 0
	match outcome:
		"win":
			damage = BASE_DAMAGE * 2 if player_combo else BASE_DAMAGE
			cpu_hp -= damage
			hp_changed.emit("cpu", cpu_hp)
		"lose":
			damage = BASE_DAMAGE
			player_hp -= damage
			hp_changed.emit("player", player_hp)
		"clash":
			damage = 10
			cpu_hp -= damage
			player_hp -= damage
			hp_changed.emit("cpu", cpu_hp)
			hp_changed.emit("player", player_hp)
		"draw", "sousei":
			damage = 0

	# 5. 新規プライム付与判定
	var prev_player_primes = player_primes.duplicate()
	var prev_cpu_primes = cpu_primes.duplicate()
	_update_primes(player_hand, cpu_hand)
	var new_player_primes = player_primes.filter(func(e): return e not in prev_player_primes)
	var new_cpu_primes = cpu_primes.filter(func(e): return e not in prev_cpu_primes)

	# 6. 履歴記録
	player_hand_history.append(player_hand)

	# 7. シグナル発信
	var result = {
		"player_hand": player_hand,
		"cpu_hand":    cpu_hand,
		"outcome":     outcome,
		"player_combo": player_combo,
		"cpu_combo":    cpu_combo,
		"damage":       damage,
		"player_hp":    player_hp,
		"cpu_hp":       cpu_hp,
		"player_primes": player_primes.duplicate(),
		"cpu_primes":    cpu_primes.duplicate(),
		"new_player_primes": new_player_primes,
		"new_cpu_primes":    new_cpu_primes,
	}
	turn_resolved.emit(result)

	# 8. 勝敗終了判定
	if cpu_hp <= 0:
		battle_ended.emit("player")
	elif player_hp <= 0:
		battle_ended.emit("cpu")

func _judge(p: String, c: String) -> String:
	if p == c:
		return "draw"
	elif BEATS[p] == c:
		return "win"
	elif BEATS[c] == p:
		return "lose"
	elif GENERATES[p] == c or GENERATES[c] == p:
		return "sousei"
	else:
		return "clash"

func _update_primes(player_hand: String, cpu_hand: String) -> void:
	if GENERATES[player_hand] == cpu_hand:
		if cpu_hand not in cpu_primes:
			cpu_primes.append(cpu_hand)
	if GENERATES[cpu_hand] == player_hand:
		if player_hand not in player_primes:
			player_primes.append(player_hand)

var button_audio: AudioStreamPlayer

func play_button_se() -> void:
	if button_audio == null:
		button_audio = AudioStreamPlayer.new()
		add_child(button_audio)
		button_audio.stream = load("res://assets/SE/ボタン.wav")
	button_audio.play()

func apply_button_style(btn: Button) -> void:
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.0, 0.67, 1.0, 1.0)
	hover_style.corner_radius_top_left = 6
	hover_style.corner_radius_top_right = 6
	hover_style.corner_radius_bottom_left = 6
	hover_style.corner_radius_bottom_right = 6
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.add_theme_stylebox_override("hover", hover_style)