extends Node

# Base de datos de items para referencia rápida
var item_database = {}

func _ready():
    # Inicializar base de datos de items
    _load_item_database()

# Cargar base de datos de items desde archivos
func _load_item_database():
    # Aquí podrías cargar desde un JSON o un recurso
    # Por ahora, lo haremos manualmente con algunos ejemplos
    
    # Armas predefinidas
    _register_weapon_template("sword", "Espada", "Una espada básica", 10, 1.0, "res://Weapons/Sword.tscn")
    _register_weapon_template("crossbow", "Ballesta", "Una ballesta de largo alcance", 8, 0.8, "res://Weapons/Crossbow.tscn")
    
    # Añadir más tipos de items según sea necesario

# Registrar una plantilla de arma en la base de datos
func _register_weapon_template(id: String, name: String, description: String, damage: int, attack_speed: float, scene_path: String):
    var template = {
        "id": id,
        "name": name,
        "description": description,
        "icon_path": "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/knight/weapon_" + id + "_1.png",
        "item_type": "weapon",
        "damage": damage,
        "attack_speed": attack_speed,
        "weapon_scene_path": scene_path
    }
    
    item_database[id] = template

# Crear un item basado en ID de la base de datos
func create_item(item_id: String):
    if not item_database.has(item_id):
        push_warning("Item ID not found in database: " + item_id)
        return null
    
    var template = item_database[item_id]
    return create_item_from_data(template)

# Crear un item a partir de datos serializados
func create_item_from_data(data: Dictionary):
    var item_type = data.get("item_type", "base")
    
    match item_type:
        "weapon":
            return _create_weapon_from_data(data)
        # Otros tipos de items aquí
        _:
            return _create_base_item_from_data(data)

# Crear un item base
func _create_base_item_from_data(data: Dictionary) -> Item:
    var item = Item.new()
    
    item.id = data.get("id", "")
    item.name = data.get("name", "Unknown Item")
    item.description = data.get("description", "")
    
    var icon_path = data.get("icon_path", "")
    if icon_path and ResourceLoader.exists(icon_path):
        item.icon = load(icon_path)
    
    item.properties = data.get("properties", {}).duplicate()
    item.item_type = data.get("item_type", "base")
    
    return item

# Crear un arma
func _create_weapon_from_data(data: Dictionary) -> WeaponItem:
    var weapon = WeaponItem.new()
    
    # Propiedades base
    weapon.id = data.get("id", "")
    weapon.name = data.get("name", "Unknown Weapon")
    weapon.description = data.get("description", "")
    
    var icon_path = data.get("icon_path", "")
    if icon_path and ResourceLoader.exists(icon_path):
        weapon.icon = load(icon_path)
    
    weapon.properties = data.get("properties", {}).duplicate()
    weapon.item_type = "weapon"
    
    # Propiedades específicas de armas
    weapon.damage = data.get("damage", 1)
    weapon.attack_speed = data.get("attack_speed", 1.0)
    
    var scene_path = data.get("weapon_scene_path", "")
    if scene_path and ResourceLoader.exists(scene_path):
        weapon.weapon_scene = load(scene_path)
    
    return weapon

# Crear un item duplicando un nodo existente
func create_item_from_node(node: Node) -> Item:
    if not node:
        return null
    
    # Debugear el nodo para ayudar a diagnosticar
    print("ItemFactory: Creando item desde nodo: ", node.name, ", Clase: ", node.get_class())
    
    # Si es una arma
    if node.get_class() == "Weapon" or node.name.begins_with("War") or node.name.begins_with("Sword"):
        print("ItemFactory: Detectado como arma: ", node.name)
        var weapon_item = WeaponItem.new()
        weapon_item.configure_from_weapon_node(node)
        
        # Forzar item_type = "weapon" para asegurar consistencia
        weapon_item.item_type = "weapon"
        
        print("ItemFactory: Creado WeaponItem con item_type = ", weapon_item.item_type)
        return weapon_item
    
    # Para otros tipos, implementar lógica similar
    
    # Fallback a item genérico
    var item = Item.new()
    item.id = node.name
    item.name = node.name
    
    if node.has_method("get_texture"):
        item.icon = node.get_texture()
    
    return item