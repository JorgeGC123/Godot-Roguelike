extends Node

# Señales
signal inventory_created(inventory_id, inventory)
signal inventory_deleted(inventory_id)
signal active_inventory_changed(old_inventory_id, new_inventory_id)

# Constantes
const PLAYER_INVENTORY = "player_inventory"

# Diccionario de inventarios administrados
var inventories = {}
var active_inventory_id = ""

# Referencias a nodos
var player_ref: WeakRef = null

# Referencia a SavedData para compatibilidad
var saved_data = null

func _ready():
	# Hacer una referencia a SavedData para compatibilidad
	if has_node("/root/SavedData"):
		saved_data = get_node("/root/SavedData")
	
	# Crear el inventario del jugador por defecto
	create_inventory(PLAYER_INVENTORY, 25)
	set_active_inventory(PLAYER_INVENTORY)
	
	# Importar cualquier arma existente
	call_deferred("import_from_saved_data")
	
	# Conectar señales para sincronización
	call_deferred("_connect_inventory_signals")

# Crear un nuevo inventario
func create_inventory(id: String, capacity: int) -> InventoryModel:
	if inventories.has(id):
		push_warning("Inventory already exists with ID: " + id)
		return inventories[id]
	
	var new_inventory = InventoryModel.new(capacity)
	inventories[id] = new_inventory
	emit_signal("inventory_created", id, new_inventory)
	return new_inventory

# Eliminar un inventario
func delete_inventory(id: String) -> bool:
	if not inventories.has(id):
		return false
	
	inventories.erase(id)
	emit_signal("inventory_deleted", id)
	
	# Si el inventario eliminado era el activo, limpiar referencia
	if active_inventory_id == id:
		active_inventory_id = ""
	
	return true

# Obtener un inventario por ID
func get_inventory(id: String) -> InventoryModel:
	return inventories.get(id)

# Establecer el inventario activo
func set_active_inventory(id: String) -> bool:
	if not inventories.has(id):
		return false
	
	var old_id = active_inventory_id
	active_inventory_id = id
	emit_signal("active_inventory_changed", old_id, active_inventory_id)
	return true

# Obtener el inventario activo
func get_active_inventory() -> InventoryModel:
	if active_inventory_id == "":
		return null
	return inventories.get(active_inventory_id)

# Referencia al jugador
func set_player(player: Node):
	player_ref = weakref(player)

func get_player():
	if player_ref and player_ref.get_ref():
		return player_ref.get_ref()
	return null

# Métodos para agregar/quitar items al inventario activo
func add_item_to_active(item: Item, slot_index: int = -1) -> bool:
	var inventory = get_active_inventory()
	if not inventory:
		return false
	return inventory.add_item(item, slot_index)

func remove_item_from_active(slot_index: int) -> Item:
	var inventory = get_active_inventory()
	if not inventory:
		return null
	return inventory.remove_item(slot_index)

# Métodos para compatibilidad con SavedData
# Métodos para compatibilidad con SavedData
func import_from_saved_data():
	if not saved_data:
		push_warning("SavedData not found, cannot import")
		return
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		push_warning("Player inventory not found")
		return
	
	print("InventoryManager: Importing weapons from SavedData, count: ", saved_data.weapons.size())
	
	# Primera pasada: crear un mapa de posición -> arma
	var position_weapon_map = {}
	
	for i in range(saved_data.weapons.size()):
		var weapon_node = saved_data.weapons[i]
		var base_name = weapon_node.name.rstrip("0123456789")
		var position = saved_data.inventory_positions.get(base_name, i)
		position_weapon_map[position] = weapon_node
		
		print("InventoryManager: Mapped weapon ", base_name, " to position ", position)
	
	# Segunda pasada: añadir armas en el orden correcto según posiciones
	var sorted_positions = position_weapon_map.keys()
	sorted_positions.sort()
	
	for position in sorted_positions:
		var weapon_node = position_weapon_map[position]
		var weapon_item = ItemFactory.create_item_from_node(weapon_node)
		
		if weapon_item:
			print("InventoryManager: Adding ", weapon_item.name, " to position ", position)
			player_inventory.add_item(weapon_item, position)
	
	print("InventoryManager: Import from SavedData complete")

func export_to_saved_data():
	if not saved_data:
		push_warning("SavedData not found, cannot export")
		return
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		push_warning("Player inventory not found")
		return
	
	# Limpiar datos actuales
	saved_data.weapons = []
	saved_data.inventory_positions = {}
	
	# Exportar armas
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item and item.item_type == "weapon":
			# Instanciar arma desde la escena
			if item.weapon_scene:
				var weapon_instance = item.weapon_scene.instance()
				
				# Configurar estadísticas
				if weapon_instance.has_node("Node2D/Sprite/Hitbox"):
					weapon_instance.get_node("Node2D/Sprite/Hitbox").damage = item.damage
				
				# Guardar en SavedData
				saved_data.weapons.append(weapon_instance)
				saved_data.inventory_positions[weapon_instance.name] = i
	
	# Guardar datos
	saved_data.save_data()

# Guardar todos los inventarios
func save_all_inventories():
	export_to_saved_data()  # Para retrocompatibilidad
	
	# Aquí puedes implementar un sistema de guardado más avanzado
	# para todos los inventarios si lo necesitas


func remove_item_by_name_from_active(item_name: String) -> Item:
	var inventory = get_active_inventory()
	if not inventory:
		return null
		
	# Buscar item por nombre
	for i in range(inventory.capacity):
		var item = inventory.get_item(i)
		if item and item.name == item_name:
			return inventory.remove_item(i)
	
	return null


# Funciones de sincronización entre sistemas
func _connect_inventory_signals():
	# Conectar señales para sincronizar con SavedData
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if player_inventory:
		# Conectar señal de swap
		if not player_inventory.is_connected("items_swapped", self, "_on_inventory_items_swapped"):
			player_inventory.connect("items_swapped", self, "_on_inventory_items_swapped")
		
		print("InventoryManager: Connected to inventory signals")

# Manejar intercambio de items
func _on_inventory_items_swapped(from_index: int, to_index: int):
	if not saved_data:
		return
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		return
		
	# Obtener los items involucrados
	var from_item = player_inventory.get_item(from_index)
	var to_item = player_inventory.get_item(to_index)
	
	# Actualizar posiciones en SavedData
	if from_item:
		# Normalizar nombre del arma - eliminar cualquier sufijo numérico
		var normalized_name = from_item.name.rstrip("0123456789")
		saved_data.update_weapon_position(normalized_name, to_index)
		print("InventoryManager: Updated position for ", normalized_name, " to ", to_index)
	
	if to_item:
		# Normalizar nombre del arma - eliminar cualquier sufijo numérico
		var normalized_name = to_item.name.rstrip("0123456789")
		saved_data.update_weapon_position(normalized_name, from_index)
		print("InventoryManager: Updated position for ", normalized_name, " to ", from_index)
	
	# Guardar los cambios
	saved_data.save_data()
