class_name LevelSelect
extends Control
## One island region: a grid of its levels with stars. Locked levels are greyed out.

var router
var region := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ins := UI.safe_insets(self)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", int(28 + ins.x))
	margin.add_theme_constant_override("margin_bottom", int(24 + ins.y))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	col.add_child(header)
	var back := UI.button("Back", Color("2c2766"), 28, 80)
	back.pressed.connect(func() -> void: router.show_island())
	header.add_child(back)
	var title := UI.label(str(Levels.REGIONS[region]["name"]), 46, Color.WHITE, 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(Widgets.CoinPill.new())

	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 24)
	scroll.add_child(stack)
	stack.add_child(grid)

	# Placeholder at the end of the map until more levels ship.
	var soon := PanelContainer.new()
	var sb := UI.panel_style(Color(0, 0, 0, 0.28), 28)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.set_border_width_all(3)
	soon.add_theme_stylebox_override("panel", sb)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	soon.add_child(sv)
	sv.add_child(UI.label("Next region coming soon", 36, Color("ffd23f")))
	var sub := UI.label("New lands and mechanics are on the way. Finish this one to be ready.", 24, Color(0.75, 0.72, 0.95))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(sub)
	stack.add_child(soon)

	var unlocked := Save.unlocked()
	var current: Control = null
	var reg: Dictionary = Levels.REGIONS[region]
	for n in range(int(reg["first"]), int(reg["last"]) + 1):
		var stars := Save.stars(n)
		var open := n <= unlocked
		var color := Color("2fbf71") if stars > 0 else (Color("7b5cff") if open else Color("2c2766"))
		var b := UI.button(str(n), color, 40, 132)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not open
		var sr := Widgets.StarRow.new(stars)
		sr.custom_minimum_size = Vector2(0, 28)
		b.add_child(sr)
		sr.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		sr.offset_top = -44
		sr.offset_bottom = -14
		sr.visible = open
		var level_n := n
		b.pressed.connect(func() -> void: router.start_game("adventure", level_n))
		grid.add_child(b)
		if n == unlocked:
			current = b
	if current != null:
		scroll.ensure_control_visible.call_deferred(current)


func go_back() -> void:
	router.show_island()
