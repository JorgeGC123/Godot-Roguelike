extends Character
class_name Player
const DUST_SCENE: PackedScene = preload("res://Characters/Player/Dust.tscn")

enum {UP, DOWN}

var current_weapon: Node2D
var lantern: Lantern
export (PackedScene) var Player
signal weapon_switched(prev_index, new_index)
signal weapon_picked_up(weapon_texture)
signal weapon_droped(index)
signal breakable_picked_up(breakable_node)
signal breakable_dropped(breakable_node)

onready var parent: Node2D = get_parent()
onready var weapons: Node2D = get_node("Weapons")
onready var dust_position: Position2D = get_node("DustPosition")
onready var player_dash: PlayerDash = $PlayerDash
var near_breakable: Node = null
var near_pickable: Node = null
var near_door: Node = null
var near_npc: Node = null
var held_breakable: Node = null 
var breakableScene: Node2D = null

export var DASH_STAMINA = 30

# Método para curar al jugador (usado por las pociones)
func heal(amount: int) -> void:
	self.hp = min(self.hp + amount, max_hp)
	# Puedes añadir efectos visuales o sonidos aquí
	print("Player healed for ", amount, " HP. Current HP: ", self.hp)
	# Actualizar HP en SavedData
	SavedData.hp = self.hp

func _ready() -> void:
	emit_signal("weapon_picked_up", weapons.get_child(0).get_texture())
	update_player_skin(SavedData.skin)
	_restore_previous_state()
	
	# Conectar señales del sistema de inventario
	if not InventoryDisplayManager.is_connected("inventory_closed", self, "_on_inventory_closed"):
		InventoryDisplayManager.connect("inventory_closed", self, "_on_inventory_closed")
	
func _restore_previous_state() -> void:
	self.hp = SavedData.hp
	print(SavedData.weapons)
	for weapon in SavedData.weapons:
		weapon = weapon.duplicate()
		weapon.position = Vector2.ZERO
		weapons.add_child(weapon)
		weapon.hide()
		
		emit_signal("weapon_picked_up", weapon.get_texture())
		emit_signal("weapon_switched", weapons.get_child_count() - 2, weapons.get_child_count() - 1)
		
	current_weapon = weapons.get_child(SavedData.equipped_weapon_index)
	current_weapon.show()
	current_weapon.player=self
	
	emit_signal("weapon_switched", weapons.get_child_count() - 1, SavedData.equipped_weapon_index)
	print(SavedData.items)
	for item in SavedData.items:
		if is_instance_valid(item) and item is Lantern:
			item.set_position(Vector2.ZERO)
			item.following_player = true
			item.set_process(true)
			lantern = item.duplicate()
			lantern.show()
			self.add_child(item)
			SavedData.items.erase(item)


func _process(_delta: float) -> void:
	# Verificar antes de procesar cualquier cosa si el inventario está abierto
	var inventory_open = state_machine.state == state_machine.states.inventory_open or \
						InventoryDisplayManager.is_inventory_visible()
	
	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	var window_size: Vector2 = OS.get_window_size()
	var mouse_pos = get_global_mouse_position()
	$Camera2D.offset_h = (mouse_pos.x - global_position.x) / (window_size.x/2)
	$Camera2D.offset_v = (mouse_pos.y - global_position.y) / (window_size.y/2)
	
	# Siempre actualizamos la orientación del sprite
	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
	
	emit_signal("flip_h_changed", animated_sprite.flip_h)
	
	# Si el inventario está abierto, no procesamos nada más
	if inventory_open:
		return
	
	# Procesamiento normal cuando el inventario está cerrado
	current_weapon.move(mouse_direction)
	
	player_dash._process(_delta)
	if Input.is_action_just_pressed("ui_dodge") and player_dash.is_dash_available() and stamina > DASH_STAMINA and mov_direction != Vector2.ZERO:
		player_dash.start_dash(mov_direction)
		reduce_stamina(DASH_STAMINA)


	if player_dash.is_dashing:
		translate(player_dash.dash_direction * player_dash.dash_speed * _delta)
		

	if Input.is_action_just_pressed("ui_interact"):
		if near_npc and !near_npc.is_talking():
			near_npc.trigger_dialog()
		if near_door and ! near_door.is_open:
			near_door.open()
		else:
			pick_up_breakable(near_breakable) 
		
