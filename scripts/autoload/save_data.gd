extends Node
## Player progress, settings and wallet, saved as JSON in user://.

signal coins_changed(coins: int)
signal theme_changed

const PATH := "user://save.json"
const AD_COINS_PER_DAY := 5

var data := {
	"coins": 100,
	"best": 0,
	"sound": true,
	"haptics_minor": true,
	"haptics_major": true,
	"reduced_fx": false,
	"theme": "midnight",
	"owned_themes": ["midnight"],
	"powerups": {"hammer": 2, "rotate": 2, "swap": 2, "undo": 2},
	"level_unlocked": 1,
	"stars": {},
	"daily": {},
	"games_played": 0,
	"ad_coins_day": "",
	"ad_coins_count": 0,
	"streak": 0,
	"streak_day": "",
	"stars_spent": 0,
	"island_dusk": false,
	"island_look": "day",
	"ads_removed": false,
}


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]


func save() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


static func today() -> String:
	return Time.get_date_string_from_system()


# --- wallet ---
func coins() -> int:
	return int(data["coins"])


func add_coins(n: int) -> void:
	data["coins"] = coins() + n
	save()
	coins_changed.emit(coins())


func spend(n: int) -> bool:
	if coins() < n:
		return false
	add_coins(-n)
	return true


func ad_coins_left() -> int:
	if data["ad_coins_day"] != today():
		return AD_COINS_PER_DAY
	return AD_COINS_PER_DAY - int(data["ad_coins_count"])


func note_ad_coins() -> void:
	if data["ad_coins_day"] != today():
		data["ad_coins_day"] = today()
		data["ad_coins_count"] = 0
	data["ad_coins_count"] = int(data["ad_coins_count"]) + 1
	save()


# --- scores and progress ---
func best() -> int:
	return int(data["best"])


func set_best(score: int) -> void:
	if score > best():
		data["best"] = score
		save()


func daily_best() -> int:
	return int(data["daily"].get(today(), -1))


func set_daily(score: int) -> void:
	data["daily"][today()] = maxi(score, daily_best())
	save()


func unlocked() -> int:
	return int(data["level_unlocked"])


func unlock(n: int) -> void:
	data["level_unlocked"] = maxi(unlocked(), mini(n, Levels.COUNT))
	save()


func stars(level: int) -> int:
	return int(data["stars"].get(str(level), 0))


func set_stars(level: int, s: int) -> void:
	data["stars"][str(level)] = maxi(s, stars(level))
	save()


# --- daily streak ---
const STREAK_REWARDS := {3: {"coins": 50}, 7: {"coins": 100, "hammer": 2}}


static func yesterday() -> String:
	return Time.get_date_string_from_unix_time(Time.get_unix_time_from_datetime_string(today()) - 86400)


## Days in a row with a finished Daily challenge; 0 once a day has been missed.
func streak() -> int:
	var day := str(data["streak_day"])
	return int(data["streak"]) if day == today() or day == yesterday() else 0


func played_daily_today() -> bool:
	return str(data["streak_day"]) == today()


## Counts today's Daily challenge toward the streak (once per day) and pays any reward.
## The reward table repeats every 7 days. Returns the reward given, or {}.
func note_daily_played() -> Dictionary:
	if played_daily_today():
		return {}
	data["streak"] = streak() + 1
	data["streak_day"] = today()
	var day := (int(data["streak"]) - 1) % 7 + 1
	var reward: Dictionary = STREAK_REWARDS.get(day, {})
	for k in reward:
		if k == "coins":
			add_coins(int(reward[k]))
		else:
			add_power(k, int(reward[k]))
	save()
	return reward


# --- star shop on the island ---
func region_stars(r: int) -> int:
	var reg: Dictionary = Levels.REGIONS[r]
	var total := 0
	for n in range(int(reg["first"]), int(reg["last"]) + 1):
		total += stars(n)
	return total


## Stars earned and not yet spent. Getting more stars on an old level adds to it.
func star_balance() -> int:
	var total := 0
	for r in Levels.REGIONS.size():
		if Levels.region_ready(r):
			total += region_stars(r)
	return total - int(data["stars_spent"])


## Spends stars on a chest and returns what was inside: {"coins": n, power-up: n, "theme": id}.
## Returns {} if the balance is too low.
func buy_chest(kind: String, cost: int) -> Dictionary:
	if star_balance() < cost:
		return {}
	data["stars_spent"] = int(data["stars_spent"]) + cost
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var powers := ["hammer", "rotate", "swap", "undo"]
	var got := {}
	if kind == "small":
		got["coins"] = rng.randi_range(6, 12) * 10
		if rng.randf() < 0.5:
			got[powers[rng.randi_range(0, 3)]] = 1
	else:
		got["coins"] = rng.randi_range(15, 25) * 10
		for k in 2:
			var p: String = powers[rng.randi_range(0, 3)]
			got[p] = int(got.get(p, 0)) + 1
		# Now and then a theme the player doesn't have yet.
		if rng.randf() < 0.25:
			for t in Themes.LIST:
				if not owns_theme(str(t["id"])):
					data["owned_themes"].append(str(t["id"]))
					got["theme"] = str(t["id"])
					break
	for k in got:
		if k != "coins" and k != "theme":
			add_power(k, int(got[k]))
	add_coins(int(got["coins"]))
	save()
	return got


## The dusk island look: bought once with stars, then switched on and off for free.
func buy_or_toggle_dusk(cost: int) -> String:
	if not bool(data["island_dusk"]):
		if star_balance() < cost:
			return ""
		data["stars_spent"] = int(data["stars_spent"]) + cost
		data["island_dusk"] = true
		data["island_look"] = "dusk"
	else:
		data["island_look"] = "day" if str(data["island_look"]) == "dusk" else "dusk"
	save()
	return str(data["island_look"])


# --- power-ups ---
func power_count(kind: String) -> int:
	return int(data["powerups"].get(kind, 0))


func add_power(kind: String, n: int) -> void:
	data["powerups"][kind] = maxi(0, power_count(kind) + n)
	save()


# --- themes ---
func theme() -> Dictionary:
	return Themes.get_theme(str(data["theme"]))


func palette() -> Array:
	return theme()["blocks"]


func owns_theme(id: String) -> bool:
	return data["owned_themes"].has(id)


func buy_theme(id: String, price: int) -> bool:
	if owns_theme(id) or not spend(price):
		return false
	data["owned_themes"].append(id)
	set_theme(id)
	return true


func set_theme(id: String) -> void:
	data["theme"] = id
	save()
	theme_changed.emit()
