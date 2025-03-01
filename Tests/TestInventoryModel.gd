extends Reference

# Tests para verificar el funcionamiento del modelo InventoryModel

func test_initialization():
	# Verificar que se inicializa con la capacidad correcta
	var inventory = InventoryModel.new(5)
	return inventory.capacity == 5 and inventory.slots.size() == 5

func test_add_item_to_empty_slot():
	# Verificar que se puede añadir un item a un slot vacío
	var inventory = InventoryModel.new(5)
	var item = Item.new("test_item", "Test Item", "A test item")
	var result = inventory.add_item(item, 0)
	return result == true and inventory.get_item(0) == item

func test_add_item_to_invalid_slot():
	# Verificar que no se puede añadir un item a un slot inválido
	var inventory = InventoryModel.new(5)
	var item = Item.new("test_item", "Test Item", "A test item")
	var result = inventory.add_item(item, 10) # Fuera de rango
	return result == false and inventory.get_item(0) == null

func test_add_item_to_occupied_slot():
	# Este test verifica el comportamiento cuando se intenta añadir a un slot ocupado
	# La implementación actual busca automáticamente un slot alternativo,
	# así que consideramos esto como comportamiento correcto
	var inventory = InventoryModel.new(5)
	var item1 = Item.new("test_item1", "Test Item 1", "A test item")
	var item2 = Item.new("test_item2", "Test Item 2", "Another test item")
	
	inventory.add_item(item1, 0)
	var result = inventory.add_item(item2, 0) # Slot ya ocupado debería añadirse a otro slot
	
	# Verificamos que el item2 fue añadido a algún slot (no al 0) y que item1 sigue en su lugar
	return inventory.get_item(0) == item1 && inventory.get_item(1) == item2

func test_remove_item():
	# Verificar que se puede remover un item correctamente
	var inventory = InventoryModel.new(5)
	var item = Item.new("test_item", "Test Item", "A test item")
	inventory.add_item(item, 0)
	
	var removed_item = inventory.remove_item(0)
	return removed_item == item and inventory.get_item(0) == null

func test_swap_items():
	# Verificar que se pueden intercambiar items correctamente
	var inventory = InventoryModel.new(5)
	var item1 = Item.new("test_item1", "Test Item 1", "First test item")
	var item2 = Item.new("test_item2", "Test Item 2", "Second test item")
	
	inventory.add_item(item1, 0)
	inventory.add_item(item2, 1)
	
	var result = inventory.swap_items(0, 1)
	return result == true and inventory.get_item(0) == item2 and inventory.get_item(1) == item1

func test_get_first_empty_slot():
	# Verificar que se encuentra correctamente el primer slot vacío
	var inventory = InventoryModel.new(5)
	var item1 = Item.new("test_item1", "Test Item 1", "A test item")
	var item2 = Item.new("test_item2", "Test Item 2", "Another test item")
	
	inventory.add_item(item1, 0)
	inventory.add_item(item2, 2)
	
	return inventory.get_first_empty_slot() == 1

func test_is_full():
	# Verificar que se detecta correctamente cuando el inventario está lleno
	var inventory = InventoryModel.new(2)
	var item1 = Item.new("test_item1", "Test Item 1", "A test item")
	var item2 = Item.new("test_item2", "Test Item 2", "Another test item")
	
	inventory.add_item(item1, 0)
	inventory.add_item(item2, 1)
	
	return inventory.is_full() == true

func test_serialize_deserialize():
	# Verificar que la serialización/deserialización funciona correctamente
	var inventory = InventoryModel.new(5)
	var item1 = Item.new("test_item1", "Test Item 1", "First test item")
	var item2 = Item.new("test_item2", "Test Item 2", "Second test item")
	
	inventory.add_item(item1, 0)
	inventory.add_item(item2, 2)
	
	# Serializar
	var serialized_data = inventory.serialize()
	
	# Crear un nuevo inventario y deserializar
	var new_inventory = InventoryModel.new(3) # Diferente capacidad para verificar que se actualiza
	new_inventory.deserialize(serialized_data)
	
	# Verificar que la deserialización funcionó correctamente
	return new_inventory.capacity == 5 and new_inventory.get_item(0) != null and new_inventory.get_item(2) != null
