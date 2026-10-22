class_name MainMenu
extends Control
## Title screen: modes, shop and settings.

var router


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ins := UI.safe_insets(self)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", int(28 + ins.x))
	margin.add_theme_constant_override("margin_bottom", int(36 + ins.y))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(top)
	var settings := UI.button("Settings", Color("2c2766"), 26, 72)
	settings.pressed.connect(func() -> void: router.show_settings())
	top.add_child(settings)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	top.add_child(Widgets.CoinPill.new())

	var logo := MenuLogo.new()
	logo.custom_minimum_size = Vector2(0, 170)
	logo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(logo)
	col.add_child(UI.label("Prism Blocks", 88, Color("ffd23f"), 20))
	col.add_child(UI.label("Drop. Clear. Combo.", 30, Color(1, 1, 1, 0.7)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	col.add_child(gap)

	var best := Save.best()
	var classic := UI.menu_button("Classic", "Best " + UI.fmt(best) if best > 0 else "Endless mode", Color("7b5cff"))
	classic.pressed.connect(func() -> void: router.start_game("classic"))
	col.add_child(classic)

	var lvl := Save.unlocked()
	var adv_sub := "Level %d of %d" % [lvl, Levels.COUNT]
	if lvl >= Levels.COUNT and Save.stars(Levels.COUNT) > 0:
		adv_sub = "All done! More levels soon"
	var adventure := UI.menu_button("Adventure", adv_sub, Color("2fbf71"))
	adventure.pressed.connect(func() -> void: router.show_island())
	col.add_child(adventure)

	var daily_best := Save.daily_best()
	var daily_sub := "New puzzle today" if daily_best < 0 else "Today's best " + UI.fmt(daily_best)
	var streak := Save.streak()
	if streak > 0:
		daily_sub = ("%d-day streak. " % streak) + ("Done today" if Save.played_daily_today() else "Keep it going!")
	var daily := UI.menu_button("Daily challenge", daily_sub, Color("ff9a3c"))
	daily.pressed.connect(func() -> void: router.start_game("daily"))
	col.add_child(daily)

	var shop := UI.menu_button("Shop", "Themes and power-ups", Color("2fc6f6"))
	shop.pressed.connect(func() -> void: router.show_shop())
	col.add_child(shop)
	col.add_child(UI.label("by BDS Labs", 24, Color(1, 1, 1, 0.45)))


## A cluster of gem blocks gently bobbing above the title.
class MenuLogo extends Control:
	var t := 0.0
	const CELLS := [
		Vector2(-1.5, -1), Vector2(-0.5, -1), Vector2(0.5, -1),
		Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(1.5, 0),
		Vector2(-1.5, 1), Vector2(0.5, 1), Vector2(1.5, 1),
	]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var pal: Array = Save.palette()
		var s := minf(size.y / 3.6, 92.0)
		var c0 := size / 2.0
		for i in CELLS.size():
			var bob := sin(t * 2.2 + i * 0.7) * s * 0.06
			var p: Vector2 = CELLS[i]
			BlockArt.draw_block(self, pal[i % pal.size()], c0 + p * s * 1.04 + Vector2(0, bob), s)
