class_name UI
extends RefCounted
## Shared styling helpers: fonts, labels, chunky buttons, panels and number formatting.

const INK := Color(0.08, 0.05, 0.2)

static var _font: Font


## Drop LilitaOne-Regular.ttf (free, OFL) into res://fonts/ and it is used everywhere.
static func display_font() -> Font:
	if _font == null:
		if ResourceLoader.exists("res://fonts/LilitaOne-Regular.ttf"):
			_font = load("res://fonts/LilitaOne-Regular.ttf")
		else:
			var f := SystemFont.new()
			f.font_names = PackedStringArray(["Arial Rounded MT Bold", "Nunito", "Roboto", "sans-serif"])
			f.font_weight = 800
			_font = f
	return _font


static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func label(text: String, size := 32, color := Color.WHITE, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = display_font()
	ls.font_size = size
	ls.font_color = color
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = INK
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func ink_for(bg: Color) -> Color:
	return INK if bg.get_luminance() > 0.55 else Color.WHITE


static func button(text: String, color: Color, size := 34, height := 96) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", display_font())
	b.add_theme_font_size_override("font_size", size)
	var states := {
		"normal": color, "hover": color.lightened(0.08),
		"pressed": color.darkened(0.08), "disabled": color.darkened(0.45),
	}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.set_corner_radius_all(26)
		sb.border_color = color.darkened(0.38)
		sb.border_width_bottom = 3 if state == "pressed" else 8
		sb.content_margin_left = 20
		sb.content_margin_right = 20
		sb.content_margin_top = 10 if state != "pressed" else 15
		sb.content_margin_bottom = 14 if state != "pressed" else 9
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var ink := ink_for(color)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, ink)
	b.add_theme_color_override("font_disabled_color", Color(ink, 0.45))
	b.pressed.connect(func() -> void:
		Sfx.play("tap")
		Sfx.vibrate(8, false, 0.3)
	)
	b.button_down.connect(func() -> void: _squash(b, 0.95))
	b.button_up.connect(func() -> void: _squash(b, 1.0))
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	return b


## Big menu button with a title and a smaller second line.
static func menu_button(title: String, sub: String, color: Color) -> Button:
	var b := button("", color, 40, 132)
	var ink := ink_for(color)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_bottom = -6
	v.add_child(label(title, 42, ink))
	v.add_child(label(sub, 24, Color(ink, 0.75)))
	return b


static func _squash(c: Control, to: float) -> void:
	if not c.is_inside_tree():
		return
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(to, to), 0.08)


static func panel_style(color: Color, radius := 32) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 24
	sb.content_margin_bottom = 24
	return sb


static func card_style() -> StyleBoxFlat:
	var sb := panel_style(Color("251f5c"), 40)
	sb.border_color = Color(1, 1, 1, 0.08)
	sb.set_border_width_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 30
	sb.content_margin_left = 36
	sb.content_margin_right = 36
	sb.content_margin_top = 36
	sb.content_margin_bottom = 32
	return sb


static func pill_style(color: Color) -> StyleBoxFlat:
	var sb := panel_style(color, 999)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	return sb


## Phone notch and gesture-bar insets, in viewport units: (top, bottom).
static func safe_insets(ctrl: Control) -> Vector2:
	if OS.get_name() not in ["Android", "iOS"]:
		return Vector2.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.y <= 0:
		return Vector2.ZERO
	var k := ctrl.get_viewport_rect().size.y / float(screen.y)
	return Vector2(safe.position.y * k, (screen.y - safe.end.y) * k)


## Makes a ScrollContainer drag smoothly with a finger even when the drag starts on a button,
## and stops that button from firing once the list has started moving.
static func touch_scroll(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = 18
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.add_child(TouchScroll.new(), false, Node.INTERNAL_MODE_FRONT)


class TouchScroll extends Node:
	var scroll: ScrollContainer

	func _ready() -> void:
		scroll = get_parent()
		get_tree().node_added.connect(_on_node_added)
		scroll.scroll_started.connect(_cancel_presses)
		_pass_all(scroll)

	func _on_node_added(n: Node) -> void:
		if n is Control and scroll.is_ancestor_of(n):
			_pass_all(n)

	## Controls that stop mouse events would keep the drag from reaching the scroll container.
	func _pass_all(n: Node) -> void:
		if n != scroll and n is Control and (n as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			(n as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		for c in n.get_children():
			_pass_all(c)

	## Toggling disabled clears a button's half-finished press, so lifting the finger does nothing.
	func _cancel_presses() -> void:
		_cancel(scroll)

	func _cancel(n: Node) -> void:
		var b := n as BaseButton
		if b != null and not b.disabled:
			b.disabled = true
			b.disabled = false
			b.scale = Vector2.ONE
		for c in n.get_children():
			_cancel(c)
