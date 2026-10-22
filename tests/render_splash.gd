extends Node
## Renders the boot splash ("Prism Blocks by BDS Labs") to res://splash.png.
## Run windowed: godot --path . res://tests/render_splash.tscn

# 20:9, like most current phones. The background is one flat color equal to
# boot_splash/bg_color, so on any other screen shape the extra space blends in.
const SIZE := Vector2i(1080, 2400)
const BG := Color(0.055, 0.043, 0.161)


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
		draw_rect(Rect2(Vector2.ZERO, size), BG)
		var pal: Array = th["blocks"]
		# Soft glow kept well inside the edges, so the border stays exactly BG.
		BlockArt.draw_glow(self, Vector2(size.x * 0.5, size.y * 0.42), size.x * 0.48, Color(pal[6], 0.22))

		# Logo: a small cluster of gem blocks.
		var cells := [Vector2(-1.5, -1), Vector2(-0.5, -1), Vector2(0.5, -1), Vector2(-0.5, 0), Vector2(0.5, 0),
			Vector2(1.5, 0), Vector2(-1.5, 1), Vector2(0.5, 1), Vector2(1.5, 1)]
		var s := size.x * 0.13
		var c0 := Vector2(size.x / 2.0, size.y * 0.38)
		for i in cells.size():
			var p: Vector2 = cells[i]
			BlockArt.draw_shadow(self, c0 + p * s * 1.04, s, 0.35)
			BlockArt.draw_block(self, pal[i % pal.size()], c0 + p * s * 1.04, s)

		var font := UI.display_font()
		var w := size.x
		var ty := size.y * 0.54
		draw_string_outline(font, Vector2(0, ty + 10), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 160, 36, Color(0, 0, 0, 0.35))
		draw_string_outline(font, Vector2(0, ty), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 160, 32, UI.INK)
		draw_string(font, Vector2(0, ty), "Prism Blocks", HORIZONTAL_ALIGNMENT_CENTER, w, 160, Color("ffd23f"))
		draw_string(font, Vector2(0, size.y * 0.84), "by BDS Labs", HORIZONTAL_ALIGNMENT_CENTER, w, 64, Color(1, 1, 1, 0.75))
