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
func import_from_saved_data():
	if not saved_data:
		push_warning("SavedData not found, cannot import")
		return
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		push_warning("Player inventory not found")
		return
	
	print("InventoryManager: Importing weapons from SavedData, count: ", saved_data.weapons.size())
	print("InventoryManager: Current inventory positions in SavedData: ", saved_data.inventory_positions)
	
	# Primero, limpiar el inventario para evitar conflictos
	for i in range(player_inventory.capacity):
		player_inventory.remove_item(i)
	
	# Crear un mapa directo de arma -> posición usando el diccionario de posiciones guardado
	var weapon_position_map = {}
	
	# Llenar el mapa usando los datos guardados en inventory_positions
	for weapon_name in saved_data.inventory_positions.keys():
		var position = saved_data.inventory_positions[weapon_name]
		print("InventoryManager: Found saved position for ", weapon_name, ": ", position)
		weapon_position_map[weapon_name] = position
	
	# Procesar cada arma y colocarla en su posición guardada
	for i in range(saved_data.weapons.size()):
		var weapon_node = saved_data.weapons[i]
		var weapon_name = weapon_node.name
		
		# Obtener la posición guardada para esta arma específica
		var target_position = saved_data.inventory_positions.get(weapon_name, i)
		print("InventoryManager: Placing ", weapon_name, " at position ", target_position)
		
		# Crear el item para esta arma
		var weapon_item = ItemFactory.create_item_from_node(weapon_node)
		if weapon_item:
			# Intentar colocar en la posición específica guardada
			var success = player_inventory.add_item(weapon_item, target_position)
			
			if success:
				print("InventoryManager: Successfully added ", weapon_item.name, " to position ", target_position)
			else:
				# Si falla (raro dada la limpieza previa), buscar slot alternativo
				var alt_slot = player_inventory.get_first_empty_slot()
				if alt_slot != -1:
					print("InventoryManager: ERROR - Slot ", target_position, " ocupado, usando alternativa: ", alt_slot)
					player_inventory.add_item(weapon_item, alt_slot)
					# Actualizar la posición en SavedData
					saved_data.update_weapon_position(weapon_item.name, alt_slot)
				else:
					print("InventoryManager: ERROR - No se pudo colocar ", weapon_item.name, " - inventario lleno")
	
	# Actualizar la UI si es necesario
	player_inventory.emit_signal("inventory_updated")
	
	print("InventoryManager: Import from SavedData complete")
	print("InventoryManager: Final inventory slots:")
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item:
			print(" - Slot ", i, ": ", item.name)
		else:
			print(" - Slot ", i, ": vacío")
	
	print("InventoryManager: Final inventory positions in SavedData: ", saved_data.inventory_positions)

