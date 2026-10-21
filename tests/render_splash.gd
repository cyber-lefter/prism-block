extends Node
## Renders the boot splash ("Prism Blocks by BDS Labs") to res://splash.png.
## Run windowed: godot --path . res://tests/render_splash.tscn

const SIZE := Vector2i(1080, 1920)


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var art := SplashArt.new()
	art.size = Vector2(SIZE)
	vp.add_child(art)
	for i in 4:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://splash.png"))
	print("splash saved")
	get_tree().quit()


class SplashArt extends Control:
	func _draw() -> void:
		var th := Themes.get_theme("midnight")
		var top: Color = th["top"]
		var bottom: Color = th["bottom"]
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))
		var pal: Array = th["blocks"]
		BlockArt.draw_glow(self, Vector2(size.x * 0.5, size.y * 0.4), size.x * 0.75, Color(pal[6], 0.16))
		BlockArt.draw_glow(self, Vector2(size.x * 0.2, size.y * 0.75), size.x * 0.6, Color(pal[4], 0.08))
		BlockArt.draw_glow(self, Vector2(size.x * 0.85, size.y * 0.15), size.x * 0.5, Color(pal[0], 0.08))

		# Logo: a small cluster of gem blocks.
		var cells := [Vector2(-1.5, -1), Vector2(-0.5, -1), Vector2(0.5, -1), Vector2(-0.5, 0), Vector2(0.5, 0),
			Vector2(1.5, 0), Vector2(-1.5, 1), Vector2(0.5, 1), Vector2(1.5, 1)]
		var s := size.x * 0.13
		var c0 := Vector2(size.x / 2.0, size.y * 0.36)
		for i in cells.size():
			var p: Vector2 = cells[i]
			BlockArt.draw_shadow(self, c0 + p * s * 1.04, s, 0.35)
			BlockArt.draw_block(self, pal[i % pal.size()], c0 + p * s * 1.04, s)

		var font := UI.display_font()
		var w := size.x
		var ty := size.y * 0.58
		draw_string_outline(font, Vector2(0, ty + 10), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 124, 30, Color(0, 0, 0, 0.35))
		draw_string_outline(font, Vector2(0, ty), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 124, 26, UI.INK)
		draw_string(font, Vector2(0, ty), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 124, Color("ffd23f"))
		draw_string(font, Vector2(0, size.y * 0.88), "by BDS Labs", HORIZONTAL_ALIGNMENT_CENTER, w, 56, Color(1, 1, 1, 0.75))