func get_input() -> void:
	# Verificar si el inventario está abierto
	if state_machine.state == state_machine.states.inventory_open or InventoryDisplayManager.is_inventory_visible():
		# No procesar entradas cuando el inventario está abierto
		mov_direction = Vector2.ZERO
		return
	
	# Verificar si el jugador está realizando un dash
	if player_dash.is_dashing:
		return  # No procesar entradas de movimiento durante el dash

	if near_npc and near_npc.is_talking():
		return

	mov_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		mov_direction += Vector2.DOWN
	if Input.is_action_pressed("ui_left"):
		mov_direction += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		mov_direction += Vector2.RIGHT
	if Input.is_action_pressed("ui_up"):
		mov_direction += Vector2.UP
		
	if not current_weapon.is_busy():
		if Input.is_action_just_released("ui_previous_weapon"):
			_switch_weapon(UP)
		elif Input.is_action_just_released("ui_next_weapon"):
			_switch_weapon(DOWN)
		elif Input.is_action_just_pressed("ui_throw") and held_breakable and is_instance_valid(held_breakable):
			print("throweo el breakable bro")
			_throw_breakable()
		elif Input.is_action_just_pressed("ui_throw") and current_weapon.get_index() != 0:
			_drop_weapon()
		
	current_weapon.get_input()
	
	
func _switch_weapon(direction: int) -> void:
	var prev_index: int = current_weapon.get_index()
	var index: int = prev_index
	if direction == UP:
		index -= 1
		if index < 0:
			index = weapons.get_child_count() - 1
	else:
		index += 1
		if index > weapons.get_child_count() - 1:
			index = 0
			
	current_weapon.hide()
	current_weapon = weapons.get_child(index)
	current_weapon.show()
	current_weapon.player = self
	SavedData.equipped_weapon_index = index
	
	emit_signal("weapon_switched", prev_index, index)
	
	
func pick_up_weapon(weapon: Node2D) -> void:
	# 1. Obtener el nombre base del arma sin sufijos numéricos
	var base_name = weapon.name.rstrip("0123456789")
	
	# 2. Generar un nombre único para esta instancia de arma
	# Contar cuántas armas del mismo tipo ya tenemos
	var count = 0
	for w in weapons.get_children():
		if w.name.begins_with(base_name):
			count += 1
	
	# Asignar un sufijo numérico si ya tenemos alguna del mismo tipo
	var unique_name = base_name
	if count > 0:
		unique_name = base_name + str(count)
	
	# Asignar el nombre único al arma
	weapon.name = unique_name
	
	# 3. Convertir el nodo de arma a un WeaponItem usando ItemFactory
	var weapon_item = ItemFactory.create_item_from_node(weapon)
	
	# 4. Añadir el WeaponItem al inventario
	var added_to_inventory = false
	if has_node("/root/InventoryManager"):
		var inventory_manager = get_node("/root/InventoryManager")
		added_to_inventory = inventory_manager.add_item_to_active(weapon_item)
	
	if not added_to_inventory:
		# Falló, usar el método antiguo como fallback
		SavedData.weapons.append(weapon.duplicate())
	else:
		# Sincronizar con SavedData para retrocompatibilidad
		SavedData.weapons.append(weapon.duplicate())
	
	# 5. Manejar la parte visual/mecánica
	var prev_index: int = SavedData.equipped_weapon_index
	var new_index: int = weapons.get_child_count()
	SavedData.equipped_weapon_index = new_index
	
	# Agregar el arma como hijo de weapons
	weapon.get_parent().call_deferred("remove_child", weapon)
	weapons.call_deferred("add_child", weapon)
	weapon.set_deferred("owner", weapons)
	
	# Mostrar la nueva arma
	current_weapon.hide()
	current_weapon.cancel_attack()
	current_weapon = weapon
	current_weapon.player = self
	
	# Emitir señales para la UI
	emit_signal("weapon_picked_up", weapon.get_texture())
	emit_signal("weapon_switched", prev_index, new_index)