func export_to_saved_data() -> bool:
	if not saved_data:
		push_warning("SavedData not found, cannot export")
		return false
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		push_warning("Player inventory not found")
		return false
	
	print("InventoryManager: Exporting to SavedData")
	
	# Verificar el estado actual de las armas antes de modificarlas
	var current_weapons_count = saved_data.weapons.size()
	print("InventoryManager: Armas actuales en SavedData: ", current_weapons_count)
	
	# Debugear las posiciones actuales de SavedData
	print("InventoryManager: Posiciones actuales en SavedData: ", saved_data.inventory_positions)
	
	# 1. PRIMERO: verificar qué armas hay en el inventario y donde están exactamente
	var inventory_weapons = []
	var inventory_positions = {}
	
	print("\nINVENTARIO ACTUAL:")
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item:
			print("- Slot ", i, ": ", item.name, " (tipo: ", item.item_type, ")")
			if item.item_type == "weapon":
				inventory_weapons.append(item)
				inventory_positions[item.name] = i
		else:
			print("- Slot ", i, ": vacío")
	
	print("\nARMAS DETECTADAS: ", inventory_weapons.size())
	print("POSICIONES DETECTADAS: ", inventory_positions)
	
	# Si no tenemos armas, mantener el estado actual
	if inventory_weapons.size() == 0 and current_weapons_count > 0:
		print("InventoryManager: ADVERTENCIA - No se detectaron armas en el inventario pero hay ", current_weapons_count, " armas en SavedData")
		print("InventoryManager: Preservando armas existentes")
		return false
	
	# 2. SEGUNDO: crear nuevas instancias de armas basadas en las armas del inventario
	var new_weapons = []
	
	print("\nCREANDO NUEVAS INSTANCIAS:")
	for weapon_item in inventory_weapons:
		print("- Procesando ", weapon_item.name)
		
		# Verificar si tenemos weapon_scene
		if not weapon_item.weapon_scene:
			print("  ERROR: weapon_scene es null para ", weapon_item.name)
			
			# Intento de recuperación: Buscar escena basada en el tipo de arma
			var base_name = weapon_item.name.rstrip("0123456789")
			var possible_path = "res://Weapons/" + base_name + ".tscn"
			print("  Intentando cargar desde: ", possible_path)
			
			if ResourceLoader.exists(possible_path):
				weapon_item.weapon_scene = load(possible_path)
				print("  RECUPERADO: Escena cargada correctamente")
			else:
				print("  FALLO DE RECUPERACIÓN: No se pudo cargar la escena")
				continue
		
		# Instanciar arma desde la escena
		var weapon_instance = weapon_item.weapon_scene.instance()
		
		# Mantener el nombre exacto
		weapon_instance.name = weapon_item.name
		
		# Configurar estadísticas
		if weapon_instance.has_node("Node2D/Sprite/Hitbox"):
			weapon_instance.get_node("Node2D/Sprite/Hitbox").damage = weapon_item.damage
		
		# Añadir a las nuevas armas
		new_weapons.append(weapon_instance)
		print("  AÑADIDA: ", weapon_instance.name, " a new_weapons")
	
	# 3. TERCERO: Actualizar SavedData con las nuevas armas y posiciones
	print("\nACTUALIZANDO SAVEDDATA:")
	print("- Armas creadas: ", new_weapons.size())
	print("- Posiciones detectadas: ", inventory_positions)
	
	# Guardar el equipped_weapon_index actual
	var current_equipped_index = saved_data.equipped_weapon_index
	
	# Actualizar saved_data
	saved_data.weapons = new_weapons
	saved_data.inventory_positions = inventory_positions
	
	# Asegurarse de que el equipped_weapon_index sea válido
	if current_equipped_index >= new_weapons.size():
		print("- Ajustando equipped_weapon_index de ", current_equipped_index, " a 0")
		saved_data.equipped_weapon_index = 0
	
	# Guardar datos
	print("- Guardando cambios...")
	saved_data.save_data()
	
	# Verificar el guardado
	print("\nEXPORTACIÓN COMPLETADA:")
	print("- Armas guardadas: ", saved_data.weapons.size())
	print("- Posiciones guardadas: ", saved_data.inventory_positions)
	
	if saved_data.weapons.size() == 0 and current_weapons_count > 0:
		print("InventoryManager: ERROR GRAVE - Se han perdido las armas durante la exportación!")
		return false
	
	return true

# Guardar todos los inventarios
func save_all_inventories():
	print("InventoryManager: Guardando todos los inventarios...")
	
	# Para retrocompatibilidad exportamos a SavedData
	var success = export_to_saved_data()
	
	# Si la exportación falló, intentar preservar el estado actual
	if not success and saved_data and saved_data.weapons.size() == 0:
		print("InventoryManager: ERROR - La exportación falló y podría haberse perdido el estado")
		# Aquí podrías implementar un mecanismo de recuperación
		
	# Verificar que los datos se guardaron correctamente
	if saved_data:
		verify_saved_data()
		
	print("InventoryManager: Guardado completado.")

