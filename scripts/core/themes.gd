class_name Themes
extends RefCounted
## Board and block color themes. Prices are in coins.

const LIST := [
	# Jewel tones on a deep, low-saturation board: the blocks carry all the color.
	{"id": "midnight", "name": "Midnight", "price": 0, "top": "2b1d72", "bottom": "0e0b29", "board": "0b0a22", "slot": "18163f",
		"blocks": ["ff3d68", "ff8a1f", "ffcf1a", "22e07a", "1ec8ff", "3f6dff", "9d4dff", "ff45c4"]},
	{"id": "sunset", "name": "Sunset", "price": 300, "top": "ff7a59", "bottom": "3b1449", "board": "2a0f33", "slot": "45204f",
		"blocks": ["ff3f5e", "ff8a3d", "ffc94a", "f9f871", "ff6fb5", "c66bff", "7e5bff", "ff9e9e"]},
	{"id": "ocean", "name": "Deep Ocean", "price": 400, "top": "0e6e8c", "bottom": "06213a", "board": "04182b", "slot": "0c2d47",
		"blocks": ["30e3ca", "11cbd7", "4fa3ff", "3d6bff", "8f7bff", "f8f3d4", "ffd166", "ff7b9c"]},
	{"id": "candy", "name": "Candy Pop", "price": 500, "top": "ffb3d9", "bottom": "7a4bc2", "board": "4a2a7d", "slot": "5d3a94",
		"blocks": ["ff6b9a", "ffa64d", "ffe066", "7ee081", "6ed3ff", "a38bff", "ff8ae2", "f4f0ff"]},
	{"id": "neon", "name": "Neon Night", "price": 800, "top": "1a0033", "bottom": "000000", "board": "07000f", "slot": "160a26",
		"blocks": ["ff2e88", "ff9500", "fff200", "39ff14", "00f0ff", "2e6bff", "b000ff", "ff00d4"]},
]


static func get_theme(id: String) -> Dictionary:
	var raw: Dictionary = LIST[0]
	for t in LIST:
		if t["id"] == id:
			raw = t
	var blocks: Array = []
	for h in raw["blocks"]:
		blocks.append(Color(h))
	return {
		"id": raw["id"], "name": raw["name"], "price": raw["price"],
		"top": Color(raw["top"]), "bottom": Color(raw["bottom"]),
		"board": Color(raw["board"]), "slot": Color(raw["slot"]),
		"blocks": blocks,
	}
