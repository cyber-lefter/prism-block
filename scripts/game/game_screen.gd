class_name GameScreen
extends Control
## One game session: HUD on top, the board in the middle, power-ups at the bottom,
## and the intro, pause and end-of-game dialogs.

const POWERS := [["hammer", "Hammer"], ["rotate", "Rotate"], ["swap", "Swap"], ["undo", "Undo"]]

var router
var mode := "classic"
var level_n := 0
var level: Dictionary = {}
var view: GameView
var hud: HBoxContainer
var bar: HBoxContainer
var score_label: Label
var combo_pill: PanelContainer
var combo_label: Label
var side_title: Label
var side_value: Label
var power_buttons := {}
var dialog: Control
var dialog_kind := ""
var _dialog_labels: Array = []
var shown_score := 0.0
var awarded := false

var c_green := Color("2fbf71")
var c_purple := Color("7b5cff")
var c_panel := Color("2c2766")
var c_gold := Color("ffd23f")
var c_muted := Color(0.75, 0.72, 0.95)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mode == "adventure":
		level = Levels.get_level(level_n)
	view = GameView.new()
	add_child(view)
	view.setup(mode, level)
	view.score_changed.connect(_on_score)
	view.goal_changed.connect(_on_goal)
	view.finished.connect(_on_finished)
	view.tool_used.connect(_on_tool_used)
	view.tool_cancelled.connect(_refresh_powers)
	view.orb_arrived.connect(_on_orb)
	_build_hud()
	_build_bar()
	resized.connect(_layout)
	_layout.call_deferred()
	_refresh_side()
	_refresh_powers()
	if mode == "adventure":
		_show_intro()
	elif mode == "daily":
		_show_daily_intro()


func _process(delta: float) -> void:
	# The counter only counts points that have landed; orbs still in flight are added on arrival.
	var target := view.shown_score()
	if absf(shown_score - target) > 0.01:
		shown_score = lerpf(shown_score, target, minf(1.0, delta * 12.0))
		if absf(shown_score - target) < 0.5:
			shown_score = target
		score_label.text = UI.fmt(roundi(shown_score))
	view.score_target = score_label.get_global_rect().get_center()
	view.goal_target = side_value.get_global_rect().get_center()


func _on_orb(target: String) -> void:
	var l := score_label if target == "score" else side_value
	l.pivot_offset = l.size / 2.0
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.08, 1.08), 0.05)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)


# ---------------------------------------------------------------- layout

