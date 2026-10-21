class_name Shapes
extends RefCounted
## Piece catalogue: every base shape with all of its distinct rotations.

# [rows, difficulty 0..1]
const BASE := [
	[["#"], 0.05],
	[["##"], 0.1],
	[["###"], 0.25],
	[["####"], 0.45],
	[["#####"], 0.7],
	[["##", "##"], 0.3],
	[["##", "#."], 0.22],
	[["#.", "#.", "##"], 0.5],
	[[".#", ".#", "##"], 0.5],
	[["###", ".#."], 0.5],
	[[".##", "##."], 0.62],
	[["##.", ".##"], 0.62],
	[["##", "##", "##"], 0.66],
	[["#..", "#..", "###"], 0.8],
	[["###", "###", "###"], 0.9],
]

static var all: Array = []
static var _by_key: Dictionary = {}


static func init() -> void:
	if not all.is_empty():
		return
	for gi in BASE.size():
		var rows: Array = BASE[gi][0]
		var d: float = BASE[gi][1]
		var cells: Array = []
		for y in rows.size():
			var row: String = rows[y]
			for x in row.length():
				if row[x] == "#":
					cells.append(Vector2i(x, y))
		cells = normalize(cells)
		var rots: Array = []
		var seen := {}
		for i in 4:
			var k := key(cells)
			if not seen.has(k):
				seen[k] = true
				rots.append(cells)
			cells = normalize(rotate_raw(cells))
		for cs in rots:
			var w := 0
			var h := 0
			for c in cs:
				w = maxi(w, c.x + 1)
				h = maxi(h, c.y + 1)
			var weight := (0.6 if gi == 0 else 1.0) / rots.size()
			var shape := {"id": all.size(), "group": gi, "cells": cs, "w": w, "h": h, "d": d, "gw": weight}
			all.append(shape)
			_by_key[key(cs)] = shape


## Rotates 90 degrees clockwise without normalizing, so cell order is kept.
static func rotate_raw(cells: Array) -> Array:
	var out: Array = []
	for c in cells:
		out.append(Vector2i(-c.y, c.x))
	return out


static func min_corner(cells: Array) -> Vector2i:
	var mx := 999
	var my := 999
	for c in cells:
		mx = mini(mx, c.x)
		my = mini(my, c.y)
	return Vector2i(mx, my)


static func normalize(cells: Array) -> Array:
	var m := min_corner(cells)
	var out: Array = []
	for c in cells:
		out.append(c - m)
	out.sort_custom(func(a, b): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


static func key(cells: Array) -> String:
	var parts := PackedStringArray()
	for c in cells:
		parts.append("%d,%d" % [c.x, c.y])
	return ";".join(parts)


## Finds the catalogue shape with these cells (any offset). Empty if none.
static func by_cells(cells: Array) -> Dictionary:
	return _by_key.get(key(normalize(cells)), {})