# Verificar el estado del guardado
func verify_saved_data() -> bool:
	if not saved_data:
		print("InventoryManager: ERROR - No hay SavedData disponible!")
		return false
	
	print("InventoryManager: Verificando datos guardados...")
	
	# Verificar que las armas existan
	if saved_data.weapons.size() == 0:
		print("InventoryManager: ERROR - No hay armas en SavedData!")
		return false
	
	# Verificar inventory_positions
	if saved_data.inventory_positions.size() == 0:
		print("InventoryManager: ERROR - No hay posiciones de inventario guardadas!")
		return false
	
	# Verificar que las posiciones sean correctas (no todas en 0)
	var all_zero = true
	var positions = saved_data.inventory_positions.values()
	for pos in positions:
		if pos != 0:
			all_zero = false
			break
	
	if all_zero and positions.size() > 1:
		print("InventoryManager: ERROR - Todas las posiciones están en 0!")
		return false
	
	# Todo correcto
	print("InventoryManager: Datos guardados verificados correctamente")
	return true


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
	# Obtener el inventario del jugador
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		print("InventoryManager: No se encuentra el inventario del jugador")
		return
	
	# Desconectar cualquier señal existente para evitar duplicados
	if player_inventory.is_connected("items_swapped", self, "_on_inventory_items_swapped"):
		player_inventory.disconnect("items_swapped", self, "_on_inventory_items_swapped")
	
	# Conectar señal de intercambio
	player_inventory.connect("items_swapped", self, "_on_inventory_items_swapped")
	print("InventoryManager: Señal 'items_swapped' conectada correctamente")
	
	# Conectar otras señales relevantes
	if not player_inventory.is_connected("item_added", self, "_on_item_added_to_inventory"):
		player_inventory.connect("item_added", self, "_on_item_added_to_inventory")
		print("InventoryManager: Señal 'item_added' conectada")
	
	if not player_inventory.is_connected("item_removed", self, "_on_item_removed_from_inventory"):
		player_inventory.connect("item_removed", self, "_on_item_removed_from_inventory")
		print("InventoryManager: Señal 'item_removed' conectada")
	
	print("InventoryManager: Todas las señales conectadas correctamente")

# Manejar intercambio de items
# Manejar intercambio de items
func _on_inventory_items_swapped(from_index: int, to_index: int):
	print("InventoryManager: ===== NUEVO MÉTODO DE INTERCAMBIO =====")
	
	if not saved_data:
		print("InventoryManager: ERROR - SavedData no disponible")
		return
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		return
	
	# Después del intercambio, 'from_index' ahora tiene el item que estaba en 'to_index'
	# y 'to_index' ahora tiene el item que estaba en 'from_index'
	var item_now_at_from = player_inventory.get_item(from_index)
	var item_now_at_to = player_inventory.get_item(to_index)
	
	print("InventoryManager: Después del intercambio:")
	print("  - Slot ", from_index, " ahora tiene: ", item_now_at_from.name if item_now_at_from else "vacío")
	print("  - Slot ", to_index, " ahora tiene: ", item_now_at_to.name if item_now_at_to else "vacío")
	
	# CORRECCIÓN: Reconstruir completamente las posiciones del inventario
	# Esto asegura que tenemos todas las posiciones actualizadas y correctas

	# Primero, guardar directamente las posiciones de los items que sabemos que existen
	if item_now_at_to and item_now_at_to.get("item_type") == "weapon":
		saved_data.inventory_positions[item_now_at_to.name] = to_index
		print("InventoryManager: Establecido directamente ", item_now_at_to.name, " en posición ", to_index)

	if item_now_at_from and item_now_at_from.get("item_type") == "weapon":
		saved_data.inventory_positions[item_now_at_from.name] = from_index
		print("InventoryManager: Establecido directamente ", item_now_at_from.name, " en posición ", from_index)
	
	# Luego, recorrer todo el inventario para verificar cada slot
	print("InventoryManager: ESCANEO COMPLETO DE INVENTARIO:")
	var updated_positions = {}
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item:
			print("  Slot ", i, ": Item encontrado: ", item.name, ", Clase: ", item.get_class())
			
			# Verificar si tiene la propiedad item_type
			if item.get("item_type"):
				print("    - item_type: ", item.item_type)
				
				# Si es un arma, guardar su posición
				if item.item_type == "weapon":
					updated_positions[item.name] = i
					print("    - Guardada posición para ", item.name, ": ", i)
				else:
					print("    - No es un arma, item_type: ", item.item_type)
			else:
				print("    - No tiene propiedad item_type")
				
			# Verificar si es WeaponItem directamente
			if item is WeaponItem:
				print("    - Es WeaponItem por herencia de clase")
				updated_positions[item.name] = i
		else:
			print("  Slot ", i, ": Vacío")
	
	# Combinar las posiciones que encontramos con las existentes
	var final_positions = saved_data.inventory_positions.duplicate()
	for key in updated_positions.keys():
		final_positions[key] = updated_positions[key]
	
	# Actualizar saved_data con las nuevas posiciones
	saved_data.inventory_positions = final_positions
	print("InventoryManager: inventory_positions actualizado: ", saved_data.inventory_positions)
	
	# Guardar cambios de inmediato
	saved_data.save_data()
	
	# Verificar que la reconstrucción fue correcta
	if item_now_at_to and saved_data.inventory_positions.get(item_now_at_to.name) != to_index:
		print("InventoryManager: ERROR - La posición de '", item_now_at_to.name, "' debería ser ", to_index, " pero es ", saved_data.inventory_positions.get(item_now_at_to.name))
	
	print("InventoryManager: ===== FIN DEL MÉTODO =====")