# Método para recoger consumibles (pociones, etc.)
func pick_up_consumable(consumable_node: Node2D) -> void:
	print("Player: Recogiendo consumible ", consumable_node.name)
	
	# 1. Generar un nombre único para el consumible
	var base_name = consumable_node.name
	
	# Contar cuántos consumibles de este tipo ya tenemos en el inventario
	var count = 0
	if InventoryManager:
		var player_inventory = InventoryManager.get_inventory(InventoryManager.PLAYER_INVENTORY)
		if player_inventory:
			for i in range(player_inventory.capacity):
				var item = player_inventory.get_item(i)
				if item and item.item_type == "consumable" and item.name.begins_with(base_name):
					count += 1
	
	# Asignar un sufijo numérico si ya tenemos alguno del mismo tipo
	var unique_name = base_name
	if count > 0:
		unique_name = base_name + str(count)
	
	print("Player: Asignando nombre único al consumible: ", unique_name)
	
	# 2. Convertir el nodo a un ConsumableItem
	var consumable_item = ItemFactory.create_item_from_node(consumable_node)
	
	# 3. Establecer el nombre único
	if consumable_item:
		consumable_item.name = unique_name
		
		# 4. Añadir el item al inventario
		var added_to_inventory = false
		if has_node("/root/InventoryManager"):
			var inventory_manager = get_node("/root/InventoryManager")
			added_to_inventory = inventory_manager.add_item_to_active(consumable_item)
			print("Player: Item añadido al inventario: ", added_to_inventory)
		
		# 5. Añadir a SavedData para compatibilidad
		if not added_to_inventory:
			SavedData.items.append(consumable_item)
	
	# 6. Eliminar el nodo original del mundo
	consumable_node.queue_free()

func pick_up_breakable(breakable: Node) -> void:
	if held_breakable and is_instance_valid(held_breakable):
		var current_orbit_position = held_breakable.global_position
		remove_child(held_breakable)
		breakableScene.add_child(held_breakable)
		held_breakable.global_position = current_orbit_position
		held_breakable.is_orbiting = false
		emit_signal("breakable_dropped", held_breakable)  # Emitir señal al soltar
		held_breakable = null
		print('lo soltamos')
		return  

	held_breakable = breakable
	if held_breakable and is_instance_valid(held_breakable):
		breakableScene = breakable.get_parent()
		breakableScene.remove_child(breakable)
		add_child(breakable)
		breakable.position = Vector2(0, -15)
		near_breakable = null
		held_breakable.player = self
		held_breakable.is_orbiting = true
		emit_signal("breakable_picked_up", held_breakable)  # Emitir señal al recoger
		print('lo pillamos?')

	
func _drop_weapon() -> void:
	var weapon_to_drop: Node2D = current_weapon
	
	# Eliminar del sistema de inventario
	if has_node("/root/InventoryManager"):
		var inventory_manager = get_node("/root/InventoryManager")
		var removed_item = inventory_manager.remove_item_by_name_from_active(weapon_to_drop.name)
		if removed_item:
			print("Removed weapon from inventory system:", weapon_to_drop.name)
	
	# Eliminar de SavedData
	var weapon_index = current_weapon.get_index()
	SavedData.weapons.remove(weapon_index - 1)
	_switch_weapon(UP)
	
	emit_signal("weapon_droped", weapon_index)
	
	weapons.call_deferred("remove_child", weapon_to_drop)
	get_parent().call_deferred("add_child", weapon_to_drop)
	weapon_to_drop.set_owner(get_parent())
	yield(weapon_to_drop.tween, "tree_entered")
	
	var throw_dir: Vector2 = (get_global_mouse_position() - position).normalized()
	var force: int = 100
	var hitbox_instance = Hitbox.new()
	hitbox_instance.damage = 2
	hitbox_instance.knockback_direction = throw_dir
	hitbox_instance.knockback_force = force
	
	weapon_to_drop.add_child(hitbox_instance)
	weapon_to_drop.show()
	weapon_to_drop.get_node("AnimationPlayer").play("throw")
	weapon_to_drop.interpolate_pos(position, position + throw_dir * force)
	weapon_to_drop.remove_child(hitbox_instance)
		
func cancel_attack() -> void:
	current_weapon.cancel_attack()
	
	
func spawn_dust() -> void:
	var dust: Sprite = DUST_SCENE.instance()
	dust.position = dust_position.global_position
	parent.add_child_below_node(parent.get_child(get_index() - 1), dust)
		
		
func switch_camera() -> void:
	var main_scene_camera: Camera2D = get_parent().get_node("Camera2D")
	main_scene_camera.position = position
	main_scene_camera.current = true
	get_node("Camera2D").current = false

func _on_AnimationPlayer_animation_started(anim_name: String) -> void:
	emit_signal("animation_changed", anim_name)

func _throw_breakable() -> void:
	if held_breakable and is_instance_valid(held_breakable):
		var throw_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		var force: int = 100

		var initial_pos = held_breakable.global_position
		var final_pos = global_position + throw_dir * force

		remove_child(held_breakable)
		breakableScene.add_child(held_breakable)
		held_breakable.global_position = initial_pos
		held_breakable.is_orbiting = false  # Detener órbita al lanzar
		held_breakable.interpolate_pos(initial_pos, final_pos)

		held_breakable = null
		print("breakable lanzado")


