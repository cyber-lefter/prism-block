extends Node
## Captures screenshots of a staged multi-line combo clear into build/shots/.
## Run windowed (not headless): godot --path . res://tests/screenshot.tscn

func _ready() -> void:
	Save.data["sound"] = false
	Save.data["haptics"] = false
	var router = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(router)
	for i in 3:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/shots"))
	await _shot("menu")
	print("recorded place variants: ", (Sfx.sounds["place"] as Array).size() if Sfx.sounds["place"] is Array else 0)
	router.show_settings()
	for i in 3:
		await get_tree().process_frame
	await _shot("settings")
	router.show_credits()
	for i in 3:
		await get_tree().process_frame
	await _shot("credits")

	router.start_game("classic")
	for i in 3:
		await get_tree().process_frame
	var screen: GameScreen = router.current
	var view := screen.view
	# Stage: rows 5-7 full except column 3, a few scattered blocks above, combo already running.
	for y in range(5, 8):
		for x in 8:
			if x != 3:
				view.color[y * 8 + x] = 1 + (x + y) % 8
	for i in [9, 10, 18, 26, 27, 34]:
		view.color[i] = 1 + i % 8
	# Streak 4, so this clear starts fever mode.
	view.streak = 4
	view.score = 1240
	view._update_near_lines()
	var vertical: Dictionary = Shapes.by_cells([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)])
	view.tray[0] = {"shape": vertical, "color": 4, "bomb": -1}
	for i in 30:
		await get_tree().process_frame
	await _shot("board")
	view._place(0, 3, 5)
	await get_tree().process_frame
	await _shot("clear_0")
	await _wait(0.12)
	await _shot("clear_1")
	await _wait(0.25)
	await _shot("clear_2")
	await _wait(0.6)
	await _shot("fever")

	# Game over: fill the board in a checkerboard so nothing fits, then watch it crumble.
	for i in 64:
		view.color[i] = 1 + i % 8 if (i % 8 + i / 8) % 2 == 0 else 0
	var big: Dictionary = Shapes.by_cells([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])
	for k in 3:
		view.tray[k] = {"shape": big, "color": k, "bomb": -1}
	view._check_over()
	await _wait(0.3)
	await _shot("over_0")
	await _wait(0.6)
	await _shot("over_1")

	# Level complete: adventure level 1 with its goal met.
	router.start_game("adventure", 1)
	for i in 3:
		await get_tree().process_frame
	screen = router.current
	screen._close_dialog()
	screen.view.score = int(screen.level["target"])
	screen.view.goal_current = int(screen.level["target"])
	screen.view.placements = 5
	screen.view._after_move()
	await _wait(2.2)
	await _shot("level_done")
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://build/shots/%s.png" % name))
