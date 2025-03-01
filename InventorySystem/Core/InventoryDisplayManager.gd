extends Node

# Esta clase actúa como interfaz global para mostrar/ocultar el inventario
# Evita dependencias circulares al instanciar la UI bajo demanda

# Referencias
var inventory_ui_scene = preload("res://InventorySystem/View/InventoryUI.tscn")
var inventory_ui_instance = null
var player_ref = null

signal inventory_opened
signal inventory_closed
signal item_selected(item, index)
signal weapon_equipped(item, index)

func _ready():
	# Buscar el jugador - esto podría hacerse después en _process si el jugador no está disponible al inicio
	call_deferred("_find_player")

func _find_player():
	# Esperar un frame para asegurarnos de que la escena esté completamente cargada
	yield(get_tree(), "idle_frame")
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = weakref(players[0])
		print("InventoryDisplayManager: Player found")


func _process(_delta):
	# Si no tenemos referencia al jugador, intentar encontrarlo
	if player_ref == null or not player_ref.get_ref():
		_find_player()
		return

func show_inventory():
	print("InventoryDisplayManager: show_inventory llamado")
	# Crear UI si no existe
	if inventory_ui_instance == null:
		print("InventoryDisplayManager: Creando nueva instancia de UI")
		# Crear un nuevo CanvasLayer para asegurar que esté por encima de todo
		var ui_layer = CanvasLayer.new()
		ui_layer.layer = 100  # Layer alto para estar al frente
		ui_layer.name = "InventoryCanvasLayer"  # Nombrar para facilitar depuración
		get_tree().root.add_child(ui_layer)
		
		# Instanciar la UI en el CanvasLayer
		inventory_ui_instance = inventory_ui_scene.instance()
		ui_layer.add_child(inventory_ui_instance)
		print("InventoryDisplayManager: UI instanciada y añadida al CanvasLayer")
		
		# Configurar señales
		inventory_ui_instance.connect("inventory_closed", self, "_on_inventory_closed")
		inventory_ui_instance.connect("item_selected", self, "_on_item_selected")
		inventory_ui_instance.connect("weapon_equipped", self, "_on_weapon_equipped")
		
		# Configurar UI con el inventario del jugador
		if InventoryManager.has_method("get_inventory"):
			var player_inventory = InventoryManager.get_inventory(InventoryManager.PLAYER_INVENTORY)
			if player_inventory:
				inventory_ui_instance.setup(player_inventory)
				print("InventoryDisplayManager: UI configured with player inventory")
		else:
			print("InventoryDisplayManager: Could not get player inventory")
		
		# Hacer visible el inventario (esto también inicia el posicionamiento)
		inventory_ui_instance.show_inventory()
	else:
		print("InventoryDisplayManager: usando instancia existente de UI")
		# Si ya existe, asegurar que esté al frente
		var parent = inventory_ui_instance.get_parent()
		if parent is CanvasLayer:
			parent.layer = 100
		
		# Solo mostrar si no está visible
		if not inventory_ui_instance.visible:
			print("InventoryDisplayManager: mostrando UI existente")
			inventory_ui_instance.show_inventory()
		else:
			print("InventoryDisplayManager: UI ya está visible")
	
	emit_signal("inventory_opened")

func hide_inventory():
	print("InventoryDisplayManager: hide_inventory llamado")
	if inventory_ui_instance != null:
		if inventory_ui_instance.visible:
			print("InventoryDisplayManager: ocultando UI")
			inventory_ui_instance.hide_inventory()
		else:
			print("InventoryDisplayManager: UI ya está oculta")
	else:
		print("InventoryDisplayManager: No hay inventario para ocultar")
	
	# Emitir señal para asegurar que todos los sistemas se actualizan
	emit_signal("inventory_closed")

func toggle_inventory():
	print("InventoryDisplayManager: toggle_inventory llamado")
	if is_inventory_visible():
		print("InventoryDisplayManager: ocultando inventario")
		hide_inventory()
	else:
		print("InventoryDisplayManager: mostrando inventario")
		show_inventory()

func is_inventory_visible() -> bool:
	var result = inventory_ui_instance != null and inventory_ui_instance.visible
	return result

# Callback para señales
func _on_inventory_closed():
	emit_signal("inventory_closed")
	# get_tree().paused = false

func _on_item_selected(item, index):
	emit_signal("item_selected", item, index)

func _on_weapon_equipped(item, index):
	emit_signal("weapon_equipped", item, index)
	
	# Notificar al jugador del cambio
	var player = _get_player()
	if player and player.has_method("switch_weapon"):
		# Guardar el índice anterior antes de actualizar SavedData
		var prev_index = SavedData.equipped_weapon_index
		
		# El índice actual ya está actualizado en SavedData por el método _on_equip_slot_item_dropped
		# Solo necesitamos notificar al jugador
		player.switch_weapon(prev_index, index)
		print("InventoryDisplayManager: Notificado al jugador del cambio de arma")

# Obtener referencia al jugador
func _get_player():
	if player_ref and player_ref.get_ref():
		return player_ref.get_ref()
	return null

# Función para limpiar/eliminar la UI
func cleanup():
	if inventory_ui_instance != null:
		# Obtener el CanvasLayer padre si existe
		var parent = inventory_ui_instance.get_parent()
		
		# Liberar la instancia de UI
		inventory_ui_instance.queue_free()
		inventory_ui_instance = null
		
		# Si el padre es un CanvasLayer que creamos, también liberarlo
		if parent is CanvasLayer and parent.get_parent() == get_tree().root:
			parent.queue_free()
