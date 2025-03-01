extends Reference

# Pruebas para verificar el ciclo completo de añadir items, guardarlos y cargarlos
# Utilizamos un archivo alternativo para no interferir con los datos del juego

const TEST_SAVE_FILE = "user://save_data2.json"
const ORIGINAL_SAVE_FILE = "user://save_data.json"

var original_save_path

# Mock de SavedData que utiliza un archivo de guardado diferente para las pruebas
class MockSavedData:
	signal saved
	signal loaded
	
	var num_floor: int = 0
	var hp: int = 4
	var weapons: Array = []
	var items: Array = []
	var equipped_weapon_index: int = 0
	var skin: int = 1
	var inventory_positions = {}
	var save_path: String
	
	func _init(path: String = TEST_SAVE_FILE):
		save_path = path
	
	func reset_data() -> void:
		num_floor = 0
		hp = 4
		weapons = []
		items = []
		equipped_weapon_index = 0
		skin = 1
		inventory_positions = {}
		save_data()
	
	func add_item(item) -> void:
		if not items.has(item):
			items.append(item)
			save_data()
	
	func add_weapon(weapon) -> void:
		if not weapons.has(weapon):
			weapons.append(weapon)
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
		print("MockSavedData: Guardando datos en ", save_path)
		
		# Convertir armas a formato serializable
		var weapons_array = []
		for weapon in weapons:
			var position = 0
			if inventory_positions.has(weapon.name):
				position = inventory_positions[weapon.name]
			else:
				for i in range(weapons.size()):
					if weapons[i].name == weapon.name:
						position = i
						break
				inventory_positions[weapon.name] = position
			
			weapons_array.append({
				"name": weapon.name,
				"inventory_position": position
			})
		
		# Convertir consumibles a formato serializable
		var items_array = []
		for item in items:
			var position = -1
			if inventory_positions.has(item.name):
				position = inventory_positions[item.name]
			
			var base_name = "HealthPotion"
			if item.name:
				base_name = item.name.rstrip("0123456789")
			
			items_array.append({
				"name": item.name,
				"type": "consumable",
				"scene_path": "res://Items/" + base_name + ".tscn",
				"heal_amount": 1,
				"inventory_position": position
			})
		
		# Crear diccionario con los datos a guardar
		var save_dict = {
			"num_floor": num_floor,
			"hp": hp,
			"weapons": weapons_array,
			"items": items_array,
			"equipped_weapon_index": equipped_weapon_index,
			"skin": skin
		}
		
		# Guardar en archivo
		var save_file = File.new()
		var err = save_file.open(save_path, File.WRITE)
		if err != OK:
			push_error("MockSavedData: Error al abrir el archivo de guardado: " + str(err))
			return
		
		save_file.store_line(to_json(save_dict))
		save_file.close()
		
		emit_signal("saved")
	
	func load_data() -> bool:
		print("MockSavedData: Cargando datos desde ", save_path)
		
		var save_file = File.new()
		if not save_file.file_exists(save_path):
			print("MockSavedData: El archivo de prueba no existe. Inicializando con datos vacíos.")
			reset_data()
			return false
		
		save_file.open(save_path, File.READ)
		var content = save_file.get_as_text()
		save_file.close()
		
		# Comprueba si el archivo está vacío
		if content.strip_edges() == "":
			print("MockSavedData: El archivo de prueba está vacío. Inicializando con datos vacíos.")
			reset_data()
			return false
		
		var save_dict = parse_json(content)
		if save_dict == null:
			print("MockSavedData: Error al parsear el archivo de prueba. Inicializando con datos vacíos.")
			reset_data()
			return false
		
		# Cargar datos básicos
		num_floor = save_dict.get("num_floor", 0)
		hp = save_dict.get("hp", 4)
		equipped_weapon_index = save_dict.get("equipped_weapon_index", 0)
		skin = save_dict.get("skin", 1)
		
		# Cargar posiciones del inventario
		inventory_positions = {}
		
		# Cargar armas
		weapons = []
		for weapon_dict in save_dict.get("weapons", []):
			var weapon_name = weapon_dict["name"]
			var position = weapon_dict.get("inventory_position", 0)
			inventory_positions[weapon_name] = position
			
			# Crear nodo simple para pruebas
			var weapon = Node2D.new()
			weapon.name = weapon_name
			weapons.append(weapon)
		
		# Cargar consumibles
		items = []
		for item_dict in save_dict.get("items", []):
			var item_name = item_dict.get("name", "UnknownItem")
			var position = item_dict.get("inventory_position", -1)
			
			if position >= 0:
				inventory_positions[item_name] = position
			
			# Crear nodo simple para pruebas
			var item = Area2D.new()
			item.name = item_name
			items.append(item)
		
		emit_signal("loaded")
		return true
	
	func update_weapon_position(weapon_name: String, position: int) -> void:
		inventory_positions[weapon_name] = position
	
	func update_item_position(item_name: String, position: int) -> void:
		inventory_positions[item_name] = position