# Manejadores para eventos del inventario
func _on_item_added_to_inventory(item: Item, slot_index: int):
	print("InventoryManager: Item añadido al inventario: ", item.name if item else "None", " en slot ", slot_index)
	
	# Si es un arma, actualizar su posición en SavedData
	if item and item.item_type == "weapon" and saved_data:
		# Verificar que es un arma válida
		if item is WeaponItem:
			# Si no tiene weapon_scene, intentar recuperarla
			if not item.weapon_scene:
				var base_name = item.name.rstrip("0123456789")
				var weapon_path = "res://Weapons/" + base_name + ".tscn"
				
				if ResourceLoader.exists(weapon_path):
					item.weapon_scene = load(weapon_path)
					print("InventoryManager: Recuperada escena de arma para ", item.name)
				else:
					print("InventoryManager ERROR: No se pudo recuperar la escena para ", item.name)
					
		# Actualizar la posición en saved_data
		saved_data.update_weapon_position(item.name, slot_index)
		print("InventoryManager: Actualizada posición del arma ", item.name, " a slot ", slot_index)
		
		# Reconstruir completamente las posiciones para garantizar consistencia
		var player_inventory = get_inventory(PLAYER_INVENTORY)
		if player_inventory:
			var updated_positions = {}
			
			# Recolectar posiciones actuales de cada arma en el inventario
			for i in range(player_inventory.capacity):
				var inv_item = player_inventory.get_item(i)
				if inv_item and inv_item.item_type == "weapon":
					updated_positions[inv_item.name] = i
			
			# Actualizar saved_data con las nuevas posiciones
			saved_data.inventory_positions = updated_positions
			print("InventoryManager: Posiciones reconstruidas: ", saved_data.inventory_positions)
		
		# Guardar los cambios
		saved_data.save_data()

# Manejador para item eliminado
func _on_item_removed_from_inventory(item: Item, slot_index: int):
	print("InventoryManager: Item eliminado del inventario: ", item.name if item else "None", " del slot ", slot_index)
	
	# Si era un arma, actualizar SavedData
	if item and item.item_type == "weapon" and saved_data:
		# Verificar si el arma sigue en el inventario pero en otro slot
		var player_inventory = get_inventory(PLAYER_INVENTORY)
		var found = false
		
		if player_inventory:
			for i in range(player_inventory.capacity):
				var current_item = player_inventory.get_item(i)
				if current_item and current_item.name == item.name:
					found = true
					break
		
		# Si ya no está en el inventario, quitar la referencia en SavedData
		if not found and saved_data.inventory_positions.has(item.name):
			saved_data.inventory_positions.erase(item.name)
			print("InventoryManager: Eliminada referencia del arma en SavedData")
			
			# Guardar los cambios
			saved_data.save_data()
