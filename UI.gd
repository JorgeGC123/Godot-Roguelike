extends CanvasLayer

# Ya no necesitamos el antiguo InventoryItem porque usamos el nuevo sistema
# const INVENTORY_ITEM_SCENE: PackedScene = preload("res://InventoryItem.tscn")

const MIN_HEALTH: int = 23

var max_hp: int = 4
var max_stamina: int = 100

onready var player: KinematicBody2D = get_parent().get_node("Player")
onready var health_bar: TextureProgress = get_node("HealthBar")
onready var health_bar_tween: Tween = get_node("HealthBar/Tween")
onready var stamina_bar: TextureProgress = get_node("StaminaBar")
onready var stamina_bar_tween: Tween = get_node("StaminaBar/Tween")
onready var portrait: Sprite = get_node("Sprite")
onready var weapons_inventory: HBoxContainer = get_node("PanelContainer/VBoxContainer/Inventory")
onready var consumables_container: HBoxContainer = get_node("PanelContainer/VBoxContainer/Consumables")

# Referencia al nuevo sistema de inventario
var inventory_manager

func _ready() -> void:
	# Configurar el retrato del jugador
	var current_skin = SavedData.skin
	var base_path = "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/portrait_{0}/".format([current_skin])
	var texture_path = base_path + "{0}.png".format([current_skin])
	portrait.scale = Vector2(0.25,0.25)
	portrait.texture = load(texture_path)
	
	# Configurar barras de salud y resistencia
	max_hp = player.max_hp
	_update_health_bar(100)
	max_stamina = player.max_stamina
	_update_stamina_bar(100)
	
	# Conectar con el nuevo sistema de inventario
	_connect_to_new_inventory_system()
	
	# Actualizar la representación visual de las armas actuales
	_populate_inventory_display()

# Conectar a las señales del nuevo sistema de inventario
func _connect_to_new_inventory_system() -> void:
	if has_node("/root/InventoryManager"):
		inventory_manager = get_node("/root/InventoryManager")
		
		# Conectar señales relevantes
		if not inventory_manager.is_connected("active_inventory_changed", self, "_on_active_inventory_changed"):
			inventory_manager.connect("active_inventory_changed", self, "_on_active_inventory_changed")
		
		# Conectar señales del controlador de visualización del inventario
		if has_node("/root/InventoryDisplayManager"):
			var display_manager = get_node("/root/InventoryDisplayManager")
			
			if not display_manager.is_connected("item_selected", self, "_on_inventory_item_selected"):
				display_manager.connect("item_selected", self, "_on_inventory_item_selected")