func _input(event):
	# Solo procesar eventos del inventario
	if event.is_action_pressed("ui_inventory"):
		print("Player: Inventario tecla presionada - Tab")
		# Alternar el inventario directamente
		toggle_inventory()
		# Importante: consumir el evento para evitar doble procesamiento
		get_tree().set_input_as_handled()
		return

	# Bloquear acciones de combate si el inventario está abierto
	if InventoryDisplayManager.is_inventory_visible():
		# Intercepción temprana para evitar que las acciones del jugador se activen
		# cuando se está interactuando con el inventario
		if event is InputEventMouseButton or \
		   event.is_action_pressed("ui_attack") or \
		   event.is_action_pressed("ui_throw") or \
		   event.is_action_pressed("ui_dodge") or \
		   event.is_action_pressed("ui_interact") or \
		   event.is_action_pressed("ui_previous_weapon") or \
		   event.is_action_pressed("ui_next_weapon"):
			# NO evitamos que el evento se propague para que llegue al inventario
			# Solo queremos evitar que se procese aquí
			return

func toggle_inventory():
	print("toggle_inventory llamado")
	# Guardar el estado anterior antes de abrir el inventario (si no estamos en un estado especial)
	var prev_state = state_machine.state
	var was_in_special_state = (prev_state == state_machine.states.hurt or 
							  prev_state == state_machine.states.dead or
							  prev_state == state_machine.states.inventory_open)
	
	# Alternar el inventario
	print("Intentando alternar inventario")
	InventoryDisplayManager.toggle_inventory()
	print("Inventario visible: ", InventoryDisplayManager.is_inventory_visible())
	
	# Actualizar el estado de la FSM según el estado del inventario
	if InventoryDisplayManager.is_inventory_visible():
		# Cancelar cualquier ataque en progreso
		cancel_attack()
		# Cambiar al estado de inventario
		state_machine.set_state(state_machine.states.inventory_open)
		# Detener el movimiento inmediatamente
		mov_direction = Vector2.ZERO
		velocity = Vector2.ZERO
	else:
		# Al cerrar el inventario, volver al estado idle
		state_machine.set_state(state_machine.states.idle)

func _on_inventory_closed():
	print("Player: _on_inventory_closed")
	# Esta función se llama cuando el inventario se cierra desde la UI
	# Asegurarnos de que el estado del jugador sea coherente
	if state_machine.state == state_machine.states.inventory_open:
		print("Player: Cambiando estado a idle")
		# Detener el movimiento inmediatamente
		mov_direction = Vector2.ZERO
		velocity = Vector2.ZERO
		# Cambiar al estado idle
		state_machine.set_state(state_machine.states.idle)

func change_skin(new_skin: int):
	SavedData.skin = new_skin
	update_player_skin(new_skin)

## Requiere este formato en los assets:
# res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/skin_1/idle.png
# res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/skin_1/move.png
# res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/skin_1/roll.png
# res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/skin_1/dead.png

func update_player_skin(skin_number: int):
	var current_skin = skin_number
	var base_path = "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/skin_{0}/".format([current_skin])
	
	var new_spriteframes = SpriteFrames.new()
	
	for animation in ["idle", "move", "roll", "dead"]:  # Añade aquí todas tus animaciones
		var texture_path = base_path + "{0}.png".format([animation])
		var texture = load(texture_path)
		
		if texture:
			var hframes = texture.get_width() / 16  # Asumiendo que cada frame es de 16x16
			var vframes = texture.get_height() / 16
			
			new_spriteframes.add_animation(animation)
			
			for frame in range(hframes * vframes):
				var atlas_texture = AtlasTexture.new()
				atlas_texture.atlas = texture
				var x = (frame % hframes) * 16
				var y = (frame / hframes) * 16
				atlas_texture.region = Rect2(x, y, 16, 16)
				
				new_spriteframes.add_frame(animation, atlas_texture)
			
			# Configurar la velocidad de la animación
			new_spriteframes.set_animation_speed(animation, 5)  # 5 FPS por defecto
		else:
			print("Error: No se pudo cargar la textura para la animación ", animation)
	
	animated_sprite.frames = new_spriteframes
	animated_sprite.play("idle")  # Reinicia la animación al estado inicial
