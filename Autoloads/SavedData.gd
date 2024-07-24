extends Node

var num_floor: int = 0

var hp: int = 4
var weapons: Array = []
var items: Array = []
var equipped_weapon_index: int = 0
var skin: int = 1

func reset_data() -> void:
	num_floor = 0
	
	hp = 4
	weapons = []
	items = []
	equipped_weapon_index = 0

func add_item(item) -> void:
	if not items.has(item):
		items.append(item)
