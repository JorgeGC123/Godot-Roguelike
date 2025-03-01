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
	print("SavedData: ===== INICIO GUARDADO =====")
	print("SavedData: Armas: ", weapons.size(), ", Posiciones: ", inventory_positions.size())
	
	# NO REPARAR POSICIONES AQUÍ - confiamos en las posiciones ya existentes
	print("SavedData: Usando posiciones existentes: ", inventory_positions)
	
	# Convertir armas a formato serializable
	var weapons_array = weapons_to_dict()
	
	# Verificación final de posiciones en el array JSON
	var positions_in_json_ok = true
	for weapon_dict in weapons_array:
		var name = weapon_dict["name"]
		var pos = weapon_dict["inventory_position"]
		if pos < 0:
			positions_in_json_ok = false
			print("SavedData ERROR GRAVE: Posición inválida ", pos, " para '", name, "' en el JSON")
			# IMPORTANTE: NO corregir aquí, solo reportar el error
	
	# Crear diccionario con los datos a guardar
	var save_dict = {
		"num_floor": num_floor,
		"hp": hp,
		"weapons": weapons_array,
		"items": items_to_dict(),
		"equipped_weapon_index": equipped_weapon_index,
		"skin": skin
	}
	
	# Convertir a JSON para verificar antes de guardar
	var json_str = to_json(save_dict)
	print("SavedData: JSON final (primeros 300 caracteres):\n", json_str.substr(0, 300))
	
	# Guardar en archivo
	var save_file = File.new()
	var err = save_file.open(SAVE_FILE, File.WRITE)
	if err != OK:
		push_error("SavedData: Error al abrir el archivo de guardado: " + str(err))
		return
	
	save_file.store_line(json_str)
	save_file.close()
	
	# Verificación final
	if save_file.file_exists(SAVE_FILE):
		print("SavedData: Datos guardados exitosamente")
	else:
		push_error("SavedData: Error al verificar el archivo guardado")
	
	print("SavedData: ===== FIN GUARDADO =====")

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
	
	print("SavedData DEBUG ----- MÉTODO weapons_to_dict() -----")
	print("SavedData DEBUG: Armas en weapons: ", weapons.size())
	print("SavedData DEBUG: Posiciones en inventory_positions: ", inventory_positions)
	
	# Para cada arma que tenemos
	for weapon in weapons:
		var weapon_name = weapon.name
		var position = 0  # Posición por defecto - SIEMPRE usar un valor válido
		
		# Obtener la posición de inventory_positions
		if inventory_positions.has(weapon_name):
			position = inventory_positions[weapon_name]
			print("SavedData DEBUG: Usando posición guardada para '", weapon_name, "': ", position)
		else:
			# Si no tiene posición, asignar una posición automática
			# basada en su índice en el array weapons
			for i in range(weapons.size()):
				if weapons[i].name == weapon_name:
					position = i
					break
			
			# IMPORTANTE: Actualizar inventory_positions con esta posición
			inventory_positions[weapon_name] = position
			
			print("SavedData DEBUG: Asignada posición automática para '", weapon_name, "': ", position)
		
		# Crear el diccionario con la posición del arma
		weapon_dicts.append({
			"name": weapon_name,
			"inventory_position": position
		})
		print("SavedData DEBUG: Añadido al JSON: '", weapon_name, "' en posición ", position)
	
	return weapon_dicts

func dict_to_weapons(weapon_dicts: Array) -> Array:
	var loaded_weapons = []
	var loaded_positions = {}
	
	print("SavedData: ===== CARGANDO ARMAS =====")
	print("SavedData: Armas en JSON: ", weapon_dicts.size())
	
	# DEBUG: Mostrar datos cargados del JSON
	print("SavedData: Datos de posiciones cargados del JSON:")
	for weapon_dict in weapon_dicts:
		print("  - Arma: ", weapon_dict["name"], ", posición: ", weapon_dict["inventory_position"])
	
	# 1. Primero, extraer todas las posiciones del JSON
	for weapon_dict in weapon_dicts:
		var weapon_name = weapon_dict["name"]
		var position = weapon_dict.get("inventory_position", -1)
		
		# Sólo guardar posiciones válidas
		if position >= 0:
			loaded_positions[weapon_name] = position
		else:
			print("SavedData ERROR: Posición inválida para '", weapon_name, "': ", position)
	
	# 2. Luego, crear un mapa por posición para instanciar las armas
	var weapons_by_position = {}
	
	# 3. Instanciar cada arma y asignarla a su posición
	for weapon_dict in weapon_dicts:
		var weapon_name = weapon_dict["name"]
		var position = weapon_dict.get("inventory_position", -1)
		
		# Verificar que la posición sea válida
		if position < 0:
			print("SavedData ERROR: Omitiendo arma '", weapon_name, "' por posición inválida: ", position)
			continue
		
		# Cargar la escena base (sin sufijos numéricos)
		var base_name = weapon_name.rstrip("0123456789")
		var weapon_scene_path = "res://Weapons/" + base_name + ".tscn"
		
		print("SavedData: Cargando arma ", weapon_name, " desde ", weapon_scene_path, " en posición ", position)
		
		# Verificar que la escena existe
		if not ResourceLoader.exists(weapon_scene_path):
			print("SavedData ERROR: No se encuentra la escena ", weapon_scene_path)
			continue
		
		# Instanciar el arma
		var weapon = load(weapon_scene_path).instance()
		
		# Preservar el nombre único original con sus sufijos
		weapon.name = weapon_name
		
		# Guardar en el mapa por posición
		weapons_by_position[position] = weapon
		print("SavedData: Arma ", weapon_name, " asignada a posición ", position)
	
	# 4. Establecer las posiciones, crucial para mantenerlas entre sesiones
	inventory_positions = loaded_positions.duplicate()
	print("SavedData: Posiciones cargadas: ", inventory_positions)
	
	# 5. Ordenar armas por posición para la lista weapons
	var positions = weapons_by_position.keys()
	positions.sort()
	
	# 6. Añadir las armas al array final en orden de posición
	for pos in positions:
		loaded_weapons.append(weapons_by_position[pos])
		var weapon_name = weapons_by_position[pos].name
		print("SavedData: Añadida arma ", weapon_name, " a loaded_weapons (pos ", pos, ")")
	
	# 7. Verificar el resultado final
	print("SavedData: Carga completada. Armas cargadas: ", loaded_weapons.size())
	print("SavedData: Inventory positions: ", inventory_positions)
	print("SavedData: ===== FIN CARGA ARMAS =====")
	
	return loaded_weapons

