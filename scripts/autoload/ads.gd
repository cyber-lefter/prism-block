extends Node
## Placeholder ad service. The rest of the game only calls show_rewarded() and game_finished().
## To ship, keep this API and replace _fake() with calls to the AdMob plugin (see README).

const INTERSTITIAL_EVERY := 3
const FREE_GAMES_BEFORE_INTERSTITIALS := 3

var busy := false
var _games_since_interstitial := 0


## Shows a rewarded ad the player chose to watch, then grants the reward.
func show_rewarded(placement: String, on_reward: Callable) -> void:
	if busy:
		return
	_fake("Rewarded ad", "Placement: %s\nPlaceholder, no real ad plays" % placement, 1.6, on_reward)


## Called between games. Shows an interstitial now and then, never during play.
func game_finished(on_done: Callable) -> void:
	_games_since_interstitial += 1
	if bool(Save.data.get("ads_removed", false)):
		on_done.call()
		return
	var played := int(Save.data.get("games_played", 0))
	if played > FREE_GAMES_BEFORE_INTERSTITIALS and _games_since_interstitial >= INTERSTITIAL_EVERY:
		_games_since_interstitial = 0
		_fake("Interstitial ad", "Placeholder, no real ad plays", 1.0, on_done)
	else:
		on_done.call()


func _fake(title: String, sub: String, seconds: float, done: Callable) -> void:
	busy = true
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.94)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := UI.label(title + "\n" + sub, 34, Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bg.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		layer.queue_free()
		busy = false
		if done.is_valid():
			done.call()
	)
