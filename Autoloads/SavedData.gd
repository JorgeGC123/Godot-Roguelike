extends Node

const SAVE_FILE = "user://save_data.json"

var num_floor: int = 0
var hp: int = 4
var weapons: Array = []
var items: Array = []
var equipped_weapon_index: int = 0
var skin: int = 1

func _ready():
	load_data()

func reset_data() -> void:
	num_floor = 0
	hp = 4
	weapons = []
	items = []
	equipped_weapon_index = 0
	#skin = 1
	save_data()

func add_item(item) -> void:
	if not items.has(item):
		items.append(item)
		save_data()

func remove_item(item) -> void:
	if items.has(item):
		items.erase(item)
		save_data()

func save_data() -> void:
	var save_dict = {
		"num_floor": num_floor,
		"hp": hp,
		"weapons": weapons_to_dict(),
		"items": items_to_dict(),
		"equipped_weapon_index": equipped_weapon_index,
		"skin": skin
	}
	var save_file = File.new()
	save_file.open(SAVE_FILE, File.WRITE)
	save_file.store_line(to_json(save_dict))
	save_file.close()

func load_data() -> void:
	var save_file = File.new()
	if not save_file.file_exists(SAVE_FILE):
		reset_data()
		return
	
	save_file.open(SAVE_FILE, File.READ)
	var content = save_file.get_as_text()
	save_file.close()
	
	# Comprueba si el archivo está vacío
	if content.strip_edges() == "":
		print("El archivo de guardado está vacío. Reseteando datos.")
		reset_data()
		return
	
	var save_dict = parse_json(content)
	if save_dict == null:
		print("Error al parsear el archivo de guardado. Reseteando datos.")
		reset_data()
		return
	
	num_floor = save_dict.get("num_floor", 0)
	hp = save_dict.get("hp", 4)
	weapons = dict_to_weapons(save_dict.get("weapons", []))
	items = dict_to_items(save_dict.get("items", []))
	equipped_weapon_index = save_dict.get("equipped_weapon_index", 0)
	skin = save_dict.get("skin", 1)

func weapons_to_dict() -> Array:
	var weapon_dicts = []
	
	for weapon in weapons:
		weapon_dicts.append({
			"name": weapon.name.rstrip("0123456789"),
			#"damage": weapon.damage,
			# Añade aquí otras propiedades relevantes de las armas
		})
	return weapon_dicts

func dict_to_weapons(weapon_dicts: Array) -> Array:
	var loaded_weapons = []
	for weapon_dict in weapon_dicts:
		var weapon = load("res://Weapons/" + weapon_dict["name"] + ".tscn").instance()
		weapon.name = weapon_dict["name"]
		#weapon.damage = weapon_dict["damage"]
		# Configura aquí otras propiedades relevantes de las armas
		loaded_weapons.append(weapon)
	return loaded_weapons

func items_to_dict() -> Array:
	var item_dicts = []
	for item in items:
		item_dicts.append({
			"name": item.name,
			"type": item.get_class(),
			# Añade aquí otras propiedades relevantes de los items
		})
	return item_dicts

func dict_to_items(item_dicts: Array) -> Array:
	var loaded_items = []
	for item_dict in item_dicts:
		var item = load("res://Items/" + item_dict["name"] + ".tscn").instance()
		item.name = item_dict["name"]
		# Configura aquí otras propiedades relevantes de los items
		loaded_items.append(item)
	return loaded_items
