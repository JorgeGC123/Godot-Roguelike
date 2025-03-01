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
onready var inventory: HBoxContainer = get_node("PanelContainer/Inventory")

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
	for child in inventory.get_children():
		child.queue_free()
	
	# Si tenemos acceso al InventoryManager
	if inventory_manager:
		var player_inventory = inventory_manager.get_inventory(inventory_manager.PLAYER_INVENTORY)
		if player_inventory:
			# Obtener todos los items del inventario
			var equipped_index = SavedData.equipped_weapon_index
			
			# Crear una representación visual para cada arma
			for i in range(player_inventory.capacity):
				var item = player_inventory.get_item(i)
				if item and item.item_type == "weapon":
					var item_display = TextureRect.new()
					item_display.expand = true
					item_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					item_display.rect_min_size = Vector2(32, 32)
					
					# Establecer la textura
					if item.icon:
						item_display.texture = item.icon
					
					# Añadir al inventario
					inventory.add_child(item_display)
					
					# Marcar como seleccionado si es el arma actual
					if i == equipped_index:
						# Simulamos la selección visual (adaptarla según tu implementación)
						item_display.modulate = Color(1.2, 1.2, 1.2)  # Highlight

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
		# Aquí podríamos manejar la selección visual directa
		pass
