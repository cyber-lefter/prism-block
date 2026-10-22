extends Node
## Headless balance report: a greedy bot plays every adventure level several times
## and prints win rate and moves used, to tune stars (par) and difficulty.
## Run: godot --headless --path . res://tests/balance.tscn  (RUNS=8 by default)

var router


func _ready() -> void:
	Save.data["sound"] = false
	var runs := int(OS.get_environment("RUNS")) if OS.get_environment("RUNS") != "" else 8
	router = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(router)
	await get_tree().process_frame
	await get_tree().process_frame
	var only := OS.get_environment("LEVELS")  # e.g. LEVELS=3,7,11 to check just those
	for n in range(1, Levels.COUNT + 1):
		if only != "" and not only.split(",").has(str(n)):
			continue
		var lv := Levels.get_level(n)
		var wins: Array = []
		for r in runs:
			var res: Array = await _play(n)
			if res[0]:
				wins.append(res[1])
		wins.sort()
		var med: int = wins[wins.size() / 2] if not wins.is_empty() else -1
		var lo: int = wins[0] if not wins.is_empty() else -1
		print("BAL %d %s target=%d par=%d wins=%d/%d min=%d med=%d all=%s" % [n, lv["type"], int(lv["target"]), int(lv["par"]), wins.size(), runs, lo, med, str(wins)])
	print("BALANCE DONE")
	get_tree().quit()


func _play(level: int) -> Array:
	router.start_game("adventure", level)
	await get_tree().process_frame
	var screen: GameScreen = router.current
	screen._close_dialog()
	var view := screen.view
	var moves := 0
	while not view.over and moves < 300:
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
		if moves % 25 == 0:
			await get_tree().process_frame
	var won := view.over and not view.lost
	return [won, view.placements]