# Poblar la interfaz de usuario con los items actuales del inventario
func _populate_inventory_display() -> void:
	# Limpiar la visualización anterior
	for child in weapons_inventory.get_children():
		child.queue_free()
	
	# Limpiar visualización de consumibles
	if consumables_container:
		for child in consumables_container.get_children():
			child.queue_free()
	
	# Asegurarnos de que el contenedor existe
	if not consumables_container:
		# El contenedor debería existir, pero por si acaso...
		consumables_container = HBoxContainer.new()
		consumables_container.name = "Consumables"
		consumables_container.alignment = BoxContainer.ALIGN_CENTER
		var vbox = get_node("PanelContainer/VBoxContainer")
		if vbox:
			vbox.add_child(consumables_container)
		else:
			# Si no hay VBoxContainer, crear la estructura completa
			var vbox_container = VBoxContainer.new()
			vbox_container.name = "VBoxContainer"
			get_node("PanelContainer").add_child(vbox_container)
			vbox_container.add_child(consumables_container)
	
	# Si tenemos acceso al InventoryManager
	if inventory_manager:
		var player_inventory = inventory_manager.get_inventory(inventory_manager.PLAYER_INVENTORY)
		if player_inventory:
			# Obtener todos los items del inventario
			var equipped_index = SavedData.equipped_weapon_index
			
			# === VISUALIZACIÓN DE ARMAS ===
			# Obtener todas las armas del inventario
			var weapons = inventory_manager.get_items_by_type("weapon")
			
			# Crear una representación visual para cada arma
			for weapon_data in weapons:
				var item = weapon_data.item
				var index = weapon_data.index
				
				var item_display = TextureRect.new()
				item_display.expand = true
				item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				item_display.rect_min_size = Vector2(32, 32)
				item_display.hint_tooltip = item.name # Añadir tooltip con el nombre
				
				# Guardar referencia al item y su índice para uso en eventos
				item_display.set_meta("item", item)
				item_display.set_meta("index", index)
				
				# Conectar señales de ratón para interacción
				item_display.connect("gui_input", self, "_on_item_gui_input", [item, index])
				
				# Establecer la textura
				if item.icon:
					item_display.texture = item.icon
				
				# Añadir borde para mejorar visibilidad
				var border = ColorRect.new()
				border.color = Color(0.3, 0.3, 0.3, 0.5)
				border.mouse_filter = Control.MOUSE_FILTER_IGNORE # El ratón ignorará este control
				border.rect_position = Vector2(-1, -1)
				border.rect_size = Vector2(item_display.rect_min_size.x + 2, item_display.rect_min_size.y + 2)
				item_display.add_child(border)
				
				# Añadir al inventario
				weapons_inventory.add_child(item_display)
				
				# Marcar como seleccionado si es el arma actual
				if index == equipped_index:
					# Añadir un indicador de selección más visible
					border.color = Color(1.0, 0.8, 0.0, 0.8) # Borde dorado para el arma equipada
					item_display.modulate = Color(1.2, 1.2, 1.2)  # Highlight
			
			# === VISUALIZACIÓN DE CONSUMIBLES ===
			# Obtener todos los consumibles del inventario
			var consumables = inventory_manager.get_items_by_type("consumable")
			
			# Crear una representación visual para cada consumible
			for consumable_data in consumables:
				var item = consumable_data.item
				var index = consumable_data.index
				
				var item_display = TextureRect.new()
				item_display.expand = true
				item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				item_display.rect_min_size = Vector2(30, 30)
				item_display.hint_tooltip = item.name + "\n" + item.description # Añadir tooltip más detallado
				
				# Guardar referencia al item y su índice para uso en eventos
				item_display.set_meta("item", item)
				item_display.set_meta("index", index)
				
				# Conectar señales de ratón para interacción
				item_display.connect("gui_input", self, "_on_consumable_gui_input", [item, index])
				
				# Establecer la textura
				if item.icon:
					item_display.texture = item.icon
				
				# Añadir borde para mejorar visibilidad - verde para consumibles
				var border = ColorRect.new()
				border.color = Color(0.2, 0.5, 0.2, 0.5)
				border.mouse_filter = Control.MOUSE_FILTER_IGNORE
				border.rect_position = Vector2(-1, -1)
				border.rect_size = Vector2(item_display.rect_min_size.x + 2, item_display.rect_min_size.y + 2)
				item_display.add_child(border)
				
				# Añadir al contenedor de consumibles
				consumables_container.add_child(item_display)

