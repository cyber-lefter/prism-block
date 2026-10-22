class_name Levels
extends RefCounted
## 50 adventure levels generated from fixed seeds, so every player gets the same levels.
## New mechanics: ice from level 6, stones from 11, bomb pieces from 16, thick ice from 30.

const COUNT := 50

## Island regions on the Adventure map, bottom to top. Each opens once the previous one is finished.
## Regions without levels yet show as locked "?" areas. To ship one: give it a name and a level
## range that continues the numbering, and raise COUNT.
const REGIONS := [
	{"name": "Prism Meadows", "first": 1, "last": 50, "land": "6fd16b", "pos": Vector2(0.38, 0.76)},
	{"name": "", "first": 0, "last": 0, "land": "e9f4ff", "pos": Vector2(0.70, 0.66)},
	{"name": "", "first": 0, "last": 0, "land": "f2c46b", "pos": Vector2(0.28, 0.52)},
	{"name": "", "first": 0, "last": 0, "land": "2f9e6a", "pos": Vector2(0.70, 0.38)},
	{"name": "", "first": 0, "last": 0, "land": "b48cff", "pos": Vector2(0.32, 0.24)},
	{"name": "", "first": 0, "last": 0, "land": "8a5a4a", "pos": Vector2(0.58, 0.10)},
]


## Things to spend stars on, sitting on the treasure islet below the island ("pos").
## Stars earned anywhere on the island add to one balance. Chests can be bought again
## and again with random contents; the dusk look is bought once and then toggles.
const CHESTS := [
	{"id": "small", "cost": 50, "pos": Vector2(0.40, 1.03)},
	{"id": "big", "cost": 75, "pos": Vector2(0.58, 1.03)},
	{"id": "dusk", "cost": 250, "pos": Vector2(0.76, 1.03)},
]


static func region_ready(r: int) -> bool:
	return int(REGIONS[r]["last"]) > 0


## A region is open when it has levels and every level before it has been beaten.
static func region_open(r: int) -> bool:
	if not region_ready(r):
		return false
	return r == 0 or Save.stars(int(REGIONS[r - 1]["last"])) > 0


static func region_of(n: int) -> int:
	for r in REGIONS.size():
		if region_ready(r) and n >= int(REGIONS[r]["first"]) and n <= int(REGIONS[r]["last"]):
			return r
	return 0


static func goal_text(lv: Dictionary) -> String:
	match lv["type"]:
		"score":
			return "Reach %s points" % UI.fmt(int(lv["target"]))
		"lines":
			return "Clear %d lines" % int(lv["target"])
		"gems":
			return "Collect all %d gems" % int(lv["target"])
		"ice":
			return "Break the ice on %d blocks" % int(lv["target"])
	return ""


static func _intro(n: int) -> String:
	match n:
		1:
			return "Fill a row or column to clear it."
		6:
			return "New: Ice. Clear a line through a frozen block to break its ice. The block stays, now unfrozen."
		11:
			return "New: Stone. Stones count toward full lines but never break."
		16:
			return "New: Bombs. A bomb in a cleared line blasts the 3x3 area around it."
		30:
			return "New: Thick ice. It takes two line clears to break."
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
		"base": 0.1 + 0.22 * n / float(COUNT), "par": 0,
		"intro": _intro(n), "cells": [],
	}

	# Symmetric starting pattern, denser toward the bottom.
	var grid := {}
	var fill := 0.1 + 0.14 * minf(1.0, n / 40.0)
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
			# Gentler climb after level 30, where the bot's win rate dropped off.
			lv["target"] = 250 + 38 * mini(n, 30) + 25 * maxi(0, n - 30)
		"lines":
			lv["target"] = 5 + int(n / 5.0)
		"gems":
			var want := mini(3 + int(n / 7.0), blocks.size())
			for i in _pick_spread(grid, blocks, want):
				grid[i]["kind"] = "gem"
			lv["target"] = want
		"ice":
			var want := mini(4 + int(n / 7.0), blocks.size())
			for i in _pick_spread(grid, blocks, want):
				grid[i]["ice"] = 2 if n >= 30 and rng.randf() < 0.3 else 1
			lv["target"] = want

	lv["par"] = par_for(t, int(lv["target"]))

	var cells: Array = []
	for key in grid.keys():
		var c: Dictionary = grid[key]
		cells.append({"i": key, "color": c["color"], "kind": c["kind"], "ice": c["ice"]})
	lv["cells"] = cells
	return lv


## Moves allowed for 3 stars. Tuned from bot play (tests/balance.gd): roughly 80% of the moves
## a simple greedy bot needs, so a careful player can get 3 stars and most players get 2.
static func par_for(type: String, target: int) -> int:
	match type:
		"score":
			return roundi(1.4 * sqrt(target))
		"lines":
			return roundi(12 + 1.5 * target)
		"gems":
			return roundi(20 + 1.6 * target)
		"ice":
			return roundi(10 + 4.0 * target)
	return 20


## Picks goal blocks (gems, ice) that are hard to grab all at once: blocks in the emptiest
## rows and columns first, and no two sharing a row or column while that is possible.
## Otherwise a lucky first piece can finish a level by completing one nearly full line.
static func _pick_spread(grid: Dictionary, blocks: Array, want: int) -> Array:
	var fill := {}
	for line in 16:
		var c := 0
		for j in 8:
			if grid.has(line * 8 + j if line < 8 else j * 8 + (line - 8)):
				c += 1
		fill[line] = c
	var ranked := blocks.duplicate()
	ranked.sort_custom(func(a, b):
		return maxi(fill[a / 8], fill[8 + a % 8]) < maxi(fill[b / 8], fill[8 + b % 8]))
	var out: Array = []
	var rows := {}
	var cols := {}
	for i in ranked:
		if out.size() >= want:
			break
		if not rows.has(i / 8) and not cols.has(i % 8):
			out.append(i)
			rows[i / 8] = true
			cols[i % 8] = true
	for i in ranked:
		if out.size() >= want:
			break
		if not out.has(i):
			out.append(i)
	return out


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
