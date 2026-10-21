class_name BoardLogic
extends RefCounted
## Pure board rules on an 8x8 occupancy array (1 = filled). Used by the game and the dealer.
## "sticky" marks cells that survive a line clear in simulations (stones and iced blocks).

const N := 8


static func fits(occ: PackedByteArray, shape: Dictionary, gx: int, gy: int) -> bool:
	for c in shape["cells"]:
		var x: int = gx + c.x
		var y: int = gy + c.y
		if x < 0 or y < 0 or x >= N or y >= N:
			return false
		if occ[y * N + x] != 0:
			return false
	return true


static func fits_anywhere(occ: PackedByteArray, shape: Dictionary) -> bool:
	var w: int = shape["w"]
	var h: int = shape["h"]
	for y in N - h + 1:
		for x in N - w + 1:
			if fits(occ, shape, x, y):
				return true
	return false


static func full_lines(occ: PackedByteArray) -> Dictionary:
	var rows: Array = []
	var cols: Array = []
	for y in N:
		var full := true
		for x in N:
			if occ[y * N + x] == 0:
				full = false
				break
		if full:
			rows.append(y)
	for x in N:
		var full := true
		for y in N:
			if occ[y * N + x] == 0:
				full = false
				break
		if full:
			cols.append(x)
	return {"rows": rows, "cols": cols}


static func fill_ratio(occ: PackedByteArray) -> float:
	var n := 0
	for v in occ:
		if v != 0:
			n += 1
	return n / float(N * N)


## Returns a new occupancy array after placing the shape and clearing full lines.
static func sim_place(occ: PackedByteArray, sticky: PackedByteArray, shape: Dictionary, gx: int, gy: int) -> PackedByteArray:
	var g := occ.duplicate()
	for c in shape["cells"]:
		g[(gy + c.y) * N + gx + c.x] = 1
	var f := full_lines(g)
	for y in f["rows"]:
		for x in N:
			var i: int = y * N + x
			if sticky[i] == 0:
				g[i] = 0
	for x in f["cols"]:
		for y in N:
			var i: int = y * N + x
			if sticky[i] == 0:
				g[i] = 0
	return g


## Most lines the shape can complete with a single placement.
static func max_clear(occ: PackedByteArray, shape: Dictionary) -> int:
	var best := 0
	var w: int = shape["w"]
	var h: int = shape["h"]
	for y in N - h + 1:
		for x in N - w + 1:
			if not fits(occ, shape, x, y):
				continue
			var g := occ.duplicate()
			for c in shape["cells"]:
				g[(y + c.y) * N + x + c.x] = 1
			var f := full_lines(g)
			best = maxi(best, f["rows"].size() + f["cols"].size())
	return best


## True if some order and placement fits every shape. budget[0] caps the search.
static func solvable(occ: PackedByteArray, sticky: PackedByteArray, shapes: Array, budget: Array) -> bool:
	if shapes.is_empty():
		return true
	var tried := {}
	for i in shapes.size():
		var s: Dictionary = shapes[i]
		if tried.has(s["id"]):
			continue
		tried[s["id"]] = true
		var rest := shapes.duplicate()
		rest.remove_at(i)
		var w: int = s["w"]
		var h: int = s["h"]
		for y in N - h + 1:
			for x in N - w + 1:
				budget[0] -= 1
				if budget[0] < 0:
					return false
				if not fits(occ, s, x, y):
					continue
				if rest.is_empty():
					return true
				if solvable(sim_place(occ, sticky, s, x, y), sticky, rest, budget):
					return true
	return false
