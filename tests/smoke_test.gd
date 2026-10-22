extends Node
## Headless smoke test: plays every mode with a simple bot and exercises power-ups.
## Run: godot --headless --path . res://tests/smoke_test.tscn

var router


func _ready() -> void:
	# Set BAKE_SOUNDS=1 to re-synthesize every sound into res://sounds/*.wav (only needed after editing sfx.gd).
	if OS.get_environment("BAKE_SOUNDS") == "1":
		var t0 := Time.get_ticks_msec()
		Sfx.synthesize()
		print("sound synthesis: %d ms" % (Time.get_ticks_msec() - t0))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Sfx.BAKED_DIR))
		for key in Sfx.NAMES:
			var wav: AudioStreamWAV = Sfx.sounds[key]
			wav.save_to_wav(ProjectSettings.globalize_path(Sfx.BAKED_DIR + key + ".wav"))
		Sfx.load_recorded()
	Save.data["sound"] = false
	Save.data["haptics"] = false
	router = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(router)
	await get_tree().process_frame
	await get_tree().process_frame

	router.show_island()
	await get_tree().process_frame
	router.show_levels()
	await get_tree().process_frame
	router.show_shop()
	await get_tree().process_frame
	router.show_menu()
	await get_tree().process_frame

	var report := []
	for mode in ["classic", "daily"]:
		report.append(await _play(mode, 0))
	var wins := 0
	for n in range(1, Levels.COUNT + 1):
		var line: String = await _play("adventure", n)
		if line.contains("lost false"):
			wins += 1
		else:
			report.append(line)
	report.append("bot cleared %d of %d adventure levels" % [wins, Levels.COUNT])
	for n in range(1, Levels.COUNT + 1):
		var lv := Levels.get_level(n)
		assert(int(lv["target"]) > 0, "level %d has no target" % n)
	for line in report:
		print(line)
	print("SMOKE TEST DONE")
	get_tree().quit()


func _play(mode: String, level: int) -> String:
	router.start_game(mode, level)
	await get_tree().process_frame
	await get_tree().process_frame
	var screen: GameScreen = router.current
	screen._close_dialog()
	var view := screen.view
	var moves := 0
	var t0 := Time.get_ticks_msec()
	while not view.over and moves < 250:
		# Greedy bot: the move that clears the most lines, then the one leaving the emptiest board.
		var best := []
		var best_score := -INF
		var occ := view.occupancy()
		var sticky := view.sticky()
		for slot in 3:
			var p = view.tray[slot]
			if p == null:
				continue
			for y in 8:
				for x in 8:
					if not BoardLogic.fits(occ, p["shape"], x, y):
						continue
					var after := BoardLogic.sim_place(occ, sticky, p["shape"], x, y)
					var sc := -BoardLogic.fill_ratio(after) * 10.0 + y * 0.01
					if sc > best_score:
						best_score = sc
						best = [slot, x, y]
		if not best.is_empty():
			view._place(best[0], best[1], best[2])
		moves += 1
		if moves == 5 and mode != "daily":
			view.use_undo()
			view.use_swap()
			view.set_tool("rotate")
			view._rotate(0)
			for i in 64:
				if view.color[i] != 0:
					view.set_tool("hammer")
					view._hammer(Vector2i(i % 8, i / 8))
					break
		if moves % 20 == 0:
			await get_tree().process_frame
	var lost := view.lost
	if lost and not view.revived:
		view.revive()
	for i in 15:
		await get_tree().process_frame
	var ms := Time.get_ticks_msec() - t0
	return "%s %d: %d moves, score %d, goal %d, lost %s, %d ms" % [mode, level, moves, view.score, view.goal_current, lost, ms]
