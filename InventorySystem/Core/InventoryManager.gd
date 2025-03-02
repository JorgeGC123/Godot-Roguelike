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

# Obtener items por tipo de un inventario específico
func get_items_by_type(type: String, inventory_id: String = PLAYER_INVENTORY) -> Array:
	var items_array = []
	var inventory = get_inventory(inventory_id)
	
	if not inventory:
		return items_array
		
	for i in range(inventory.capacity):
		var item = inventory.get_item(i)
		if item and item.item_type == type:
			items_array.append({"item": item, "index": i})
			
	return items_array

# Obtener el arma equipada actual
func get_equipped_weapon() -> WeaponItem:
	if not saved_data:
		return null
		
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		return null
		
	# Obtener el índice del arma equipada desde SavedData
	var equipped_index = saved_data.equipped_weapon_index
	if equipped_index < 0:
		return null
		
	# Buscar el arma en la posición guardada
	var item = player_inventory.get_item(equipped_index)
	if item and item.item_type == "weapon":
		return item
		
	# Si no encontramos el arma en la posición esperada, buscar la primera arma
	var weapons = get_items_by_type("weapon")
	if weapons.size() > 0:
		return weapons[0].item
		
	return null

# Verificar si un item está equipado
func is_item_equipped(item: Item) -> bool:
	if not saved_data or not item or item.item_type != "weapon":
		return false
		
	var equipped_weapon = get_equipped_weapon()
	if not equipped_weapon:
		return false
		
	return equipped_weapon.name == item.name

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
	
	print("InventoryManager: Importando desde SavedData")
	print("InventoryManager: Armas en SavedData: ", saved_data.weapons.size())
	print("InventoryManager: Consumibles en SavedData: ", saved_data.items.size())
	print("InventoryManager: Posiciones en SavedData: ", saved_data.inventory_positions)
	
	# Primero, limpiar el inventario para evitar conflictos
	for i in range(player_inventory.capacity):
		player_inventory.remove_item(i)
	
	# ===== IMPORTACIÓN DE ARMAS =====
	var weapon_position_map = {}
	
	# Llenar el mapa usando los datos guardados en inventory_positions
	for weapon_name in saved_data.inventory_positions.keys():
		var position = saved_data.inventory_positions[weapon_name]
		print("InventoryManager: Posición guardada para ", weapon_name, ": ", position)
		weapon_position_map[weapon_name] = position
	
	# Procesar cada arma y colocarla en su posición guardada
	for i in range(saved_data.weapons.size()):
		var weapon_node = saved_data.weapons[i]
		var weapon_name = weapon_node.name
		
		# Obtener la posición guardada para esta arma específica
		var target_position = saved_data.inventory_positions.get(weapon_name, i)
		print("InventoryManager: Colocando arma ", weapon_name, " en posición ", target_position)
		
		# Crear el item para esta arma
		var weapon_item = ItemFactory.create_item_from_node(weapon_node)
		if weapon_item:
			# Intentar colocar en la posición específica guardada
			var success = player_inventory.add_item(weapon_item, target_position)
			
			if success:
				print("InventoryManager: Añadida arma ", weapon_item.name, " a la posición ", target_position)
			else:
				# Si falla, buscar slot alternativo
				var alt_slot = player_inventory.get_first_empty_slot()
				if alt_slot != -1:
					print("InventoryManager: ERROR - Slot ", target_position, " ocupado, usando alternativa: ", alt_slot)
					player_inventory.add_item(weapon_item, alt_slot)
					# Actualizar la posición en SavedData
					saved_data.update_weapon_position(weapon_item.name, alt_slot)
				else:
					print("InventoryManager: ERROR - No se pudo colocar ", weapon_item.name, " - inventario lleno")
	
	# ===== IMPORTACIÓN DE CONSUMIBLES =====
	print("InventoryManager: Importando consumibles...")
	for i in range(saved_data.items.size()):
		var consumable_node = saved_data.items[i]
		var consumable_name = consumable_node.name
		
		print("InventoryManager: Procesando consumible ", consumable_name)
		
		# Buscar si el consumible tiene una posición guardada
		var target_position = saved_data.inventory_positions.get(consumable_name, -1)
		if target_position == -1:
			# Si no tiene posición guardada, buscar el primer slot vacío
			target_position = player_inventory.get_first_empty_slot()
			print("InventoryManager: Consumible sin posición guardada, usando slot vacío: ", target_position)
		
		# Crear el item para este consumible
		var consumable_item = ItemFactory.create_item_from_node(consumable_node)
		if consumable_item:
			# Intentar colocar en la posición específica
			if target_position != -1:
				var success = player_inventory.add_item(consumable_item, target_position)
				if success:
					print("InventoryManager: Añadido consumible ", consumable_item.name, " a la posición ", target_position)
				else:
					# Si no se pudo colocar en la posición deseada, buscar otro slot
					var alt_slot = player_inventory.get_first_empty_slot()
					if alt_slot != -1:
						print("InventoryManager: ERROR - Slot ", target_position, " ocupado, usando alternativa: ", alt_slot)
						player_inventory.add_item(consumable_item, alt_slot)
						# Actualizar la posición guardada
						saved_data.inventory_positions[consumable_item.name] = alt_slot
					else:
						print("InventoryManager: ERROR - No se pudo añadir el consumible ", consumable_item.name, " - inventario lleno")
			else:
				print("InventoryManager: ERROR - No hay slots disponibles para el consumible ", consumable_item.name)
		else:
			print("InventoryManager: ERROR - No se pudo crear el item para el consumible ", consumable_name)
	
	# Actualizar la UI
	player_inventory.emit_signal("inventory_updated")
	
	print("InventoryManager: Importación desde SavedData completada")
	print("InventoryManager: Estado final del inventario:")
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item:
			print(" - Slot ", i, ": ", item.name, " (tipo: ", item.item_type, ")")

