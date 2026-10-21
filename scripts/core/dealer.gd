class_name Dealer
extends RefCounted
## Fair dealer. Every tray has at least one order in which all three pieces fit.
## Difficulty depends only on score (and the level in adventure), the same for every player.

var rng := RandomNumberGenerator.new()
var recent_groups: Array = []
var trays := 0
var base := 0.18
var ramp := 0.55


func target_difficulty(score: int) -> float:
	var d := base + ramp * (1.0 - exp(-score / 2500.0))
	return minf(0.95, d + sin(trays * 0.9) * 0.08)


func pick(difficulty: float) -> Dictionary:
	var total := 0.0
	var ws := PackedFloat32Array()
	for s in Shapes.all:
		var w: float = s["gw"] * (0.08 + exp(-pow(s["d"] - difficulty, 2) / (2.0 * 0.22 * 0.22)))
		ws.append(w)
		total += w
	var r := rng.randf() * total
	for i in ws.size():
		r -= ws[i]
		if r <= 0.0:
			return Shapes.all[i]
	return Shapes.all[Shapes.all.size() - 1]


func deal(occ: PackedByteArray, sticky: PackedByteArray, score: int) -> Array:
	var difficulty := target_difficulty(score)
	var fill := BoardLogic.fill_ratio(occ)
	var best: Array = []
	var best_score := -INF
	for attempt in 12:
		var candidate: Array = [pick(difficulty), pick(difficulty), pick(difficulty)]
		var ok := true
		for s in candidate:
			if not BoardLogic.fits_anywhere(occ, s):
				ok = false
				break
		if not ok:
			continue
		if not BoardLogic.solvable(occ, sticky, candidate, [6000]):
			continue
		var diff := 0.0
		var groups := {}
		var repeats := 0
		for s in candidate:
			diff += s["d"] / 3.0
			groups[s["group"]] = true
			if recent_groups.has(s["group"]):
				repeats += 1
		var clears := 0
		if fill > 0.3:
			for s in candidate:
				clears += BoardLogic.max_clear(occ, s)
		# When the board is crowded, favour "rescue" trays that can clear lines.
		var sc := -absf(diff - difficulty) * 3.0 + clears * (1.4 if fill > 0.5 else 0.25)
		sc += -repeats * 0.35 + groups.size() * 0.2 + rng.randf() * 0.3
		if sc > best_score:
			best_score = sc
			best = candidate
	if best.is_empty():
		best = constructive(occ, sticky)
	recent_groups = []
	for s in best:
		recent_groups.append(s["group"])
	return best


## Fallback: builds the tray piece by piece on a simulated board, so it is playable by construction.
func constructive(occ: PackedByteArray, sticky: PackedByteArray) -> Array:
	var sim := occ.duplicate()
	var by_size := Shapes.all.duplicate()
	by_size.sort_custom(func(a, b): return a["cells"].size() < b["cells"].size())
	var out: Array = []
	for k in 3:
		var options: Array = []
		for cand in by_size:
			if BoardLogic.fits_anywhere(sim, cand):
				options.append(cand)
		var s: Dictionary = Shapes.all[0]
		if not options.is_empty():
			s = options[rng.randi_range(0, mini(options.size(), 8) - 1)]
		out.append(s)
		var placed := false
		for y in BoardLogic.N - int(s["h"]) + 1:
			if placed:
				break
			for x in BoardLogic.N - int(s["w"]) + 1:
				if BoardLogic.fits(sim, s, x, y):
					sim = BoardLogic.sim_place(sim, sticky, s, x, y)
					placed = true
					break
	return out
