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
