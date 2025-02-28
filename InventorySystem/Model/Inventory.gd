class_name InventoryModel
extends Resource

signal item_added(item, slot_index)
signal item_removed(item, slot_index)
signal items_swapped(from_index, to_index)
signal inventory_updated()

export(int) var capacity: int = 25
export(Array) var slots = []  # Array de InventorySlot

func _init(initial_capacity: int = 25):
	capacity = initial_capacity
	_initialize_slots()

func _initialize_slots() -> void:
	slots = []
	for i in range(capacity):
		slots.append(InventorySlot.new())

# Añadir item a un slot específico
# Añadir item a un slot específico
func add_item(item: Item, slot_index: int = -1) -> bool:
	# Si no se especifica slot, buscar el primer slot disponible
	if slot_index == -1:
		slot_index = get_first_empty_slot()
		if slot_index == -1:
			print("InventoryModel: Cannot add item - inventory full")
			return false  # Inventario lleno
	
	# Verificar índice válido
	if slot_index < 0 or slot_index >= capacity:
		print("InventoryModel: Cannot add item - invalid slot index: ", slot_index)
		return false
	
	# Verificar si el slot está vacío
	if not slots[slot_index].is_empty():
		print("InventoryModel: Cannot add item to slot ", slot_index, " - slot not empty")
		
		# Alternativa: intentar encontrar otro slot vacío
		var alt_slot = get_first_empty_slot()
		if alt_slot != -1:
			print("InventoryModel: Using alternative slot: ", alt_slot)
			return add_item(item, alt_slot)
			
		return false
	
	# Asignar item al slot
	print("InventoryModel: Adding item ", item.name, " to slot ", slot_index)
	slots[slot_index].set_item(item)
	emit_signal("item_added", item, slot_index)
	emit_signal("inventory_updated")
	return true

# Remover item de un slot
func remove_item(slot_index: int) -> Item:
	if slot_index < 0 or slot_index >= capacity:
		return null
	
	var item = slots[slot_index].get_item()
	if item:
		slots[slot_index].clear()
		emit_signal("item_removed", item, slot_index)
		emit_signal("inventory_updated")
	return item

# Intercambiar items entre slots
func swap_items(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= capacity or to_index < 0 or to_index >= capacity:
		return false
	
	var from_item = slots[from_index].get_item()
	var to_item = slots[to_index].get_item()
	
	# Debug
	print("InventoryModel: Swapping items")
	print("  - From slot ", from_index, ": ", from_item.name if from_item else "None")
	print("  - To slot ", to_index, ": ", to_item.name if to_item else "None")
	
	# Realizar intercambio
	slots[from_index].set_item(to_item)
	slots[to_index].set_item(from_item)
	
	# Nota: la sincronización con SavedData se hará desde InventoryManager
	# ya que los Resources no pueden acceder directamente a los autoloads
	
	emit_signal("items_swapped", from_index, to_index)
	emit_signal("inventory_updated")
	return true

# Obtener item en un slot específico
func get_item(slot_index: int) -> Item:
	if slot_index < 0 or slot_index >= capacity:
		return null
	return slots[slot_index].get_item()

# Buscar el primer slot vacío
func get_first_empty_slot() -> int:
	for i in range(capacity):
		if slots[i].is_empty():
			return i
	return -1

# Verificar si el inventario está lleno
func is_full() -> bool:
	return get_first_empty_slot() == -1

# Serializar para guardar
func serialize() -> Dictionary:
	var data = {
		"capacity": capacity,
		"items": []
	}
	
	for i in range(capacity):
		var slot = slots[i]
		if not slot.is_empty():
			var item = slot.get_item()
			data.items.append({
				"index": i,
				"item_data": item.serialize()
			})
	
	return data

# Deserializar datos guardados
func deserialize(data: Dictionary) -> void:
	capacity = data.get("capacity", capacity)
	_initialize_slots()
	
	for item_data in data.get("items", []):
		var index = item_data.get("index", -1)
		if index >= 0 and index < capacity:
			var item = ItemFactory.create_item_from_data(item_data.get("item_data", {}))
			if item:
				slots[index].set_item(item)
	
	emit_signal("inventory_updated")
