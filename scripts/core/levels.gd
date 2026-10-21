class_name Levels
extends RefCounted
## 50 adventure levels generated from fixed seeds, so every player gets the same levels.
## New mechanics: ice from level 6, stones from 11, bomb pieces from 16, thick ice from 30.

const COUNT := 50


static func goal_text(lv: Dictionary) -> String:
	match lv["type"]:
		"score":
			return "Reach %s points" % UI.fmt(int(lv["target"]))
		"lines":
			return "Clear %d lines" % int(lv["target"])
		"gems":
			return "Collect all %d gems" % int(lv["target"])
		"ice":
			return "Break all %d ice blocks" % int(lv["target"])
	return ""


static func _intro(n: int) -> String:
	match n:
		1:
			return "Fill a row or column to clear it."
		6:
			return "New: Ice. A frozen block needs its line cleared one extra time."
		11:
			return "New: Stone. Stones count toward full lines but never break."
		16:
			return "New: Bombs. A bomb in a cleared line blasts the 3x3 area around it."
		30:
			return "New: Thick ice needs two extra clears."
	return ""


static func get_level(n: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 7919 + 1013
	var types: Array = ["score", "lines", "gems"]
	if n >= 6:
		types = ["score", "lines", "gems", "ice"]
	var t: String = types[(n - 1) % types.size()]
	if n == 6:
		t = "ice"
	var lv := {
		"n": n, "type": t, "target": 0, "bombs": n >= 16,
		"base": 0.1 + 0.3 * n / float(COUNT), "par": 12 + int(n * 0.35),
		"intro": _intro(n), "cells": [],
	}

	# Symmetric starting pattern, denser toward the bottom.
	var grid := {}
	var fill := 0.1 + 0.16 * minf(1.0, n / 40.0)
	if t == "score":
		fill *= 0.6
	elif t == "gems" or t == "ice":
		fill = maxf(fill, 0.2)
	for y in 8:
		for x in 4:
			if rng.randf() < fill * (0.6 + 0.8 * y / 7.0):
				var ci := rng.randi_range(0, 7)
				grid[y * 8 + x] = {"color": ci, "kind": "block", "ice": 0}
				grid[y * 8 + 7 - x] = {"color": ci, "kind": "block", "ice": 0}

	if n >= 11:
		var stones := 1 + int(n / 20.0)
		for k in stones:
			for tries in 20:
				var i := rng.randi_range(0, 63)
				if not grid.has(i):
					grid[i] = {"color": 0, "kind": "stone", "ice": 0}
					break

	_break_full_lines(grid, rng)

	var blocks: Array = []
	for key in grid.keys():
		if grid[key]["kind"] == "block":
			blocks.append(key)
	_shuffle(blocks, rng)
	match t:
		"score":
			lv["target"] = 250 + n * 45
		"lines":
			lv["target"] = 5 + int(n / 4.0)
		"gems":
			var want := mini(3 + int(n / 6.0), blocks.size())
			for k in want:
				grid[blocks[k]]["kind"] = "gem"
			lv["target"] = want
		"ice":
			var want := mini(4 + int(n / 5.0), blocks.size())
			for k in want:
				grid[blocks[k]]["ice"] = 2 if n >= 30 and rng.randf() < 0.4 else 1
			lv["target"] = want

	var cells: Array = []
	for key in grid.keys():
		var c: Dictionary = grid[key]
		cells.append({"i": key, "color": c["color"], "kind": c["kind"], "ice": c["ice"]})
	lv["cells"] = cells
	return lv


## No line may start full. Removes one plain block from any full row or column.
static func _break_full_lines(grid: Dictionary, rng: RandomNumberGenerator) -> void:
	for pass_n in 2:
		for line in 16:
			var idx: Array = []
			for j in 8:
				idx.append(line * 8 + j if line < 8 else j * 8 + (line - 8))
			var full := true
			for i in idx:
				if not grid.has(i):
					full = false
					break
			if not full:
				continue
			var plain: Array = []
			for i in idx:
				if grid[i]["kind"] == "block":
					plain.append(i)
			if not plain.is_empty():
				grid.erase(plain[rng.randi_range(0, plain.size() - 1)])


static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
