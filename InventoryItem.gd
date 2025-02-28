extends TextureRect
# Archivo de compatibilidad para el sistema antiguo
# Redirige al nuevo sistema de inventario

signal item_dropped(source_index, target_index)

func _ready():
	# No hace nada, solo proporciona compatibilidad de API
	pass

func initialize(texture: Texture) -> void:
	self.texture = texture

# Estos métodos ya no son necesarios pero se mantienen para compatibilidad
func select() -> void:
	pass

func deselect() -> void:
	pass

func highlight() -> void:
	pass

func unhighlight() -> void:
	pass

func _on_ReferenceRect_mouse_entered():
	pass

func _on_ReferenceRect_mouse_exited():
	pass
