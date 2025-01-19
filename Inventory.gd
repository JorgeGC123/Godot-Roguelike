extends CanvasLayer

signal inventory_closed

const INVENTORY_ITEM_SCENE: PackedScene = preload("res://InventoryItem.tscn")
const MAX_SLOTS = 25

var items = []

onready var control: Control = $Control
onready var grid: GridContainer = $Control/CenterContainer/Panel/VBoxContainer/InventoryGrid

func _ready():
	initialize_inventory()
	load_items()
	control.hide()

func initialize_inventory():
	for i in range(MAX_SLOTS):
		var item = INVENTORY_ITEM_SCENE.instance()
		# Conectar la señal de drop para cada item
		item.connect("item_dropped", self, "_on_Item_dropped")
		grid.add_child(item)
		items.append(null)

func _on_Item_dropped(source_index: int, target_index: int) -> void:
	if source_index == target_index:
		return

	# Obtener referencias a los slots visuales
	var source_slot = grid.get_child(source_index)
	var target_slot = grid.get_child(target_index)

	# Guardar las texturas actuales
	var source_texture = source_slot.texture
	var target_texture = target_slot.texture

	# Intercambiar los items en el array
	var temp_item = items[source_index]
	items[source_index] = items[target_index]
	items[target_index] = temp_item

	# Actualizar las texturas
	source_slot.texture = target_texture
	target_slot.texture = source_texture

func load_items():
	var saved_items = SavedData.weapons
	for i in range(min(saved_items.size(), MAX_SLOTS)):
		add_item(saved_items[i])

func add_item(item):
	for i in range(MAX_SLOTS):
		if items[i] == null:
			items[i] = item
			grid.get_child(i).initialize(item.get_texture())
			return true
	return false

func remove_item(index):
	if index >= 0 and index < MAX_SLOTS and items[index] != null:
		var item = items[index]
		items[index] = null
		grid.get_child(index).texture = null
		SavedData.remove_item(item)
		return item
	return null

func show_inventory():
	print("Showing inventory")
	control.show()
	print("Inventory visibility: ", control.visible)

func hide_inventory():
	print("Hiding inventory")
	control.hide()
	print("Inventory visibility: ", control.visible)

func _on_CloseButton_pressed():
	print("Close button pressed")
	emit_signal("inventory_closed")
	hide_inventory()
