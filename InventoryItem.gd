extends TextureRect

signal item_dropped(source_index, target_index)

onready var border: ReferenceRect = get_node("ReferenceRect")
var grid_index: int = -1  # Para mantener track de su posición

func _ready():
	set_mouse_filter(Control.MOUSE_FILTER_PASS)
	# Obtener el índice del item en el grid
	if get_parent().name == "InventoryGrid":
		grid_index = get_index()

func initialize(texture: Texture) -> void:
	self.texture = texture

func get_drag_data(_position: Vector2):
	# Solo permitir drag si hay una textura
	if texture == null:
		return null

	# Crear preview
	var preview = TextureRect.new()
	preview.texture = texture
	preview.modulate = Color(1, 1, 1, 0.7)

	# Centrar el preview
	var control = Control.new()
	control.add_child(preview)
	preview.rect_position = -preview.rect_size / 2

	set_drag_preview(control)

	# Retornar los datos necesarios
	return {
		"source_texture": texture,
		"source_index": grid_index
	}

func can_drop_data(_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("source_texture")

func drop_data(_position: Vector2, data) -> void:
	# Emitir señal con los índices para que Inventory.gd maneje el intercambio
	emit_signal("item_dropped", data.source_index, grid_index)

func select() -> void:
	border.show()

func deselect() -> void:
	border.hide()

func highlight() -> void:
	if get_parent().name == "InventoryGrid":
		modulate = Color(1, 1, 0.5)  # Resalta en amarillo

func unhighlight() -> void:
	if get_parent().name == "InventoryGrid":
		modulate = Color(1, 1, 1)  # Resetea a color original

func _on_ReferenceRect_mouse_entered():
	highlight()

func _on_ReferenceRect_mouse_exited():
	unhighlight()
