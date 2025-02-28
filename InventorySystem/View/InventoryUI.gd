class_name InventoryUI
extends Control

signal inventory_closed
signal item_selected(item, index)
signal item_used(item, index)

export(PackedScene) var slot_scene: PackedScene
export(NodePath) var grid_container_path
export(NodePath) var close_button_path

var inventory_model: InventoryModel
var slots: Array = []
var selected_slot_index: int = -1

onready var grid_container = get_node(grid_container_path)
onready var close_button = get_node(close_button_path) if close_button_path else null

var drag_preview: Control = null
var drag_data = null

# Referencias para posicionamiento dinámico
var player_ref = null
var update_timer = null
var last_player_pos = Vector2.ZERO  # Última posición del jugador
var repositioning_threshold = 100  # Distancia mínima en píxeles para reposicionar

func _ready():
	# Conectar señales del botón de cierre si existe
	if close_button:
		close_button.connect("pressed", self, "_on_CloseButton_pressed")
	
	# Inicializar el drag preview
	_setup_drag_preview()
	
	# Configura un timer para actualizar la posición del inventario
	update_timer = Timer.new()
	update_timer.wait_time = 0.1  # 100ms
	update_timer.one_shot = false
	update_timer.autostart = false
	update_timer.connect("timeout", self, "_update_position")
	add_child(update_timer)
	
	# Buscar al jugador
	call_deferred("_find_player")

# Configurar la vista con un modelo de inventario
func setup(model: InventoryModel):
	inventory_model = model
	
	# Conectar señales del modelo
	inventory_model.connect("item_added", self, "_on_item_added")
	inventory_model.connect("item_removed", self, "_on_item_removed")
	inventory_model.connect("items_swapped", self, "_on_items_swapped")
	inventory_model.connect("inventory_updated", self, "_on_inventory_updated")
	
	# Inicializar slots UI
	_initialize_slots()

# Inicializar slots
func _initialize_slots():
	# Limpiar slots existentes
	for slot in slots:
		slot.queue_free()
	slots.clear()
	
	# Crear nuevos slots
	for i in range(inventory_model.capacity):
		var slot_ui = slot_scene.instance()
		grid_container.add_child(slot_ui)
		slots.append(slot_ui)
		
		# Configurar slot
		slot_ui.index = i
		slot_ui.connect("gui_input", self, "_on_Slot_gui_input", [i])
		
		# Conexiones específicas para drag & drop
		slot_ui.connect("item_dropped", self, "_on_item_dropped")
		
		# Asignar item si existe
		var item = inventory_model.get_item(i)
		if item:
			slot_ui.set_item(item)
	
	# Ajustar el número de columnas para una cuadrícula más estética
	# Si tenemos menos de 10 slots, usamos menos columnas
	if grid_container.get_child_count() <= 5:
		grid_container.columns = 3
	elif grid_container.get_child_count() <= 12:
		grid_container.columns = 4
	else:
		grid_container.columns = 5
	
	print("Initialized ", slots.size(), " slots with ", grid_container.columns, " columns")

# Función para manejar drops entre slots
func _on_item_dropped(source_index, target_index):
	print("InventoryUI: Dropping item from slot ", source_index, " to slot ", target_index)
	
	# Verificar índices válidos
	if source_index < 0 or source_index >= inventory_model.capacity or target_index < 0 or target_index >= inventory_model.capacity:
		print("InventoryUI: Invalid slot indices")
		return
		
	# Intentar intercambiar en el modelo
	var success = inventory_model.swap_items(source_index, target_index)
	
	# Actualizar UI si fue exitoso
	if success:
		print("InventoryUI: Swap successful")
		# La actualización visual la maneja el modelo a través de señales
	else:
		print("InventoryUI: Swap failed")
		# Podríamos agregar una animación o feedback visual aquí

# Actualizar visualmente todos los slots
func refresh():
	for i in range(slots.size()):
		var item = inventory_model.get_item(i) if i < inventory_model.capacity else null
		slots[i].set_item(item)

# Mostrar el inventario
func show_inventory():
	refresh()
	
	# Asegurar que la UI esté por encima de todo
	var parent = get_parent()
	if parent:
		parent.move_child(self, parent.get_child_count() - 1)
	
	# Asegurar que estamos usando un CanvasLayer con alto layer si es necesario
	var current_parent = get_parent()
	if current_parent is CanvasLayer:
		current_parent.layer = 100
	
	# Hacer visible
	visible = true
	
	# Centrar en el jugador (forzar posicionamiento inicial)
	_center_on_player(true)
	
	# Iniciar seguimiento al jugador (solo para movimientos significativos)
	if update_timer:
		update_timer.start()

# Ocultar el inventario
func hide_inventory():
	# Detener el timer de actualización
	if update_timer and update_timer.is_inside_tree() and update_timer.is_processing():
		update_timer.stop()
	
	visible = false
	emit_signal("inventory_closed")

# Seleccionar un slot
func select_slot(index: int):
	# Deseleccionar slot previo
	if selected_slot_index != -1 and selected_slot_index < slots.size():
		slots[selected_slot_index].deselect()
	
	# Seleccionar nuevo slot
	selected_slot_index = index
	if index != -1 and index < slots.size():
		slots[index].select()
		
		# Emitir señal con el item seleccionado
		var item = inventory_model.get_item(index)
		emit_signal("item_selected", item, index)