# Actualizar la barra de salud
func _update_health_bar(new_value: int) -> void:
	var __ = health_bar_tween.interpolate_property(health_bar, "value", health_bar.value, new_value, 0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
	__ = health_bar_tween.start()

# Actualizar la barra de resistencia 
func _update_stamina_bar(new_value: int) -> void:
	var __ = stamina_bar_tween.interpolate_property(stamina_bar, "value", stamina_bar.value, new_value, 0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
	__ = stamina_bar_tween.start()

# Manejar cambios de HP
func _on_Player_hp_changed(new_hp: int) -> void:
	var new_health: int = int((100 - MIN_HEALTH) * float(new_hp) / max_hp) + MIN_HEALTH
	_update_health_bar(new_health)

# Manejar cambios de stamina
func _on_Player_stamina_changed(new_st: int) -> void:
	var new_stamina: int = int((100 - MIN_HEALTH) * float(new_st) / max_stamina) + MIN_HEALTH
	_update_stamina_bar(new_stamina)

# Manejar el cambio de arma seleccionada (compatible con el sistema anterior)
func _on_Player_weapon_switched(prev_index: int, new_index: int) -> void:
	# Actualizar toda la representación visual del inventario
	_populate_inventory_display()

# Manejar interacción con un item de arma
func _on_item_gui_input(event: InputEvent, item: Item, index: int) -> void:
	# Si es un click izquierdo, seleccionar el arma
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if SavedData.equipped_weapon_index != index:
			# Cambiar el arma equipada
			var prev_index = SavedData.equipped_weapon_index
			SavedData.equipped_weapon_index = index
			
			# Notificar al jugador del cambio
			if player and player.has_method("switch_weapon"):
				player.switch_weapon(prev_index, index)
			
			# Actualizar la visualización
			_populate_inventory_display()

# Manejar interacción con un consumible
func _on_consumable_gui_input(event: InputEvent, item: Item, index: int) -> void:
	# Si es un click izquierdo, intentar usar el consumible
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if item and item is ConsumableItem and item.can_use(player):
			# Usar el consumible
			var success = item.use(player)
			
			# Si se usó completamente (uses_left == 0), quitarlo del inventario
			if success and item.uses_left <= 0:
				if inventory_manager:
					inventory_manager.remove_item_from_active(index)
					
			# Actualizar la visualización en todos los casos
			_populate_inventory_display()

# Manejar cuando se recoge un arma (compatible con el sistema anterior)
func _on_Player_weapon_picked_up(weapon_texture: Texture) -> void:
	# Actualizar toda la representación visual del inventario
	_populate_inventory_display()

# Manejar cuando se descarta un arma (compatible con el sistema anterior)
func _on_Player_weapon_droped(index: int) -> void:
	# Actualizar toda la representación visual del inventario
	_populate_inventory_display()

# === Nuevos manejadores para el sistema de inventario actualizado ===

# Cuando cambia el inventario activo
func _on_active_inventory_changed(old_id: String, new_id: String) -> void:
	_populate_inventory_display()

# Cuando se selecciona un item en el inventario
func _on_inventory_item_selected(item, index: int) -> void:
	# Actualizar la selección visual si es necesario
	if item and item.item_type == "weapon":
		# Cambiar al arma seleccionada
		if SavedData.equipped_weapon_index != index:
			var prev_index = SavedData.equipped_weapon_index
			SavedData.equipped_weapon_index = index
			
			# Notificar al jugador del cambio
			if player and player.has_method("switch_weapon"):
				player.switch_weapon(prev_index, index)
			
			# Actualizar la visualización
			_populate_inventory_display()
			
	elif item and item.item_type == "consumable":
		# Intentar usar el consumible
		if item.can_use(player):
			var success = item.use(player)
			
			# Si se usó completamente, quitarlo del inventario
			if success and item.uses_left <= 0:
				if inventory_manager:
					inventory_manager.remove_item_from_active(index)
					
			# Actualizar la visualización
			_populate_inventory_display()

# Cuando se equipa un item en el inventario
func _on_inventory_item_equipped(item, index: int, equipment_type: String) -> void:
	# Manejar equipamiento según el tipo
	if equipment_type == "weapon":
		# El cambio ya se ha actualizado en SavedData, solo necesitamos actualizar la UI
		_populate_inventory_display()
		
	# Aquí se puede añadir manejo para otros tipos de equipamiento en el futuro
	# elif equipment_type == "armor":
	#     # Manejar equipamiento de armadura
	
	# Actualizamos la visualización de la UI
	_populate_inventory_display()
