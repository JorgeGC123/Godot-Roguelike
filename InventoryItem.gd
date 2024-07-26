extends TextureRect

onready var border: ReferenceRect = get_node("ReferenceRect")
onready var is_instanced_from_inventory = false

func _ready():
	set_mouse_filter(Control.MOUSE_FILTER_PASS)

func initialize(texture: Texture) -> void:
	self.texture = texture

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