# Configurar el preview de drag and drop
func _setup_drag_preview():
	drag_preview = TextureRect.new()
	drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_preview.visible = false
	add_child(drag_preview)

# Manejar entrada en los slots
func _on_Slot_gui_input(event, slot_index):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				# Seleccionar slot
				select_slot(slot_index)
			elif event.doubleclick:
				# Usar item (doble clic)
				var item = inventory_model.get_item(slot_index)
				if item and item.can_use():
					item.use()
					emit_signal("item_used", item, slot_index)

# Handlers para señales del modelo de inventario
func _on_item_added(item, slot_index):
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].set_item(item)

func _on_item_removed(item, slot_index):
	if slot_index >= 0 and slot_index < slots.size():
		slots[slot_index].clear_item()

func _on_items_swapped(from_index, to_index):
	if from_index >= 0 and from_index < slots.size() and to_index >= 0 and to_index < slots.size():
		var from_item = inventory_model.get_item(from_index)
		var to_item = inventory_model.get_item(to_index)
		slots[from_index].set_item(to_item)
		slots[to_index].set_item(from_item)

func _on_inventory_updated():
	refresh()

func _on_CloseButton_pressed():
	hide_inventory()

# Encuentra al jugador en la escena
func _find_player():
	# Esperar un frame para asegurarnos que todo esté inicializado
	yield(get_tree(), "idle_frame")
	
	# Buscar jugador en grupo "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = weakref(players[0])
		print("InventoryUI: Player found")
		return
	
	# Si no está en el grupo, buscar por nombre
	var player_candidates = ["Player", "player", "Character", "character"]
	var root = get_tree().get_root()
	
	for candidate in player_candidates:
		var player_node = _find_node_by_name(root, candidate)
		if player_node:
			player_ref = weakref(player_node)
			print("InventoryUI: Player found by name: ", candidate)
			return
	
	print("InventoryUI: Player not found")

# Busca un nodo por nombre recursivamente
func _find_node_by_name(node, name):
	if node.get_name().to_lower() == name.to_lower():
		return node
	
	for child in node.get_children():
		var result = _find_node_by_name(child, name)
		if result:
			return result
	
	return null

# Centra el inventario en el jugador
func _center_on_player(force_update=false):
	if not player_ref or not player_ref.get_ref():
		_find_player()
		return
	
	var player = player_ref.get_ref()
	if not player:
		return
	
	# Obtener el centro de control
	var center_container = $CenterContainer
	if not center_container:
		return
	
	# Obtener el panel
	var panel = center_container.get_node("Panel")
	if not panel:
		return
	
	# Obtener posición global del jugador
	var player_global_pos
	if player.has_method("get_global_position"):
		player_global_pos = player.get_global_position()
	elif player.get("global_position") != null:
		player_global_pos = player.global_position
	elif player.get("position") != null:
		player_global_pos = player.position
	else:
		return
	
	# Comprobar si el jugador se ha movido lo suficiente como para reposicionar
	if not force_update:
		var viewport = get_viewport()
		if not viewport:
			return
		
		# Convertir posición global actual a posición de pantalla
		var current_screen_pos = viewport.canvas_transform.xform(player_global_pos)
		
		# Si no tenemos una posición anterior guardada o si es la primera vez
		if last_player_pos == Vector2.ZERO:
			last_player_pos = current_screen_pos
			force_update = true  # Forzar actualización la primera vez
		else:
			# Calcular la distancia que se ha movido el jugador en coordenadas de pantalla
			var distance = last_player_pos.distance_to(current_screen_pos)
			
			# Solo reposicionar si se ha movido más de la distancia umbral
			if distance < repositioning_threshold:
				return  # No reposicionar si no se ha movido lo suficiente
			
			# Actualizar la última posición conocida
			last_player_pos = current_screen_pos
	
	# Convertir a posición de pantalla
	var viewport = get_viewport()
	if not viewport:
		return
	
	var player_screen_pos = viewport.canvas_transform.xform(player_global_pos)
	
	# Centrar el panel en la posición del jugador
	# El CenterContainer debe centrarse automáticamente si su posición global se establece correctamente
	var panel_size = panel.rect_size
	var offset = Vector2(panel_size.x/2, panel_size.y/2)
	
	# Ajustar la posición global del control principal para centrar el panel
	rect_global_position = player_screen_pos - offset
	
	# Asegurar que el panel no se salga de la pantalla
	var viewport_size = viewport.size
	var panel_rect = Rect2(rect_global_position, panel_size)
	
	# Ajustar horizontalmente
	if panel_rect.position.x < 0:
		rect_global_position.x = 0
	elif panel_rect.end.x > viewport_size.x:
		rect_global_position.x = viewport_size.x - panel_size.x
	
	# Ajustar verticalmente
	if panel_rect.position.y < 0:
		rect_global_position.y = 0
	elif panel_rect.end.y > viewport_size.y:
		rect_global_position.y = viewport_size.y - panel_size.y


# Actualiza la posición del inventario (llamado por timer)
func _update_position():
	if visible:
		_center_on_player(false)  # Solo actualizar si el jugador se mueve significativamente
