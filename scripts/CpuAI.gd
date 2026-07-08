# CpuAI.gd
# CPU AIロジック：難易度別の手選択

extends Node

const ELEMENTS = ["wood", "fire", "earth", "metal", "water"]

# 相克：キーが相手を打ち破る
const BEATS = {
	"wood":  "earth",
	"earth": "water",
	"water": "fire",
	"fire":  "metal",
	"metal": "wood",
}

# =====================
# メイン選択関数
# =====================
func choose(
	difficulty: String,
	cpu_primes: Array,
	player_primes: Array,
	player_history: Array
) -> String:
	match difficulty:
		"easy":
			return _choose_easy()
		"normal":
			return _choose_normal(cpu_primes)
		"hard":
			return _choose_hard(cpu_primes, player_primes, player_history)
		_:
			return _choose_easy()

# =====================
# Easy：完全ランダム
# =====================
func _choose_easy() -> String:
	return ELEMENTS[randi() % ELEMENTS.size()]

# =====================
# Normal：自分のプライムを消費できる手を優先
# =====================
func _choose_normal(cpu_primes: Array) -> String:
	if cpu_primes.size() > 0:
		# プライム中の手をランダムに1つ選んで出す
		return cpu_primes[randi() % cpu_primes.size()]
	return _choose_easy()

# =====================
# Hard：頻度解析＋プライム重み付け
# =====================
func _choose_hard(
	cpu_primes: Array,
	player_primes: Array,
	player_history: Array
) -> String:
	# 各手のスコアを計算
	var scores = {}
	for e in ELEMENTS:
		scores[e] = 0.0

	# 1. プレイヤーの直近10手の頻度解析
	#    → プレイヤーがよく出す手を相克で勝てる手のスコアを上げる
	var recent = player_history.slice(max(0, player_history.size() - 10))
	for hand in recent:
		# この手に勝てる手を探す
		for e in ELEMENTS:
			if BEATS[e] == hand:
				scores[e] += 2.0

	# 2. CPUのプライム消費を優先（攻撃的加点）
	for prime in cpu_primes:
		scores[prime] += 3.0

	# 3. プレイヤーのプライムを警戒（相克で潰せる手に加点）
	for prime in player_primes:
		for e in ELEMENTS:
			if BEATS[e] == prime:
				scores[e] += 1.5

	# 最高スコアの手を選択（同点はランダム）
	var best_score = -1.0
	var best_hands = []
	for e in ELEMENTS:
		if scores[e] > best_score:
			best_score = scores[e]
			best_hands = [e]
		elif scores[e] == best_score:
			best_hands.append(e)

	return best_hands[randi() % best_hands.size()]
