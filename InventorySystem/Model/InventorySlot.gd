class_name InventorySlot
extends Resource

signal item_changed(old_item, new_item)

var item: Item = null

# Verificar si el slot está vacío
func is_empty() -> bool:
    return item == null

# Obtener el item actual
func get_item() -> Item:
    return item

# Establecer un nuevo item
func set_item(new_item: Item) -> void:
    var old_item = item
    item = new_item
    emit_signal("item_changed", old_item, new_item)

# Limpiar el slot
func clear() -> void:
    var old_item = item
    item = null
    emit_signal("item_changed", old_item, null)