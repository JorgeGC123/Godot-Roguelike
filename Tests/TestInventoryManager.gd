extends Reference

# Tests para verificar el funcionamiento del InventoryManager

func test_create_inventory():
	# Verificar que se puede crear un nuevo inventario
	var manager = InventoryManager.new()
	var inventory = manager.create_inventory("test_inventory", 10)
	
	return inventory != null and manager.get_inventory("test_inventory") == inventory

func test_delete_inventory():
	# Verificar que se puede eliminar un inventario
	var manager = InventoryManager.new()
	manager.create_inventory("test_inventory", 10)
	
	var result = manager.delete_inventory("test_inventory")
	return result == true and manager.get_inventory("test_inventory") == null

func test_set_active_inventory():
	# Verificar que se puede establecer el inventario activo
	var manager = InventoryManager.new()
	manager.create_inventory("inventory1", 5)
	manager.create_inventory("inventory2", 10)
	
	manager.set_active_inventory("inventory2")
	return manager.active_inventory_id == "inventory2"

func test_get_active_inventory():
	# Verificar que se puede obtener el inventario activo
	var manager = InventoryManager.new()
	var inventory = manager.create_inventory("test_inventory", 10)
	manager.set_active_inventory("test_inventory")
	
	return manager.get_active_inventory() == inventory

func test_add_item_to_active():
	# Verificar que se puede añadir un item al inventario activo
	var manager = InventoryManager.new()
	manager.create_inventory("test_inventory", 5)
	manager.set_active_inventory("test_inventory")
	
	var item = Item.new("test_item", "Test Item", "A test item")
	var result = manager.add_item_to_active(item)
	
	var active_inventory = manager.get_active_inventory()
	return result == true and active_inventory.get_item(0) == item

func test_remove_item_from_active():
	# Verificar que se puede remover un item del inventario activo
	var manager = InventoryManager.new()
	manager.create_inventory("test_inventory", 5)
	manager.set_active_inventory("test_inventory")
	
	var item = Item.new("test_item", "Test Item", "A test item")
	manager.add_item_to_active(item, 0)
	
	var removed_item = manager.remove_item_from_active(0)
	var active_inventory = manager.get_active_inventory()
	
	return removed_item == item and active_inventory.get_item(0) == null

func test_player_inventory_default():
	# Verificar que el inventario del jugador se crea por defecto
	var manager = InventoryManager.new()
	manager._ready() # Simular el método _ready()
	
	return manager.get_inventory(manager.PLAYER_INVENTORY) != null
