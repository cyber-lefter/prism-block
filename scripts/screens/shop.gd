class_name ShopScreen
extends Control
## Spend coins on themes and power-ups, or watch a rewarded ad for a few free coins.

const POWER_PACKS := [
	["hammer", "Hammer", "Smash any single block", 150],
	["rotate", "Rotate", "Turn a piece in your tray", 120],
	["swap", "Swap", "Get three new pieces", 120],
	["undo", "Undo", "Take back your last move", 120],
]
const PACK_SIZE := 3
const AD_COINS := 25

var router
var list: VBoxContainer


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
	back.pressed.connect(func() -> void: router.show_menu())
	header.add_child(back)
	var title := UI.label("Shop", 54, Color.WHITE, 12)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(Widgets.CoinPill.new())

	var scroll := ScrollContainer.new()
	UI.touch_scroll(scroll)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	_rebuild()


func go_back() -> void:
	router.show_menu()


func _section(text: String) -> void:
	var l := UI.label(text, 34, Color(0.75, 0.72, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	list.add_child(l)


func _row(left: Control, title: String, sub: String, action: Button) -> void:
	var panel := PanelContainer.new()
	var sb := UI.panel_style(Color(0, 0, 0, 0.28), 28)
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	panel.add_theme_stylebox_override("panel", sb)
	list.add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	panel.add_child(h)
	if left != null:
		h.add_child(left)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var t := UI.label(title, 32, Color.WHITE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(t)
	var s := UI.label(sub, 22, Color(0.75, 0.72, 0.95))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	action.custom_minimum_size = Vector2(190, 84)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(action)


func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()

	_section("No ads")
	# Placeholder until in-app purchases are set up; Save.data["ads_removed"] then turns off interstitials.
	var remove := UI.button("Soon", Color("2c2766"), 28, 84)
	remove.disabled = true
	_row(null, "Remove ads", "No more ads between games. Rewarded ads you choose stay.", remove)

	_section("Themes")
	for raw in Themes.LIST:
		var id: String = raw["id"]
		var price: int = raw["price"]
		var th := Themes.get_theme(id)
		var swatch := ThemeSwatch.new()
		swatch.theme_data = th
		swatch.custom_minimum_size = Vector2(150, 84)
		var action: Button
		if Save.data["theme"] == id:
			action = UI.button("In use", Color("2c2766"), 26, 84)
			action.disabled = true
		elif Save.owns_theme(id):
			action = UI.button("Use", Color("7b5cff"), 28, 84)
			action.pressed.connect(func() -> void:
				Save.set_theme(id)
				_rebuild()
			)
		else:
			action = UI.button(UI.fmt(price), Color("ffd23f"), 28, 84)
			action.disabled = Save.coins() < price
			action.pressed.connect(func() -> void:
				if Save.buy_theme(id, price):
					Sfx.play("coin")
					_rebuild()
			)
		_row(swatch, th["name"], "Owned" if Save.owns_theme(id) else "Board and block colors", action)

	_section("Power-ups")
	for p in POWER_PACKS:
		var kind: String = p[0]
		var cost: int = p[3]
		var buy := UI.button(UI.fmt(cost), Color("ffd23f"), 28, 84)
		buy.disabled = Save.coins() < cost
		buy.pressed.connect(func() -> void:
			if Save.spend(cost):
				Save.add_power(kind, PACK_SIZE)
				Sfx.play("coin")
				_rebuild()
		)
		_row(null, "%s x%d" % [p[1], PACK_SIZE], "%s. You have %d." % [p[2], Save.power_count(kind)], buy)

	_section("Free coins")
	var left := Save.ad_coins_left()
	var watch := UI.button("Watch ad", Color("2fbf71"), 28, 84)
	watch.disabled = left <= 0
	watch.pressed.connect(func() -> void:
		Ads.show_rewarded("shop_coins", func() -> void:
			Save.note_ad_coins()
			Save.add_coins(AD_COINS)
			Sfx.play("coin")
			_rebuild()
		)
	)
	_row(null, "+%d coins" % AD_COINS, "%d left today" % left, watch)


## Mini board preview in a theme's colors.
class ThemeSwatch extends Control:
	var theme_data: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = theme_data["board"]
		sb.set_corner_radius_all(18)
		draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var blocks: Array = theme_data["blocks"]
		var s := minf(size.y * 0.42, size.x / 4.6)
		for i in 4:
			var c := Vector2(size.x * (i + 0.5) / 4.0, size.y / 2.0 + (s * 0.25 if i % 2 == 0 else -s * 0.25))
			BlockArt.draw_block(self, blocks[i * 2], c, s)