func export_to_saved_data() -> bool:
	if not saved_data:
		push_warning("SavedData not found, cannot export")
		return false
	
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if not player_inventory:
		push_warning("Player inventory not found")
		return false
	
	print("InventoryManager: Exporting to SavedData")
	
	# ===== MANEJO DE ARMAS =====
	# Verificar el estado actual de las armas antes de modificarlas
	var current_weapons_count = saved_data.weapons.size()
	print("InventoryManager: Armas actuales en SavedData: ", current_weapons_count)
	
	# Debugear las posiciones actuales de SavedData
	print("InventoryManager: Posiciones actuales en SavedData: ", saved_data.inventory_positions)
	
	# 1. PRIMERO: verificar qué armas hay en el inventario y donde están exactamente
	var inventory_weapons = []
	var inventory_positions = {}
	
	# ===== MANEJO DE CONSUMIBLES =====
	# También necesitamos exportar los consumibles
	var inventory_consumables = []
	
	print("\nINVENTARIO ACTUAL:")
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item:
			print("- Slot ", i, ": ", item.name, " (tipo: ", item.item_type, ")")
			
			# Guardar posición para cualquier tipo de item
			inventory_positions[item.name] = i
			
			# Manejar armas
			if item.item_type == "weapon":
				inventory_weapons.append(item)
			
			# Manejar consumibles
			elif item.item_type == "consumable":
				print("- Agregando consumible ", item.name, " al array de consumibles")
				inventory_consumables.append(item)
	
	print("\nARMAS DETECTADAS: ", inventory_weapons.size())
	print("CONSUMIBLES DETECTADOS: ", inventory_consumables.size())
	print("POSICIONES DETECTADAS: ", inventory_positions)
	
	# Si no tenemos armas, NO preservar el estado actual ya que el jugador las ha soltado
	if inventory_weapons.size() == 0 and current_weapons_count > 0:
		print("InventoryManager: AVISO - No se detectaron armas en el inventario pero hay ", current_weapons_count, " armas en SavedData")
		print("InventoryManager: El jugador ha soltado sus armas, limpiando SavedData.weapons")
		# No preservamos las armas - si el inventario está vacío, es correcto que saved_data también lo esté
	
	# 2. SEGUNDO: crear nuevas instancias de armas basadas en las armas del inventario
	var new_weapons = []
	
	print("\nCREANDO NUEVAS INSTANCIAS:")
	for weapon_item in inventory_weapons:
		print("- Procesando ", weapon_item.name)
		
		# Verificar si estamos tratando con un WeaponItem válido
		if not (weapon_item is WeaponItem):
			print("  ERROR: El objeto no es un WeaponItem válido. Tipo: ", weapon_item.get_class())
			continue
		
		# Verificar si tenemos weapon_scene usando get() para seguridad
		if not weapon_item.get("weapon_scene"):
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
		var weapon_scene = weapon_item.get("weapon_scene")
		if not weapon_scene:
			print("  ERROR: No se pudo obtener weapon_scene para instanciar")
			continue
			
		var weapon_instance = weapon_scene.instance()
		if not weapon_instance:
			print("  ERROR: Fallo al instanciar el arma desde la escena")
			continue
		
		# Mantener el nombre exacto
		weapon_instance.name = weapon_item.name
		
		# Configurar estadísticas
		if weapon_instance.has_node("Node2D/Sprite/Hitbox"):
			weapon_instance.get_node("Node2D/Sprite/Hitbox").damage = weapon_item.damage
		
		# Añadir a las nuevas armas
		new_weapons.append(weapon_instance)
		print("  AÑADIDA: ", weapon_instance.name, " a new_weapons")
	
	# ===== MANEJO DE CONSUMIBLES =====
	# 3. Crear instancias de consumibles a partir de los items en el inventario
	var new_consumables = []
	
	print("\nPROCESANDO CONSUMIBLES:")
	for consumable_item in inventory_consumables:
		print("- Procesando consumible ", consumable_item.name)
		
		# Verificar que sea un ConsumableItem válido
		if consumable_item is ConsumableItem:
			# Instanciar la escena del consumible si es posible
			if consumable_item.item_scene:
				var consumable_instance = consumable_item.item_scene.instance()
				consumable_instance.name = consumable_item.name
				new_consumables.append(consumable_instance)
				print("  AÑADIDO: ", consumable_instance.name, " a new_consumables")
			else:
				# Si no tiene escena, intentar cargarla
				var possible_path = "res://Items/" + consumable_item.name + ".tscn"
				if ResourceLoader.exists(possible_path):
					var consumable_instance = load(possible_path).instance()
					consumable_instance.name = consumable_item.name
					new_consumables.append(consumable_instance)
					print("  ESCENA RECUPERADA: Añadido ", consumable_instance.name, " a new_consumables")
				else:
					print("  ERROR: No se pudo encontrar la escena para ", consumable_item.name)
		else:
			print("  ERROR: No es un ConsumableItem válido")
	
	# 4. ACTUALIZAR SAVEDDATA
	print("\nACTUALIZANDO SAVEDDATA:")
	print("- Armas creadas: ", new_weapons.size())
	print("- Consumibles creados: ", new_consumables.size())
	print("- Posiciones de armas: ", inventory_positions)
	
	# Guardar el equipped_weapon_index actual
	var current_equipped_index = saved_data.equipped_weapon_index
	
	# Actualizar saved_data
	saved_data.weapons = new_weapons
	saved_data.items = new_consumables
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
	print("- Consumibles guardados: ", saved_data.items.size())
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
	print("InventoryManager: Intentando eliminar item por nombre: ", item_name)
	
	var inventory = get_active_inventory()
	if not inventory:
		print("InventoryManager: ERROR - No hay inventario activo")
		return null
		
	# Buscar item por nombre
	for i in range(inventory.capacity):
		var item = inventory.get_item(i)
		if item and item.name == item_name:
			print("InventoryManager: Encontrado item ", item_name, " en slot ", i)
			
			# Asegurarnos de que se elimine de SavedData
			if saved_data and saved_data.inventory_positions.has(item_name):
				print("InventoryManager: Eliminando posición de ", item_name, " de SavedData")
				saved_data.inventory_positions.erase(item_name)
				
				# Buscar y eliminar de weapons si es un arma
				if item.item_type == "weapon":
					for j in range(saved_data.weapons.size()):
						if saved_data.weapons[j].name == item_name:
							print("InventoryManager: Eliminando arma de SavedData.weapons en índice ", j)
							saved_data.weapons.remove(j)
							break
				
				# Guardar cambios inmediatamente
				saved_data.save_data()
			
			# Eliminar del inventario y retornar
			return inventory.remove_item(i)
	
	print("InventoryManager: No se encontró item con nombre ", item_name)
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
				
				# Guardar posición para cualquier tipo de item
				updated_positions[item.name] = i
				print("    - Guardada posición para ", item.name, ": ", i)
			else:
				print("    - No tiene propiedad item_type")
				
			# Verificar si es WeaponItem directamente
			if item is WeaponItem:
				print("    - Es WeaponItem por herencia de clase")
				updated_positions[item.name] = i
	
	# Combinar las posiciones que encontramos con las existentes
	var final_positions = saved_data.inventory_positions.duplicate()
	for key in updated_positions.keys():
		final_positions[key] = updated_positions[key]
	
	# Actualizar saved_data con las nuevas posiciones
	saved_data.inventory_positions = final_positions
	print("InventoryManager: inventory_positions actualizado: ", saved_data.inventory_positions)

	# ¿Tenemos consumibles que guardar?
	var has_consumables = false
	for i in range(player_inventory.capacity):
		var item = player_inventory.get_item(i)
		if item and item.item_type == "consumable":
			has_consumables = true
			break
	
	if has_consumables:
		export_to_saved_data()
	else:
		# Guardar solo las posiciones de armas
		saved_data.save_data()
	
	# Verificar que la reconstrucción fue correcta
	if item_now_at_to and saved_data.inventory_positions.get(item_now_at_to.name) != to_index:
		print("InventoryManager: ERROR - La posición de '", item_now_at_to.name, "' debería ser ", to_index, " pero es ", saved_data.inventory_positions.get(item_now_at_to.name))
	
	print("InventoryManager: ===== FIN DEL MÉTODO =====")

