extends Reference

# Tests para verificar el funcionamiento de ItemFactory

func test_create_base_item():
	# Verificar que se puede crear un item base
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	var item_data = {
		"id": "test_item",
		"name": "Test Item",
		"description": "A test item",
		"item_type": "base"
	}
	
	var item = factory.create_item_from_data(item_data)
	return item != null and item.id == "test_item" and item.item_type == "base"

func test_create_weapon_item():
	# Verificar que se puede crear un item de tipo arma
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	var weapon_data = {
		"id": "test_sword",
		"name": "Test Sword",
		"description": "A test sword",
		"item_type": "weapon",
		"damage": 10,
		"attack_speed": 1.5
	}
	
	var weapon = factory.create_item_from_data(weapon_data)
	return weapon != null and weapon is WeaponItem and weapon.damage == 10 and weapon.attack_speed == 1.5

func test_create_consumable_item():
	# Verificar que se puede crear un item de tipo consumible
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	var consumable_data = {
		"id": "test_potion",
		"name": "Test Potion",
		"description": "A test potion",
		"item_type": "consumable",
		"heal_amount": 5,
		"uses_left": 2
	}
	
	var consumable = factory.create_item_from_data(consumable_data)
	return consumable != null and consumable is ConsumableItem and consumable.heal_amount == 5 and consumable.uses_left == 2

func test_item_database_loading():
	# Verificar que la base de datos de items se carga correctamente
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	return factory.item_database.size() > 0 and factory.item_database.has("sword")

func test_create_item_from_id():
	# Verificar que se puede crear un item a partir de su ID en la base de datos
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	var item = factory.create_item("sword")
	return item != null and item.id == "sword" and item.item_type == "weapon"

func test_item_serialization():
	# Verificar que la serialización de items funciona correctamente
	var factory = ItemFactory.new()
	factory._ready() # Inicializar base de datos
	
	var original_item = factory.create_item("sword")
	var serialized_data = original_item.serialize()
	var recreated_item = factory.create_item_from_data(serialized_data)
	
	return recreated_item != null and recreated_item.id == original_item.id and recreated_item.item_type == original_item.item_type
