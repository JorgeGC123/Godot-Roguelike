extends Node

# Esta clase proporciona una interfaz compatible con el sistema de inventario antiguo
# Actúa como un puente entre el viejo sistema y el nuevo

# Referencias
var inventory_manager: Node
var player_ref: WeakRef
var ui_instance: CanvasLayer

# Inventario panel - referencia al panel original
var old_inventory_instance = null

func _ready():
    # Obtener referencias
    if has_node("/root/InventoryManager"):
        inventory_manager = get_node("/root/InventoryManager")
    else:
        push_error("InventoryManager not found")
        return
    
    # Buscar el jugador
    var player = get_tree().get_nodes_in_group("player")
    if player.size() > 0:
        player_ref = weakref(player[0])
        inventory_manager.set_player(player[0])
    
    # Conectar señales relevantes
    if inventory_manager:
        inventory_manager.connect("inventory_created", self, "_on_inventory_created")
        inventory_manager.connect("inventory_deleted", self, "_on_inventory_deleted")
    
    # Importar datos existentes
    if inventory_manager:
        inventory_manager.import_from_saved_data()

# Proxy para el método add_item antiguo
func add_item(item):
    # Si es un nodo de arma
    if item is Node and item.get_class() == "Weapon":
        # Convertir a WeaponItem
        var weapon_item = ItemFactory.create_item_from_node(item)
        if weapon_item:
            return inventory_manager.add_item_to_active(weapon_item)
    
    # Otros tipos de items
    # ...
    
    return false

# Proxy para el método remove_item antiguo
func remove_item(index_or_item):
    if typeof(index_or_item) == TYPE_INT:
        # Es un índice
        return inventory_manager.remove_item_from_active(index_or_item)
    else:
        # Es un item/nodo
        var player_inventory = inventory_manager.get_inventory(InventoryManager.PLAYER_INVENTORY)
        if player_inventory:
            # Buscar el item por nombre o referencia
            for i in range(player_inventory.capacity):
                var item = player_inventory.get_item(i)
                if item and (item.name == index_or_item.name or item == index_or_item):
                    return player_inventory.remove_item(i)
    
    return null

# Mostrar el inventario usando el nuevo sistema pero manteniendo la interfaz antigua
func show_inventory():
    # Verificar si ya hay una instancia del inventario antiguo
    if old_inventory_instance:
        old_inventory_instance.show_inventory()
        return
    
    # Crear una instancia del nuevo UI pero con la vieja interfaz
    if ui_instance:
        ui_instance.show()
    else:
        # Crea la nueva instancia del inventario UI
        var inventory_ui_scene = load("res://InventorySystem/View/InventoryUI.tscn")
        ui_instance = inventory_ui_scene.instance()
        get_tree().root.add_child(ui_instance)
        
        # Configurarla con el modelo de inventario del jugador
        var player_inventory = inventory_manager.get_inventory(InventoryManager.PLAYER_INVENTORY)
        ui_instance.setup(player_inventory)
        
        # Conectar señal de cierre
        ui_instance.connect("inventory_closed", self, "_on_inventory_closed")
    
    ui_instance.show_inventory()

# Ocultar el inventario
func hide_inventory():
    if old_inventory_instance:
        old_inventory_instance.hide_inventory()
    elif ui_instance:
        ui_instance.hide_inventory()

# Guardar datos
func save_data():
    if inventory_manager:
        inventory_manager.export_to_saved_data()

# Callbacks para señales
func _on_inventory_closed():
    # Aquí puedes agregar lógica especial al cerrar el inventario
    pass

func _on_inventory_created(inventory_id, inventory):
    # Aquí puedes manejar la creación de un nuevo inventario
    pass

func _on_inventory_deleted(inventory_id):
    # Aquí puedes manejar la eliminación de un inventario
    pass

# Métodos específicos para compatibilidad con el sistema anterior
func get_inventory_item(index: int):
    var inventory = inventory_manager.get_inventory(InventoryManager.PLAYER_INVENTORY)
    if inventory:
        return inventory.get_item(index)
    return null

# Exportar datos antiguos a nuevo formato
func export_old_inventory_to_new():
    inventory_manager.import_from_saved_data()

# Importar nuevos datos al formato antiguo
func import_new_inventory_to_old():
    inventory_manager.export_to_saved_data()


# Manejador para cuando el jugador recoge un arma
func _on_player_weapon_picked_up(weapon_texture):
    # Buscar el arma recién añadida
    var player = get_tree().get_nodes_in_group("player")[0]
    if not player:
        return
    
    # Encontrar el arma más reciente
    var weapons_container = player.get_node("Weapons")
    if not weapons_container or weapons_container.get_child_count() == 0:
        return
    
    var latest_weapon = weapons_container.get_child(weapons_container.get_child_count() - 1)
    
    # Usar ItemFactory para crear y agregar el WeaponItem al inventario
    var weapon_item = ItemFactory.create_item_from_node(latest_weapon)
    if weapon_item and has_node("/root/InventoryManager"):
        get_node("/root/InventoryManager").add_item_to_active(weapon_item)
        print("LegacyAdapter: Added weapon to inventory:", weapon_item.name)