# Manejadores para eventos del inventario
func _on_item_added_to_inventory(item: Item, slot_index: int):
	print("InventoryManager: Item añadido al inventario: ", item.name if item else "None", " en slot ", slot_index)
	
	if not saved_data:
		print("InventoryManager: ERROR - SavedData no disponible")
		return
	
	# === MANEJO DE ARMAS ===
	if item and item.item_type == "weapon":
		print("InventoryManager: Procesando arma: ", item.name)
		
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
					print("InventoryManager: ERROR - No se pudo recuperar la escena para ", item.name)
					
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
	
	# === MANEJO DE CONSUMIBLES ===
	elif item and item.item_type == "consumable":
		print("InventoryManager: Procesando consumible: ", item.name)
		
		# Verificar que es un consumible válido
		if item is ConsumableItem:
			print("InventoryManager: Consumible válido detectado. Exportando a SavedData")
			# Forzar exportación a SavedData para guardar el consumible
			export_to_saved_data()
		else:
			print("InventoryManager: ERROR - El item no es un ConsumableItem válido")
	
	# Guardar cambios en todos los casos
	else:
		# Para otros tipos de ítems, simplemente guardar
		saved_data.save_data()
	
	# Depuración adicional
	print("InventoryManager: Estado del inventario después de añadir el item:")
	var player_inventory = get_inventory(PLAYER_INVENTORY)
	if player_inventory:
		for i in range(player_inventory.capacity):
			var inv_item = player_inventory.get_item(i)
			if inv_item:
				print(" - Slot ", i, ": ", inv_item.name, " (tipo: ", inv_item.item_type, ")")

# Manejador para item eliminado
func _on_item_removed_from_inventory(item: Item, slot_index: int):
	print("InventoryManager: Item eliminado del inventario: ", item.name if item else "None", " del slot ", slot_index)
	
	if not saved_data:
		return
		
	# Si era un arma, actualizar SavedData
	if item and item.item_type == "weapon":
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
			
	# Si era un consumible, actualizar los items de SavedData
	elif item and item.item_type == "consumable":
		print("InventoryManager: Eliminado consumible. Exportando a SavedData")
		export_to_saved_data()
		
	# Guardar los cambios
	saved_data.save_data()
