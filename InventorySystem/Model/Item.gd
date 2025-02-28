class_name Item
extends Resource

export(String) var id: String
export(String) var name: String
export(String, MULTILINE) var description: String
export(Texture) var icon: Texture
export(Dictionary) var properties: Dictionary = {}
export(String) var item_type: String = "base"

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_icon = null):
    id = p_id
    name = p_name
    description = p_description
    icon = p_icon

# Método para serializar el item
func serialize() -> Dictionary:
    return {
        "id": id,
        "name": name,
        "description": description,
        "icon_path": icon.resource_path if icon else "",
        "properties": properties,
        "item_type": item_type
    }

# Método para aplicar el uso del item
# Las clases hijas deben sobreescribir este método
func use(user = null):
    push_warning("Base item use() called. This should be overridden.")
    return false

# Método para verificar si el item puede ser usado
func can_use(user = null) -> bool:
    return false

# Método para clonar el item
func duplicate_item() -> Item:
    var new_item = get_script().new()
    new_item.id = id
    new_item.name = name
    new_item.description = description
    new_item.icon = icon
    new_item.properties = properties.duplicate(true)
    new_item.item_type = item_type
    return new_item

# Obtener el valor de una propiedad específica
func get_property(property_name: String, default_value = null):
    return properties.get(property_name, default_value)

# Establecer una propiedad
func set_property(property_name: String, value) -> void:
    properties[property_name] = value