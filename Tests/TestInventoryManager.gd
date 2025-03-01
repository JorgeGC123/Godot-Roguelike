extends Reference

# Tests para verificar el funcionamiento del InventoryManager

func test_create_inventory():
	# Verificar que se puede crear un nuevo inventario
	# Usamos el autoload existente en lugar de crear una nueva instancia
	var inventory = InventoryManager.create_inventory("test_inventory", 10)
	
	return inventory != null and InventoryManager.get_inventory("test_inventory") == inventory

func test_delete_inventory():
	# Verificar que se puede eliminar un inventario
	# Usamos el autoload existente en lugar de crear una nueva instancia
	InventoryManager.create_inventory("test_inventory", 10)
	
	var result = InventoryManager.delete_inventory("test_inventory")
	return result == true and InventoryManager.get_inventory("test_inventory") == null

func test_set_active_inventory():
	# Verificar que se puede establecer el inventario activo
	# Usamos el autoload existente en lugar de crear una nueva instancia
	InventoryManager.create_inventory("inventory1", 5)
	InventoryManager.create_inventory("inventory2", 10)
	
	InventoryManager.set_active_inventory("inventory2")
	return InventoryManager.active_inventory_id == "inventory2"

func test_get_active_inventory():
	# Verificar que se puede obtener el inventario activo
	# Usamos el autoload existente en lugar de crear una nueva instancia
	var inventory = InventoryManager.create_inventory("test_inventory", 10)
	InventoryManager.set_active_inventory("test_inventory")
	
	return InventoryManager.get_active_inventory() == inventory

func test_add_item_to_active():
	# Verificar que se puede añadir un item al inventario activo
	# Usamos el autoload existente en lugar de crear una nueva instancia
	InventoryManager.create_inventory("test_inventory", 5)
	InventoryManager.set_active_inventory("test_inventory")
	
	var item = Item.new("test_item", "Test Item", "A test item")
	var result = InventoryManager.add_item_to_active(item)
	
	var active_inventory = InventoryManager.get_active_inventory()
	return result == true and active_inventory.get_item(0) == item

func test_remove_item_from_active():
	# Verificar que se puede remover un item del inventario activo
	# Usamos el autoload existente en lugar de crear una nueva instancia
	InventoryManager.create_inventory("test_inventory", 5)
	InventoryManager.set_active_inventory("test_inventory")
	
	var item = Item.new("test_item", "Test Item", "A test item")
	InventoryManager.add_item_to_active(item, 0)
	
	var removed_item = InventoryManager.remove_item_from_active(0)
	var active_inventory = InventoryManager.get_active_inventory()
	
	return removed_item == item and active_inventory.get_item(0) == null

func test_player_inventory_default():
	# Verificar que el inventario del jugador se crea por defecto
	# El autoload ya debería tener el inventario del jugador inicializado
	return InventoryManager.get_inventory(InventoryManager.PLAYER_INVENTORY) != null
