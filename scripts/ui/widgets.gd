class_name Widgets
extends RefCounted
## Small drawn controls used across screens.


## Gradient background with drifting light, faint gem blocks and a theme ambience
## (stars, petals, bubbles, hearts or a neon grid). Turns rainbow during fever.
class Backdrop extends Control:
	var t := 0.0
	var floaters: Array = []
	var ambience: Array = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 9:
			floaters.append({"x": randf(), "y": randf(), "s": randf_range(40.0, 110.0),
				"speed": randf_range(0.01, 0.035), "c": i % 8, "phase": randf() * TAU})
		for i in 36:
			ambience.append({"x": randf(), "y": randf(), "s": randf_range(0.6, 1.4),
				"speed": randf_range(0.015, 0.05), "phase": randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var th := Save.theme()
		var top: Color = th["top"]
		var bottom: Color = th["bottom"]
		var full := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
		draw_polygon(full, PackedColorArray([top, top, bottom, bottom]))
		var fever := GameView.fever_amount
		if fever > 0.0:
			# Slowly rotating rainbow wash over the whole screen.
			var cols := PackedColorArray()
			for k in 4:
				cols.append(Color.from_hsv(fmod(t * 0.12 + k * 0.25, 1.0), 0.8, 0.9, 0.3 * fever))
			draw_polygon(full, cols)
		var pal: Array = th["blocks"]
		# Big, faint pools of colored light drifting slowly behind everything.
		for k in 4:
			var lc: Color = pal[(k * 2 + 1) % pal.size()]
			var lp := Vector2(0.5 + 0.38 * sin(t * 0.07 + k * 1.7), 0.5 + 0.4 * cos(t * 0.05 + k * 2.3)) * size
			BlockArt.draw_glow(self, lp, size.x * 0.7, Color(lc, 0.07 + 0.05 * fever))
		_draw_ambience(str(th["id"]), pal)
		for f in floaters:
			var y := fposmod(float(f["y"]) - t * float(f["speed"]), 1.2) - 0.1
			var x: float = f["x"] + sin(t * 0.6 + float(f["phase"])) * 0.02
			BlockArt.draw_block(self, pal[f["c"]], Vector2(x * size.x, y * size.y), f["s"], 1.0, 0.07)

	func _draw_ambience(id: String, pal: Array) -> void:
		var u := size.x / 720.0
		if id == "neon":
			# Faint grid lines rolling downward.
			var step := 90.0 * u
			var off := fposmod(t * 30.0 * u, step)
			var gc := Color(pal[4] as Color, 0.08)
			for k in int(size.y / step) + 2:
				draw_line(Vector2(0, k * step + off), Vector2(size.x, k * step + off), gc, 2.0)
			for k in int(size.x / step) + 1:
				draw_line(Vector2(k * step, 0), Vector2(k * step, size.y), Color(gc, 0.05), 2.0)
			return
		for i in ambience.size():
			var a: Dictionary = ambience[i]
			var s: float = a["s"] * u
			var ph: float = a["phase"]
			var sp: float = a["speed"]
			match id:
				"midnight":
					# Twinkling star field.
					var tw := 0.5 + 0.5 * sin(t * (1.5 + sp * 40.0) + ph)
					BlockArt.draw_sparkle(self, Vector2(a["x"], a["y"]) * size, 9.0 * s * tw, Color(1, 1, 1, 0.35 * tw))
				"sunset":
					# Petals drifting down and sideways.
					var p := Vector2(fposmod(float(a["x"]) + t * sp * 0.5, 1.0), fposmod(float(a["y"]) + t * sp, 1.1) - 0.05) * size
					draw_set_transform(p, t * 0.8 + ph, Vector2(1.0, 0.5))
					draw_circle(Vector2.ZERO, 10.0 * s, Color(pal[i % 3 + 4] as Color, 0.18))
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"ocean":
					# Bubbles rising and wobbling.
					var p := Vector2(float(a["x"]) + sin(t + ph) * 0.015, 1.05 - fposmod(float(a["y"]) + t * sp, 1.1)) * size
					draw_arc(p, 9.0 * s, 0.0, TAU, 20, Color(1, 1, 1, 0.16), 2.0 * u, true)
					draw_circle(p + Vector2(-3, -3) * s, 2.0 * s, Color(1, 1, 1, 0.25))
				"candy":
					# Little hearts floating up.
					var p := Vector2(float(a["x"]) + sin(t * 0.7 + ph) * 0.02, 1.05 - fposmod(float(a["y"]) + t * sp * 0.7, 1.1)) * size
					var h := 8.0 * s
					var hc := Color(pal[i % 2 * 6] as Color, 0.2)
					draw_circle(p + Vector2(-h * 0.5, -h * 0.2), h * 0.55, hc)
					draw_circle(p + Vector2(h * 0.5, -h * 0.2), h * 0.55, hc)
					draw_colored_polygon(PackedVector2Array([p + Vector2(-h, 0), p + Vector2(h, 0), p + Vector2(0, h * 1.1)]), hc)


## Row of stars, `filled` of them gold. With `slam`, earned stars drop in one by one with a thud.
class StarRow extends Control:
	var filled := 0
	var total := 3
	var slam := false
	var t := 0.0
	var landed := 0

	func _init(p_filled := 0) -> void:
		filled = p_filled
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		if not slam:
			return
		t += delta
		# Each earned star lands 0.3 s after the previous one.
		while landed < filled and t >= 0.35 + landed * 0.3 + 0.18:
			landed += 1
			Sfx.play("place", 0.9 + landed * 0.12)
			Sfx.play_later("coin", 0.03, 0.8 + landed * 0.15)
			Sfx.vibrate(35 + landed * 10, true, 0.9)
		queue_redraw()

	func _draw() -> void:
		var r := minf(size.y / 2.0, size.x / (total * 2.4)) * 0.8
		var gap := r * 2.6
		var start := size.x / 2.0 - gap * (total - 1) / 2.0
		for i in total:
			var c := Vector2(start + i * gap, size.y / 2.0)
			_star(c, r, Color(1, 1, 1, 0.18))
			if i >= filled:
				continue
			var sc := 1.0
			if slam:
				var k := (t - 0.35 - i * 0.3) / 0.18
				if k < 0.0:
					continue
				# Falls in from 2.6x size and lands with a small bounce, then a burst of light.
				sc = lerpf(2.6, 1.0, minf(1.0, k)) if k < 1.0 else 1.0 + 0.12 * sin(minf(1.0, (k - 1.0) * 0.6) * PI)
				var glow := maxf(0.0, 1.0 - (k - 1.0) / 2.0) if k >= 1.0 else 0.0
				if glow > 0.0:
					BlockArt.draw_glow(self, c, r * (1.6 + (1.0 - glow) * 2.0), Color(1, 0.85, 0.3, 0.5 * glow))
			_star(c, r * sc, Color("ffd23f"))

	func _star(c: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 10:
			var a := -PI / 2.0 + k * PI / 5.0
			var rad := r if k % 2 == 0 else r * 0.45
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, col)


## Confetti shower over the whole screen; removes itself when done.
class Confetti extends Control:
	var palette: Array = []
	var bits: Array = []
	var t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var w := get_viewport_rect().size.x
		for i in 140:
			bits.append({"p": Vector2(randf() * w, randf_range(-900.0, -20.0)), "v": Vector2(randf_range(-60, 60), randf_range(180, 420)),
				"r": randf() * TAU, "vr": randf_range(-6.0, 6.0), "s": randf_range(10.0, 20.0), "phase": randf() * TAU,
				"c": palette[i % palette.size()] if not palette.is_empty() else Color.WHITE})

	func _process(delta: float) -> void:
		t += delta
		for b in bits:
			b["p"] = b["p"] + (b["v"] + Vector2(sin(t * 3.0 + float(b["phase"])) * 70.0, 0)) * delta
			b["r"] = float(b["r"]) + float(b["vr"]) * delta
		if t > 4.5:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var fade := clampf((4.5 - t) / 0.8, 0.0, 1.0)
		for b in bits:
			var s: float = b["s"]
			# Flipping paper: width wobbles as it spins.
			var flip := absf(cos(t * 5.0 + float(b["phase"])))
			draw_set_transform(b["p"], b["r"], Vector2(1.0, 0.25 + 0.75 * flip))
			draw_rect(Rect2(-s / 2.0, -s * 0.3, s, s * 0.6), Color(b["c"] as Color, fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class CoinIcon extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(40, 40)

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0
		draw_circle(c, r, Color("c98a12"))
		draw_circle(c - Vector2(0, r * 0.08), r * 0.86, Color("ffd23f"))
		draw_circle(c - Vector2(0, r * 0.08), r * 0.52, Color("ffe680"))
		draw_circle(c + Vector2(-r * 0.3, -r * 0.38), r * 0.14, Color(1, 1, 1, 0.8))


## Coin balance that updates itself when coins change.
class CoinPill extends PanelContainer:
	var label: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_stylebox_override("panel", UI.pill_style(Color(0, 0, 0, 0.3)))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		add_child(h)
		h.add_child(CoinIcon.new())
		label = UI.label(UI.fmt(Save.coins()), 32, Color("ffd23f"))
		h.add_child(label)
		Save.coins_changed.connect(_on_coins)

	func _on_coins(c: int) -> void:
		label.text = UI.fmt(c)
		pivot_offset = size / 2.0
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08)
		tw.tween_property(self, "scale", Vector2.ONE, 0.12)


## Power-up button with a drawn icon, a name and a count badge ("AD" when empty).
class PowerButton extends Button:
	var kind := "hammer"
	var title := "Hammer"
	var count := 0
	var active := false

	func _init(p_kind: String, p_title: String) -> void:
		kind = p_kind
		title = p_title
		custom_minimum_size = Vector2(132, 140)
		focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed", "disabled"]:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("2c2766") if state != "pressed" else Color("25205a")
			sb.set_corner_radius_all(28)
			sb.border_color = Color("1a1645")
			sb.border_width_bottom = 3 if state == "pressed" else 7
			add_theme_stylebox_override(state, sb)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		pressed.connect(func() -> void:
			Sfx.play("tap")
			Sfx.vibrate(8, false, 0.3)
		)

	func _draw() -> void:
		var a := 0.35 if disabled else 1.0
		var col := Color(1, 1, 1, a)
		var c := Vector2(size.x / 2.0, size.y * 0.42)
		if active:
			var glow := StyleBoxFlat.new()
			glow.draw_center = false
			glow.set_border_width_all(5)
			glow.border_color = Color("ffd23f")
			glow.set_corner_radius_all(28)
			draw_style_box(glow, Rect2(Vector2.ZERO, size))
		match kind:
			"hammer":
				draw_set_transform(c, -0.7, Vector2.ONE)
				draw_rect(Rect2(-6, -6, 12, 46), Color(0.85, 0.6, 0.35, a))
				draw_rect(Rect2(-26, -28, 52, 24), Color(0.8, 0.82, 0.92, a))
				draw_rect(Rect2(-26, -28, 52, 7), Color(1, 1, 1, 0.6 * a))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			"rotate":
				draw_arc(c, 24, -PI * 0.1, PI * 1.5, 24, col, 7.0)
				var tip := c + Vector2(cos(-PI * 0.1), sin(-PI * 0.1)) * 24
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-12, -6), tip + Vector2(12, -6), tip + Vector2(0, 12)]), col)
			"swap":
				draw_line(c + Vector2(-24, -10), c + Vector2(20, -10), col, 7.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(28, -10), c + Vector2(14, -22), c + Vector2(14, 2)]), col)
				draw_line(c + Vector2(24, 12), c + Vector2(-20, 12), col, 7.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-28, 12), c + Vector2(-14, 0), c + Vector2(-14, 24)]), col)
			"undo":
				draw_arc(c + Vector2(4, 4), 20, -PI * 0.5, PI * 0.6, 20, col, 7.0)
				draw_line(c + Vector2(4, -16), c + Vector2(-14, -16), col, 7.0)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-26, -16), c + Vector2(-12, -29), c + Vector2(-12, -3)]), col)
		var font := UI.display_font()
		draw_string(font, Vector2(0, size.y - 22), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 22, Color(0.8, 0.78, 1.0, a))
		var bc := Vector2(size.x - 22, 22)
		if count > 0:
			draw_circle(bc, 19, Color(1, 0.82, 0.25, a))
			draw_string(font, bc + Vector2(-30, 8), str(count), HORIZONTAL_ALIGNMENT_CENTER, 60, 22, Color(UI.INK, a))
		else:
			draw_circle(bc, 19, Color(0.25, 0.8, 0.5, a))
			draw_string(font, bc + Vector2(-30, 7), "AD", HORIZONTAL_ALIGNMENT_CENTER, 60, 17, Color(1, 1, 1, a))
