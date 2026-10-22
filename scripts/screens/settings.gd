class_name SettingsScreen
extends Control
## Sound, the two vibration levels, reduced effects, and the way into Credits.

var router


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Screens.frame(self, "Settings", func() -> void: router.show_menu())

	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)

	list.add_child(_toggle("Sound", "Clicks, pops and music notes", "sound"))
	list.add_child(_toggle("Minor vibrations", "Dragging, snapping, placing, buttons", "haptics_minor"))
	list.add_child(_toggle("Major vibrations", "Clears, combos, bombs, fever, game over", "haptics_major"))
	list.add_child(_toggle("Reduced effects", "Less shaking, flashing and particles", "reduced_fx"))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	list.add_child(gap)
	var credits := UI.menu_button("Credits", "The people behind the game", Color("2fc6f6"))
	credits.pressed.connect(func() -> void: router.show_credits())
	list.add_child(credits)

	col.add_child(UI.label("Prism Blocks %s · by BDS Labs" % ProjectSettings.get_setting("application/config/version", "0.1.0"), 22, Color(0.75, 0.72, 0.95)))


func go_back() -> void:
	router.show_menu()


## A switch row: title and explanation on the left, an On/Off pill on the right.
func _toggle(title: String, sub: String, key: String) -> Button:
	var b := UI.button("", Color("2c2766"), 30, 124)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 16)
	b.add_child(h)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 28
	h.offset_right = -24
	h.offset_bottom = -6
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := UI.label(title, 34, Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	var s := UI.label(sub, 21, Color(0.75, 0.72, 0.95))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.custom_minimum_size = Vector2(110, 0)
	h.add_child(pill)
	var state := UI.label("", 28, Color.WHITE)
	pill.add_child(state)
	var sync := func() -> void:
		var on: bool = Save.data.get(key, true)
		state.text = "On" if on else "Off"
		state.label_settings.font_color = UI.INK if on else Color(1, 1, 1, 0.7)
		pill.add_theme_stylebox_override("panel", UI.pill_style(Color("3fdc8a") if on else Color(1, 1, 1, 0.12)))
	sync.call()
	b.pressed.connect(func() -> void:
		Save.data[key] = not Save.data.get(key, true)
		Save.save()
		sync.call()
		Sfx.play("toggle")
		if key == "haptics_minor" and Save.data[key]:
			Sfx.vibrate(12, false, 0.4)
		elif key == "haptics_major" and Save.data[key]:
			Sfx.vibrate(80, true, 1.0)
	)
	return b
