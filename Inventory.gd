extends CanvasLayer
# Archivo de compatibilidad para el sistema antiguo
# Redirige al nuevo sistema de inventario

signal inventory_closed

const MAX_SLOTS = 25

func _ready():
	# Conectar señal del sistema nuevo
	if has_node("/root/InventoryDisplayManager"):
		InventoryDisplayManager.connect("inventory_closed", self, "_on_inventory_closed_callback")

# Función de reenvío de señal
func _on_inventory_closed_callback():
	emit_signal("inventory_closed")

# Métodos de compatibilidad que redirigen al nuevo sistema
func add_item(item):
	if has_node("/root/InventoryManager") and has_node("/root/ItemFactory"):
		var item_data = ItemFactory.create_item_from_node(item)
		return InventoryManager.add_item_to_active(item_data)
	return false

func remove_item(index: int):
	# Este método es más difícil de mapear directamente
	# Puede que necesites adaptarlo según tus necesidades específicas
	if has_node("/root/InventoryManager"):
		var inventory = InventoryManager.get_active_inventory()
		if inventory:
			return inventory.remove_item(index)
	return null

func show_inventory():
	if has_node("/root/InventoryDisplayManager"):
		InventoryDisplayManager.show_inventory()

func hide_inventory():
	if has_node("/root/InventoryDisplayManager"):
		InventoryDisplayManager.hide_inventory()

func _on_CloseButton_pressed():
	hide_inventory()