# Preparación de test: Guardar la ruta original y mover a un lado
func setup():
	# Preservar el archivo original si existe
	var file = File.new()
	original_save_path = ""
	
	if file.file_exists(TEST_SAVE_FILE):
		var timestamp = OS.get_unix_time()
		original_save_path = "user://save_data2_backup_" + str(timestamp) + ".json"
		var dir = Directory.new()
		dir.copy(TEST_SAVE_FILE, original_save_path)
		dir.remove(TEST_SAVE_FILE)
	
	# Crear una instancia de MockSavedData para las pruebas
	return MockSavedData.new()

# Limpieza después del test
func teardown(mock_data):
	# Eliminar el archivo de prueba
	var dir = Directory.new()
	if dir.file_exists(TEST_SAVE_FILE):
		dir.remove(TEST_SAVE_FILE)
	
	# Restaurar el archivo original si existe
	if original_save_path != "" and dir.file_exists(original_save_path):
		dir.copy(original_save_path, TEST_SAVE_FILE)
		dir.remove(original_save_path)

# Test para verificar la creación y guardado de un nuevo inventario
func test_create_and_save_inventory():
	var mock_data = setup()
	
	# Crear algunos nodos ficticios para simular armas y consumibles
	var sword = Node2D.new()
	sword.name = "Sword1"
	
	var potion = Area2D.new()
	potion.name = "HealthPotion"
	
	# Asignar posiciones en el inventario
	mock_data.inventory_positions[sword.name] = 3
	mock_data.inventory_positions[potion.name] = 5
	
	# Añadir items al inventario simulado
	mock_data.weapons.append(sword)
	mock_data.items.append(potion)
	
	# Guardar datos
	mock_data.save_data()
	
	# Verificar que el archivo existe
	var file = File.new()
	var file_exists = file.file_exists(TEST_SAVE_FILE)
	
	# Limpiar
	teardown(mock_data)
	
	return file_exists

# Test para verificar carga de datos guardados
func test_load_saved_inventory():
	var mock_data = setup()
	
	# Crear y guardar datos iniciales
	var sword = Node2D.new()
	sword.name = "Sword1"
	mock_data.weapons.append(sword)
	mock_data.inventory_positions[sword.name] = 3
	mock_data.save_data()
	
	# Crear una nueva instancia y cargar los datos
	var new_mock_data = MockSavedData.new()
	new_mock_data.load_data()
	
	# Verificar que los datos se cargaron correctamente
	var has_correct_position = new_mock_data.inventory_positions.has(sword.name) and new_mock_data.inventory_positions[sword.name] == 3
	var has_weapon = new_mock_data.weapons.size() > 0
	
	# Limpiar
	teardown(mock_data)
	
	return has_correct_position and has_weapon

# Test simple que siempre pasa, para verificar que el sistema de tests funciona
func test_basic_pass():
	# Este test solo retorna true sin usar setup/teardown
	return true