func update_weapon_position(weapon_name: String, position: int) -> void:
	print("SavedData: Actualizando posición del arma '", weapon_name, "' a ", position)
	
	# Guardamos el nombre exacto del arma con sufijos para mantener la referencia correcta
	inventory_positions[weapon_name] = position
	
	# Mostrar el estado actual de las posiciones
	print("SavedData: Posiciones actualizadas: ", inventory_positions)

# Método para actualizar la posición de cualquier item en el inventario
func update_item_position(item_name: String, position: int) -> void:
	print("SavedData: Actualizando posición del item '", item_name, "' a ", position)
	
	# Guardamos el nombre exacto del item con sufijos para mantener la referencia correcta
	inventory_positions[item_name] = position
	
	# Mostrar el estado actual de las posiciones
	print("SavedData: Posiciones actualizadas: ", inventory_positions)

func items_to_dict() -> Array:
	var item_dicts = []
	print("SavedData: Serializando ", items.size(), " consumibles")
	
	for item in items:
		if not item or not is_instance_valid(item):
			continue
		
		# Obtener la posición del item si existe
		var position = -1
		if inventory_positions.has(item.name):
			position = inventory_positions[item.name]
			print("SavedData: Usando posición guardada para consumible '", item.name, "': ", position)
		
		# Obtener la escena base sin sufijos numéricos
		var base_name = "HealthPotion"  # Valor por defecto
		if item.name:
			base_name = item.name.rstrip("0123456789")
		
		var item_data = {
			"name": item.name,
			"type": "consumable",
			"scene_path": "res://Items/" + base_name + ".tscn",
			"heal_amount": 1,  # Valor por defecto para pociones
			"inventory_position": position  # Incluir la posición en el JSON
		}
		
		print("SavedData: Serializando consumible: ", item.name, ", escena: ", item_data.scene_path, ", posición: ", position)
		item_dicts.append(item_data)
	
	return item_dicts

func dict_to_items(item_dicts: Array) -> Array:
	var loaded_items = []
	var loaded_positions = {}
	
	print("SavedData: ===== CARGANDO CONSUMIBLES =====")
	print("SavedData: Consumibles en JSON: ", item_dicts.size())
	
	# DEBUG: Mostrar datos cargados del JSON
	for item_dict in item_dicts:
		var item_name = item_dict.get("name", "UnknownItem")
		var position = item_dict.get("inventory_position", -1)
		print("SavedData: Consumible cargado: ", item_name, ", posición: ", position)
		
		# Si el item tiene una posición válida, guardarla
		if position >= 0:
			loaded_positions[item_name] = position
	
	# Crear consumibles a partir de los datos del JSON
	for item_dict in item_dicts:
		var item_name = item_dict.get("name", "UnknownItem")
		var scene_path = item_dict.get("scene_path", "")
		var position = item_dict.get("inventory_position", -1)
		
		# Si no se especificó una ruta de escena, intentar construirla
		if scene_path.empty():
			var base_name = "HealthPotion"  # Valor por defecto
			if item_name:
				base_name = item_name.rstrip("0123456789")
			scene_path = "res://Items/" + base_name + ".tscn"
		
		print("SavedData: Cargando consumible ", item_name, " desde ", scene_path, " en posición ", position)
		
		# Verificar que la escena existe
		if ResourceLoader.exists(scene_path):
			var item_instance = load(scene_path).instance()
			item_instance.name = item_name
			
			# Configurar propiedades adicionales
			if item_dict.has("heal_amount") and item_instance.has_method("set"):
				item_instance.set("heal_amount", item_dict["heal_amount"])
			
			loaded_items.append(item_instance)
			print("SavedData: Consumible cargado exitosamente: ", item_instance.name)
		else:
			print("SavedData ERROR: No se encuentra la escena del consumible: ", scene_path)
	
	# Añadir las nuevas posiciones cargadas a inventory_positions
	for item_name in loaded_positions.keys():
		inventory_positions[item_name] = loaded_positions[item_name]
	
	print("SavedData: Consumibles cargados: ", loaded_items.size())
	print("SavedData: Posiciones actualizadas: ", inventory_positions)
	print("SavedData: ===== FIN CARGA CONSUMIBLES =====")
	
	return loaded_items
