extends Node

const SAVE_FILE = "user://save_data.json"

var num_floor: int = 0
var hp: int = 4
var weapons: Array = []
var items: Array = []
var equipped_weapon_index: int = 0
var skin: int = 1
var inventory_positions = {}

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
	if weapons.has(item):
		weapons.erase(item)
		if inventory_positions.has(item.name):
			inventory_positions.erase(item.name)
		save_data()
	elif items.has(item):
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
	
	print("SavedData: weapons_to_dict(): inventory_positions = ", inventory_positions)
	
	for weapon in weapons:
		# Ya no eliminamos sufijos numéricos para permitir múltiples armas del mismo tipo
		# var base_name = weapon.name.rstrip("0123456789")
		var weapon_name = weapon.name
		var position = inventory_positions.get(weapon_name, 0)
		
		print("SavedData: Saving weapon ", weapon.name, " at position ", position)
		
		weapon_dicts.append({
			"name": weapon_name,
			"inventory_position": position
		})
	return weapon_dicts

func dict_to_weapons(weapon_dicts: Array) -> Array:
	var loaded_weapons = []
	inventory_positions.clear()
	
	print("SavedData: Loading weapons from dict, count: ", weapon_dicts.size())
	
	for weapon_dict in weapon_dicts:
		var weapon_name = weapon_dict["name"]
		
		# Cargar la escena base sin sufijos numéricos
		var weapon_scene_name = weapon_name.rstrip("0123456789")
		var weapon = load("res://Weapons/" + weapon_scene_name + ".tscn").instance()
		
		# Preservar el nombre único original con sus sufijos
		weapon.name = weapon_name
		
		if weapon_dict.has("inventory_position"):
			var position = weapon_dict["inventory_position"]
			inventory_positions[weapon_name] = position
			print("SavedData: Loaded weapon ", weapon_name, " with position ", position)
		
		loaded_weapons.append(weapon)
	
	print("SavedData: Final inventory_positions: ", inventory_positions)
	return loaded_weapons

func update_weapon_position(weapon_name: String, position: int) -> void:
	print("SavedData: Updating position for weapon ", weapon_name, " to ", position)
	
	# Ya no eliminamos sufijos numéricos para permitir múltiples armas del mismo tipo
	# weapon_name = weapon_name.rstrip("0123456789")
	
	inventory_positions[weapon_name] = position
	print("SavedData: Current inventory positions: ", inventory_positions)
	save_data()

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