func _build_hud() -> void:
	hud = HBoxContainer.new()
	hud.add_theme_constant_override("separation", 12)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)

	var left := HBoxContainer.new()
	left.custom_minimum_size = Vector2(170, 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(left)
	var pause := UI.button("II", c_panel, 32, 84)
	pause.custom_minimum_size = Vector2(84, 84)
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause.pressed.connect(_show_pause)
	left.add_child(pause)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(mid)
	score_label = UI.label("0", 92, Color.WHITE, 16)
	mid.add_child(score_label)
	combo_pill = PanelContainer.new()
	combo_pill.add_theme_stylebox_override("panel", UI.pill_style(c_gold))
	combo_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	combo_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_pill.modulate.a = 0.0
	combo_label = UI.label("Combo x2", 26, UI.INK)
	combo_pill.add_child(combo_label)
	mid.add_child(combo_pill)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(170, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right)
	side_title = UI.label("BEST", 22, c_muted)
	side_value = UI.label("0", 34, c_gold)
	right.add_child(side_title)
	right.add_child(side_value)


func _build_bar() -> void:
	bar = HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	if mode == "daily":
		var note := UI.label("Daily rules: same pieces for everyone,\nno power-ups, no revives", 24, c_muted)
		bar.add_child(note)
		return
	for p in POWERS:
		var b := Widgets.PowerButton.new(p[0], p[1])
		var kind: String = p[0]
		b.pressed.connect(func() -> void: _on_power(kind))
		bar.add_child(b)
		power_buttons[kind] = b


func _layout() -> void:
	var ins := UI.safe_insets(self)
	var top := 18.0 + ins.x
	hud.position = Vector2(24, top)
	hud.size = Vector2(size.x - 48, 160)
	var bar_h := 150.0
	bar.position = Vector2(24, size.y - bar_h - 24 - ins.y)
	bar.size = Vector2(size.x - 48, bar_h)
	var view_top := top + 168.0
	view.set_area(Rect2(0, view_top, size.x, bar.position.y - view_top - 8.0))
	score_label.pivot_offset = score_label.size / 2.0


# ---------------------------------------------------------------- HUD updates

func _on_score(score: int, streak: int) -> void:
	var show_combo := streak >= 2
	if show_combo:
		combo_label.text = "Combo x%d" % streak
	create_tween().tween_property(combo_pill, "modulate:a", 1.0 if show_combo else 0.0, 0.15)
	_refresh_side()
	_refresh_powers()


func _on_goal(current: int, target: int) -> void:
	_refresh_side()


func _refresh_side() -> void:
	match mode:
		"classic":
			side_title.text = "BEST"
			side_value.text = UI.fmt(maxi(Save.best(), view.score))
		"daily":
			side_title.text = "TODAY"
			side_value.text = UI.fmt(maxi(Save.daily_best(), view.score))
		"adventure":
			var target := int(level["target"])
			var cur := mini(view.goal_current, target)
			side_title.text = {"score": "GOAL", "lines": "LINES", "gems": "GEMS", "ice": "ICE"}[level["type"]]
			if level["type"] == "score":
				side_value.text = "%s/%s" % [_short(cur), _short(target)]
			else:
				side_value.text = "%d / %d" % [cur, target]


static func _short(n: int) -> String:
	return "%.1fk" % (n / 1000.0) if n >= 1000 else str(n)


func _refresh_powers() -> void:
	for k in power_buttons:
		var b: Widgets.PowerButton = power_buttons[k]
		b.count = Save.power_count(k)
		b.active = view.tool == k
		b.disabled = view.over or (k == "undo" and not view.can_undo())
		b.queue_redraw()


# ---------------------------------------------------------------- power-ups

func _on_power(kind: String) -> void:
	if view.over or dialog != null or Ads.busy:
		return
	if view.tool == kind:
		view.set_tool("")
		_refresh_powers()
		return
	if kind == "undo" and not view.can_undo():
		return
	if Save.power_count(kind) <= 0:
		Ads.show_rewarded(kind, func() -> void:
			Save.add_power(kind, 1)
			_activate(kind)
		)
		return
	_activate(kind)


func _activate(kind: String) -> void:
	match kind:
		"swap":
			if view.use_swap():
				Save.add_power(kind, -1)
		"undo":
			if view.use_undo():
				Save.add_power(kind, -1)
		_:
			view.set_tool(kind)
			Sfx.play("power")
	_refresh_powers()


func _on_tool_used(kind: String) -> void:
	Save.add_power(kind, -1)
	_refresh_powers()


# ---------------------------------------------------------------- dialogs

## body: array of [text, size, color]. buttons: array of [text, color, callable].
func _dialog(kind: String, title: String, body: Array, buttons: Array, stars := -1) -> void:
	_close_dialog()
	dialog_kind = kind
	view.input_enabled = false
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.1, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialog = shade
	var center := CenterContainer.new()
	shade.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.card_style())
	card.custom_minimum_size = Vector2(minf(580.0, get_viewport_rect().size.x - 64.0), 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	card.add_child(v)
	var t := UI.label(title, 58, Color.WHITE, 12)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if stars >= 0:
		var sr := Widgets.StarRow.new(stars)
		sr.custom_minimum_size = Vector2(0, 110)
		sr.slam = true
		v.add_child(sr)
	_dialog_labels = []
	for line in body:
		var l := UI.label(line[0], line[1], line[2])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
		_dialog_labels.append(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	v.add_child(gap)
	for b in buttons:
		var btn := UI.button(b[0], b[1], 36, 100)
		var cb: Callable = b[2]
		btn.pressed.connect(func() -> void:
			if not Ads.busy:
				cb.call()
		)
		v.add_child(btn)
	card.pivot_offset = Vector2(card.custom_minimum_size.x / 2.0, 300)
	card.scale = Vector2(0.85, 0.85)
	card.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)


func _close_dialog() -> void:
	if dialog != null:
		dialog.queue_free()
		dialog = null
	dialog_kind = ""
	view.input_enabled = true
	_refresh_powers()


func _show_intro() -> void:
	var body: Array = [[Levels.goal_text(level), 38, c_gold]]
	if level["intro"] != "":
		body.append([level["intro"], 28, c_muted])
	body.append(["3 stars: finish within %d moves" % int(level["par"]), 24, c_muted])
	_dialog("intro", "Level %d" % level_n, body, [["Play", c_green, _close_dialog]])


func _show_daily_intro() -> void:
	var best := Save.daily_best()
	var body: Array = [["Everyone gets the same pieces today. No power-ups, no revives.", 28, c_muted]]
	body.append(["Today's best: " + (UI.fmt(best) if best >= 0 else "not played yet"), 30, c_gold])
	_dialog("intro", "Daily challenge", body, [["Play", c_green, _close_dialog]])


func _show_pause() -> void:
	if dialog != null or view.over:
		return
	view.set_tool("")
	_dialog("pause", "Paused", [], [
		["Resume", c_green, _close_dialog],
		["Restart", c_purple, func() -> void: router.start_game(mode, level_n)],
		["Menu", c_panel, func() -> void: router.show_menu()],
	])


## Android back button.
func go_back() -> void:
	if dialog_kind == "pause":
		_close_dialog()
	elif dialog_kind == "intro":
		# Backing out before the first move: return to wherever the player came from.
		if mode == "adventure":
			router.show_levels(Levels.region_of(level_n))
		else:
			router.show_menu()
	elif dialog_kind == "end":
		# Same as the last button on the end screen (Menu or Levels), so coins are still paid out.
		_finish_run(func() -> void:
			if mode == "adventure":
				router.show_levels(Levels.region_of(level_n))
			else:
				router.show_menu()
		)
	elif dialog == null:
		_show_pause()


# ---------------------------------------------------------------- endings

func _on_finished(won: bool) -> void:
	match mode:
		"classic":
			_end_classic()
		"daily":
			_end_daily()
		"adventure":
			if won:
				_end_level_win()
			else:
				_end_level_fail()


func _run_coins() -> int:
	return int(view.score / 40.0)


## Pays out coins once per run, then shows an occasional interstitial before moving on.
func _finish_run(next: Callable, bonus := 0) -> void:
	if not awarded:
		awarded = true
		Save.data["games_played"] = int(Save.data["games_played"]) + 1
		Save.add_coins(_run_coins() + bonus)
	Ads.game_finished(next)


func _end_classic() -> void:
	var s := view.score
	var is_best := s > Save.best()
	Save.set_best(s)
	var body: Array = [["Score", 26, c_muted], [UI.fmt(s), 84, Color.WHITE]]
	if is_best and s > 0:
		body.append(["New best score!", 34, c_gold])
	else:
		body.append(["Best " + UI.fmt(Save.best()), 28, c_muted])
	body.append(["+%d coins" % _run_coins(), 28, c_gold])
	var buttons: Array = []
	if not view.revived:
		buttons.append(["Watch ad to revive", c_green, _revive])
	buttons.append(["Play again", c_purple, func() -> void: _finish_run(func() -> void: router.start_game("classic"))])
	buttons.append(["Menu", c_panel, func() -> void: _finish_run(func() -> void: router.show_menu())])
	_dialog("end", "Out of space", body, buttons)


func _end_daily() -> void:
	var s := view.score
	var first := Save.daily_best() < 0
	var is_best := s > Save.daily_best()
	Save.set_daily(s)
	var bonus := 20 if first else 0
	var body: Array = [["Score", 26, c_muted], [UI.fmt(s), 84, Color.WHITE]]
	body.append(["New best today!" if is_best and not first else "Today's best " + UI.fmt(Save.daily_best()), 30, c_gold])
	body.append(["+%d coins" % (_run_coins() + bonus), 28, c_gold])
	var reward := Save.note_daily_played()
	var st := Save.streak()
	body.append(["Streak: %d day%s in a row" % [st, "" if st == 1 else "s"], 30, Color.WHITE])
	if not reward.is_empty():
		body.append([_reward_text(reward), 28, c_gold])
	_dialog("end", "Daily done", body, [
		["Try again", c_purple, func() -> void: _finish_run(func() -> void: router.start_game("daily"), bonus)],
		["Menu", c_panel, func() -> void: _finish_run(func() -> void: router.show_menu(), bonus)],
	])


static func _reward_text(r: Dictionary) -> String:
	var parts: Array = []
	for k in r:
		if k == "coins":
			parts.append("+%d coins" % int(r[k]))
		elif k == "theme":
			parts.append("%s theme" % str(Themes.get_theme(str(r[k]))["name"]))
		else:
			parts.append("+%d %s" % [int(r[k]), k])
	return "Streak reward: " + ", ".join(parts)


func _end_level_win() -> void:
	var par := int(level["par"])
	var stars := 1
	if view.placements <= par:
		stars = 3
	elif view.placements <= int(par * 1.5):
		stars = 2
	Save.set_stars(level_n, stars)
	Save.unlock(level_n + 1)
	var coins := 15 + 5 * stars
	awarded = true
	Save.data["games_played"] = int(Save.data["games_played"]) + 1
	Save.add_coins(coins)
	var body: Array = [["%d moves" % view.placements, 28, c_muted], ["+0 coins", 32, c_gold]]
	var buttons: Array = []
	if level_n < Levels.COUNT:
		buttons.append(["Next level", c_green, func() -> void: _finish_run(func() -> void: router.start_game("adventure", level_n + 1))])
	else:
		body.append(["You finished every level! More levels coming soon.", 30, Color.WHITE])
	buttons.append(["Levels", c_panel, func() -> void: _finish_run(func() -> void: router.show_levels(Levels.region_of(level_n)))])
	_dialog("end", "Level %d complete!" % level_n, body, buttons, stars)
	# Celebration: confetti over everything, and the coin line counts up after the stars land.
	var confetti := Widgets.Confetti.new()
	confetti.palette = Save.palette()
	add_child(confetti)
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var coin_label: Label = _dialog_labels[1]
	var tw := create_tween()
	tw.tween_interval(0.4 + 0.3 * stars)
	tw.tween_method(func(n) -> void:
		coin_label.text = "+%d coins" % int(n)
		Sfx.vibrate(4, false, 0.15)
	, 0, coins, 0.6)
	tw.tween_callback(func() -> void: Sfx.play("coin"))


func _end_level_fail() -> void:
	var body: Array = [[Levels.goal_text(level), 30, c_muted]]
	body.append(["Progress %d / %d" % [mini(view.goal_current, int(level["target"])), int(level["target"])], 30, c_gold])
	var buttons: Array = []
	if not view.revived:
		buttons.append(["Watch ad to revive", c_green, _revive])
	buttons.append(["Try again", c_purple, func() -> void: _finish_run(func() -> void: router.start_game("adventure", level_n))])
	buttons.append(["Levels", c_panel, func() -> void: _finish_run(func() -> void: router.show_levels(Levels.region_of(level_n)))])
	_dialog("end", "Out of space", body, buttons)


func _revive() -> void:
	Ads.show_rewarded("revive", func() -> void:
		_close_dialog()
		view.revive()
		_refresh_side()
	)
