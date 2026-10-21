class_name Screens
extends RefCounted
## Shared screen scaffolding: safe-area margins and a header with Back, a title and the coin balance.


## Builds the frame inside `screen` and returns the column to fill with content.
static func frame(screen: Control, title: String, on_back: Callable, coins := false) -> VBoxContainer:
	var ins := UI.safe_insets(screen)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", int(28 + ins.x))
	margin.add_theme_constant_override("margin_bottom", int(28 + ins.y))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	margin.add_child(col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	col.add_child(header)
	var back := UI.button("Back", Color("2c2766"), 28, 80)
	back.pressed.connect(on_back)
	header.add_child(back)
	var t := UI.label(title, 54, Color.WHITE, 12)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(t)
	if coins:
		header.add_child(Widgets.CoinPill.new())
	else:
		# Balance the Back button so the title stays centered.
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(back.get_combined_minimum_size().x, 0)
		header.add_child(pad)
	return col
