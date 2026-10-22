class_name CreditsScreen
extends Control
## Credits and the license notices the engine requires.

var router


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Screens.frame(self, "Credits", func() -> void: router.show_settings())

	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 14)
	scroll.add_child(list)

	_entry(list, "Game", ["Made by BDS Labs"])
	_entry(list, "Sound effects", [
		"\"Interface Sounds\" and \"Impact Sounds\" by Kenney (kenney.nl)",
		"Released under CC0 (public domain). Thank you, Kenney!",
		"Line-clear notes and jingles synthesized by BDS Labs",
	])
	_entry(list, "Engine", [
		"Made with Godot Engine (godotengine.org)",
		"Godot is free and open source under the MIT license.",
	])

	var show := UI.button("Show engine licenses", Color("2c2766"), 26, 84)
	list.add_child(show)
	var licenses := Label.new()
	licenses.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	licenses.add_theme_font_size_override("font_size", 18)
	licenses.add_theme_color_override("font_color", Color(0.8, 0.78, 0.95))
	licenses.visible = false
	list.add_child(licenses)
	show.pressed.connect(func() -> void:
		if licenses.text == "":
			licenses.text = _license_text()
		licenses.visible = not licenses.visible
		show.text = "Hide engine licenses" if licenses.visible else "Show engine licenses"
	)


func go_back() -> void:
	router.show_settings()


func _entry(list: VBoxContainer, title: String, lines: Array) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(Color(0, 0, 0, 0.28), 28))
	list.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	var t := UI.label(title, 34, Color("ffd23f"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	for line in lines:
		var l := UI.label(line, 25, Color.WHITE)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)


## Godot's MIT notice plus the third-party components bundled with the engine.
static func _license_text() -> String:
	var out := Engine.get_license_text() + "\n\nThird-party components:\n"
	for c in Engine.get_copyright_info():
		out += "\n" + str(c["name"])
		for part in c["parts"]:
			for line in part["copyright"]:
				out += "\n  © " + str(line)
			out += "\n  License: " + str(part["license"])
		out += "\n"
	return out
