class_name IslandMap
extends Control
## Adventure overview: one big island split into regions, climbed from the beach to the peak.
## Open regions show their name and progress; regions still to come sit under fog with a "?".

var router
var view: IslandView


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Screens.frame(self, "Adventure", func() -> void: router.show_menu(), true)
	view = IslandView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.region_tapped.connect(_on_region)
	col.add_child(view)


func _on_region(r: int) -> void:
	if Levels.region_open(r):
		router.show_levels(r)
	elif Levels.region_ready(r):
		view.toast(r, "Finish %s first" % str(Levels.REGIONS[r - 1]["name"]))
	else:
		view.toast(r, "Coming soon")


func go_back() -> void:
	router.show_menu()


## The drawn island. Everything is generated from a fixed seed, so the map never changes.
class IslandView extends Control:
	signal region_tapped(r: int)

	const SEA_TOP := Color("1f6fb8")
	const SEA_BOTTOM := Color("0d3b74")
	const SAND := Color("f3d58c")
	const INK := Color(0.08, 0.05, 0.2)

	var t := 0.0
	var shore := PackedVector2Array()
	var blobs: Array = []
	var decor: Array = []
	var waves: Array = []
	var toasts := {}
	var font: Font

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		clip_contents = true
		font = UI.display_font()
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		# Island outline in unit space: a lumpy oval.
		for k in 64:
			var a := TAU * k / 64.0
			var r := 1.0 + 0.06 * sin(a * 3.0 + 1.3) + 0.04 * sin(a * 7.0) + rng.randf_range(-0.015, 0.015)
			shore.append(Vector2(0.5 + cos(a) * 0.45 * r, 0.47 + sin(a) * 0.45 * r))
		# Each region is a lumpy patch of its own land colour.
		for i in Levels.REGIONS.size():
			var pts := PackedVector2Array()
			var c: Vector2 = Levels.REGIONS[i]["pos"]
			for k in 24:
				var a := TAU * k / 24.0
				var r := 0.165 * (1.0 + 0.12 * sin(a * 3.0 + i) + rng.randf_range(-0.05, 0.05))
				pts.append(c + Vector2(cos(a) * r * 1.25, sin(a) * r * 0.62))
			blobs.append(pts)
		# Scenery: what kind of thing grows where depends on the region.
		var kinds := [["tree", "tree", "flower", "flower", "gem", "house"], ["pine", "rock", "snow"],
			["cactus", "rock", "dune"], ["palm", "palm", "bush"], ["crystal", "crystal", "rock"], ["rock", "rock", "crystal"]]
		for i in Levels.REGIONS.size():
			var c: Vector2 = Levels.REGIONS[i]["pos"]
			var list: Array = kinds[i]
			for k in 9:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.08, 0.2)
				var p := c + Vector2(cos(a) * d * 1.2, sin(a) * d * 0.55)
				decor.append({"p": p, "kind": list[k % list.size()], "region": i, "s": rng.randf_range(0.8, 1.2),
					"c": rng.randi_range(0, 7), "ph": rng.randf() * TAU})
		decor.sort_custom(func(a, b): return a["p"].y < b["p"].y)
		for k in 18:
			waves.append({"p": Vector2(rng.randf(), rng.randf()), "ph": rng.randf() * TAU})

	func _process(delta: float) -> void:
		t += delta
		for r in toasts.keys():
			toasts[r] -= delta
			if toasts[r] <= 0.0:
				toasts.erase(r)
		queue_redraw()

	func toast(r: int, text: String) -> void:
		toasts[r] = 1.6
		set_meta("toast_%d" % r, text)
		Sfx.play("tap", 0.8)
		Sfx.vibrate(12, false, 0.4)

	## Map unit space to pixels, keeping the island's proportions.
	func _xf(p: Vector2) -> Vector2:
		var s := minf(size.x, size.y * 0.78)
		var off := Vector2((size.x - s) / 2.0, (size.y - s / 0.78) / 2.0)
		return off + Vector2(p.x * s, p.y * s / 0.78)

	func _unit() -> float:
		return minf(size.x, size.y * 0.78) / 640.0

	func _gui_input(event: InputEvent) -> void:
		var pos := Vector2.INF
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pos = mb.position
		var touch := event as InputEventScreenTouch
		if touch != null and touch.pressed:
			pos = touch.position
		if pos == Vector2.INF:
			return
		var best := -1
		var best_d := 110.0 * _unit()
		for i in Levels.REGIONS.size():
			var d := pos.distance_to(_xf(Levels.REGIONS[i]["pos"]))
			if d < best_d:
				best_d = d
				best = i
		if best >= 0:
			accept_event()
			region_tapped.emit(best)

	func _draw() -> void:
		var u := _unit()
		var rect := Rect2(Vector2.ZERO, size)
		var sea := StyleBoxFlat.new()
		sea.bg_color = SEA_BOTTOM
		sea.set_corner_radius_all(int(40 * u))
		draw_style_box(sea, rect)
		draw_polygon(PackedVector2Array([Vector2(12, 12), Vector2(size.x - 12, 12), size - Vector2(12, 12), Vector2(12, size.y - 12)]),
			PackedColorArray([Color(SEA_TOP, 0.9), Color(SEA_TOP, 0.9), Color(SEA_BOTTOM, 0.0), Color(SEA_BOTTOM, 0.0)]))
		for w in waves:
			var p := Vector2(w["p"].x * size.x, w["p"].y * size.y)
			var a := 0.25 + 0.2 * sin(t * 1.3 + float(w["ph"]))
			draw_arc(p + Vector2(sin(t * 0.5 + float(w["ph"])) * 6.0 * u, 0), 14.0 * u, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, a), 3.0 * u)
		_draw_island(u)
		_draw_path(u)
		for d in decor:
			_draw_decor(d, u)
		for i in Levels.REGIONS.size():
			if not Levels.region_open(i):
				_draw_fog(i, u)
		for i in Levels.REGIONS.size():
			_draw_badge(i, u)
		_draw_boat(u)

	func _poly(unit_pts: PackedVector2Array, offset := Vector2.ZERO, grow := 1.0, center := Vector2(0.5, 0.47)) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in unit_pts:
			out.append(_xf(center + (p - center) * grow) + offset)
		return out

	func _draw_island(u: float) -> void:
		# Shallow-water ring with a slow pulse, then the beach, then the grass.
		var pulse := 1.07 + 0.008 * sin(t * 1.2)
		draw_colored_polygon(_poly(shore, Vector2.ZERO, pulse), Color(0.45, 0.85, 0.95, 0.35))
		draw_colored_polygon(_poly(shore, Vector2(0, 10 * u), 1.0), SAND.darkened(0.25))
		draw_colored_polygon(_poly(shore), SAND)
		draw_colored_polygon(_poly(shore, Vector2.ZERO, 0.9), Color("4fae5a"))
		for i in Levels.REGIONS.size():
			var land := Color(str(Levels.REGIONS[i]["land"]))
			var c: Vector2 = Levels.REGIONS[i]["pos"]
			draw_colored_polygon(_poly(blobs[i], Vector2(0, 6 * u), 1.0, c), land.darkened(0.3))
			draw_colored_polygon(_poly(blobs[i], Vector2.ZERO, 1.0, c), land)

	func _draw_path(u: float) -> void:
		# Dotted trail from region to region, lit up to the furthest open one.
		var n := Levels.REGIONS.size()
		for i in n - 1:
			var a := _xf(Levels.REGIONS[i]["pos"])
			var b := _xf(Levels.REGIONS[i + 1]["pos"])
			var mid := (a + b) / 2.0 + Vector2(-(b - a).y, (b - a).x).normalized() * 40.0 * u * (1 if i % 2 == 0 else -1)
			var lit := Levels.region_open(i + 1)
			var steps := 14
			for k in range(1, steps):
				var q := float(k) / steps
				var p := a.lerp(mid, q).lerp(mid.lerp(b, q), q)
				draw_circle(p + Vector2(0, 2 * u), 6.0 * u, Color(0, 0, 0, 0.25))
				draw_circle(p, 6.0 * u, Color("fff4d6") if lit else Color(1, 1, 1, 0.45))

	func _draw_decor(d: Dictionary, u: float) -> void:
		var p := _xf(d["p"])
		var s: float = d["s"] * u
		var sway := sin(t * 1.4 + float(d["ph"])) * 2.0 * s
		match d["kind"]:
			"tree":
				draw_rect(Rect2(p + Vector2(-4, -14) * s, Vector2(8, 16) * s), Color("7a4a2a"))
				draw_circle(p + Vector2(sway, -26 * s), 17.0 * s, Color("2f8f3e"))
				draw_circle(p + Vector2(sway - 6 * s, -31 * s), 8.0 * s, Color("49b356"))
			"pine", "snow":
				var col := Color("2f6f5a") if d["kind"] == "pine" else Color("dfefff")
				draw_colored_polygon(PackedVector2Array([p + Vector2(-16, 0) * s, p + Vector2(16, 0) * s, p + Vector2(sway, -40 * s)]), col)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -24) * s, p + Vector2(8, -24) * s, p + Vector2(sway, -40 * s)]), Color.WHITE)
			"palm":
				draw_line(p, p + Vector2(6 * s + sway, -34 * s), Color("8a5a2b"), 5.0 * s)
				var top := p + Vector2(6 * s + sway, -34 * s)
				for k in 5:
					var a := PI + k * PI / 4.0
					draw_line(top, top + Vector2(cos(a), sin(a) * 0.5 + 0.35) * 20.0 * s, Color("2fa84f"), 6.0 * s)
			"bush":
				draw_circle(p, 12.0 * s, Color("2b7d4c"))
				draw_circle(p + Vector2(10, 3) * s, 9.0 * s, Color("3a9a5c"))
			"cactus":
				draw_rect(Rect2(p + Vector2(-5, -30) * s, Vector2(10, 30) * s), Color("3b8f4a"))
				draw_rect(Rect2(p + Vector2(-14, -20) * s, Vector2(9, 6) * s), Color("3b8f4a"))
				draw_rect(Rect2(p + Vector2(-14, -28) * s, Vector2(6, 10) * s), Color("3b8f4a"))
			"dune":
				draw_arc(p, 18.0 * s, PI * 1.1, PI * 1.9, 10, Color("d9a64a"), 4.0 * s)
			"rock":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 0) * s, p + Vector2(-8, -14) * s, p + Vector2(6, -16) * s, p + Vector2(14, 0) * s]), Color("8d8aa3"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -14) * s, p + Vector2(6, -16) * s, p + Vector2(2, -8) * s]), Color("b4b1c7"))
			"crystal":
				var cc: Color = Save.palette()[int(d["c"])]
				draw_colored_polygon(PackedVector2Array([p + Vector2(-7, 0) * s, p + Vector2(0, -28) * s, p + Vector2(7, 0) * s]), cc)
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -28) * s, p + Vector2(7, 0) * s, p + Vector2(2, 0) * s]), cc.lightened(0.35))
			"flower":
				draw_line(p, p + Vector2(0, -10) * s, Color("2f8f3e"), 2.0 * s)
				draw_circle(p + Vector2(0, -12) * s, 5.0 * s, Save.palette()[int(d["c"])])
				draw_circle(p + Vector2(0, -12) * s, 2.0 * s, Color("fff4a0"))
			"gem":
				BlockArt.draw_block(self, Save.palette()[int(d["c"])], p + Vector2(0, -12 * s + sin(t * 2.0 + float(d["ph"])) * 3.0 * s), 24.0 * s)
			"house":
				draw_rect(Rect2(p + Vector2(-14, -18) * s, Vector2(28, 18) * s), Color("f4e1c1"))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-18, -18) * s, p + Vector2(18, -18) * s, p + Vector2(0, -34) * s]), Color("d9534f"))
				draw_rect(Rect2(p + Vector2(-4, -10) * s, Vector2(8, 10) * s), Color("7a4a2a"))

	func _draw_fog(i: int, u: float) -> void:
		var c := _xf(Levels.REGIONS[i]["pos"])
		for k in 7:
			var a := TAU * k / 7.0 + t * 0.15 + i
			var p := c + Vector2(cos(a) * 62.0, sin(a) * 28.0) * u
			draw_circle(p, (38.0 + 6.0 * sin(t * 0.8 + k)) * u, Color(0.9, 0.92, 1.0, 0.55))
		draw_circle(c, 52.0 * u, Color(0.92, 0.94, 1.0, 0.7))

	func _draw_badge(i: int, u: float) -> void:
		var reg: Dictionary = Levels.REGIONS[i]
		var c := _xf(reg["pos"])
		var open := Levels.region_open(i)
		if not open:
			# Locked: a "?" seal and a small "soon" tag.
			var bob := sin(t * 2.0 + i) * 3.0 * u
			draw_circle(c + Vector2(0, 5 * u + bob), 30.0 * u, Color(INK, 0.5))
			draw_circle(c + Vector2(0, bob), 30.0 * u, Color("2c2766"))
			draw_arc(c + Vector2(0, bob), 30.0 * u, 0, TAU, 32, Color(1, 1, 1, 0.5), 3.0 * u)
			_text("?", c + Vector2(0, 14 * u + bob), 42.0 * u, Color("ffd23f"))
			var tag := "Soon" if not Levels.region_ready(i) else "Locked"
			_pill(tag, c + Vector2(0, 52 * u), 22.0 * u, Color(1, 1, 1, 0.85), INK)
		else:
			var first := int(reg["first"])
			var last := int(reg["last"])
			var done := 0
			var stars := 0
			for n in range(first, last + 1):
				var s := Save.stars(n)
				stars += s
				if s > 0:
					done += 1
			var glow := 0.6 + 0.4 * sin(t * 2.5)
			BlockArt.draw_glow(self, c, 90.0 * u, Color(1, 0.9, 0.5, 0.35 * glow))
			# Landmark: a little stack of gem blocks, then the name and progress underneath.
			var pal: Array = Save.palette()
			var stack := [Vector2(-0.55, 0), Vector2(0.55, 0), Vector2(0, -1)]
			for k in stack.size():
				var bob := sin(t * 2.2 + k * 0.9) * 3.0 * u
				BlockArt.draw_block(self, pal[(k * 3 + i) % pal.size()], c + stack[k] * 36.0 * u + Vector2(0, bob - 10 * u), 36.0 * u)
			_pill(str(reg["name"]), c + Vector2(0, 42 * u), 30.0 * u, Color("ffd23f"), INK)
			_pill("%d/%d levels   %d/%d stars" % [done, last - first + 1, stars, (last - first + 1) * 3], c + Vector2(0, 80 * u), 21.0 * u, Color(INK, 0.85), Color.WHITE)
		if toasts.has(i):
			var a := clampf(toasts[i] / 0.3, 0.0, 1.0)
			_pill(str(get_meta("toast_%d" % i, "")), c + Vector2(0, -50 * u), 24.0 * u, Color(Color.WHITE, a), Color(INK, a))

	func _draw_boat(u: float) -> void:
		var p := Vector2(size.x * (0.12 + 0.03 * sin(t * 0.3)), size.y * 0.9 + sin(t * 1.6) * 3.0 * u)
		var rock := sin(t * 1.6) * 0.06
		draw_set_transform(p, rock, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-28, 0) * u, Vector2(28, 0) * u, Vector2(18, 12) * u, Vector2(-18, 12) * u]), Color("8a5a2b"))
		draw_line(Vector2(0, 0), Vector2(0, -40) * u, Color("5a3a1b"), 3.0 * u)
		draw_colored_polygon(PackedVector2Array([Vector2(2, -38) * u, Vector2(2, -6) * u, Vector2(24, -8) * u]), Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _text(s: String, baseline_center: Vector2, fs: float, col: Color) -> void:
		var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs)).x
		var p := baseline_center - Vector2(w / 2.0, 0)
		draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), maxi(4, int(fs / 5.0)), Color(INK, col.a))
		draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), col)

	## Rounded label centred on `c`.
	func _pill(s: String, c: Vector2, fs: float, bg: Color, fg: Color) -> void:
		var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs))
		var r := Rect2(c - Vector2(sz.x / 2.0 + fs * 0.6, fs * 0.75), Vector2(sz.x + fs * 1.2, fs * 1.5))
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.set_corner_radius_all(int(r.size.y / 2.0))
		sb.shadow_color = Color(0, 0, 0, 0.3 * bg.a)
		sb.shadow_size = 4
		draw_style_box(sb, r)
		draw_string(font, Vector2(r.position.x + fs * 0.6, c.y + fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(fs), fg)
