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

onready var parent: Node2D = get_parent()
onready var weapons: Node2D = get_node("Weapons")
onready var dust_position: Position2D = get_node("DustPosition")
onready var player_dash: PlayerDash = $PlayerDash
var near_breakable: Node = null
var held_breakable: Node = null 
var breakableScene: Node2D = null


export var DASH_STAMINA = 30

func _ready() -> void:
	emit_signal("weapon_picked_up", weapons.get_child(0).get_texture())
	
	_restore_previous_state()
	
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
	
	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	var window_size: Vector2 = OS.get_window_size()
	var mouse_pos = get_global_mouse_position()
	$Camera2D.offset_h = (mouse_pos.x - global_position.x) / (window_size.x/2)
	$Camera2D.offset_v = (mouse_pos.y - global_position.y) / (window_size.y/2)
	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
		
	emit_signal("flip_h_changed", animated_sprite.flip_h)
	current_weapon.move(mouse_direction)
	
	player_dash._process(_delta)
	if Input.is_action_just_pressed("ui_dodge") and player_dash.is_dash_available() and stamina > DASH_STAMINA:
		player_dash.start_dash(mov_direction)
		stamina -= DASH_STAMINA


	if player_dash.is_dashing:
		translate(player_dash.dash_direction * player_dash.dash_speed * _delta)
		

	if Input.is_action_just_pressed("ui_interact"):
		pick_up_breakable(near_breakable) 
		
func get_input() -> void:
	# Verificar si el jugador está realizando un dash
	if player_dash.is_dashing:
		return  # No procesar entradas de movimiento durante el dash

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
	SavedData.weapons.append(weapon.duplicate())
	var prev_index: int = SavedData.equipped_weapon_index
	var new_index: int = weapons.get_child_count()
	SavedData.equipped_weapon_index = new_index
	weapon.get_parent().call_deferred("remove_child", weapon)
	weapons.call_deferred("add_child", weapon)
	weapon.set_deferred("owner", weapons)
	current_weapon.hide()
	current_weapon.cancel_attack()
	current_weapon = weapon
	current_weapon.player = self
	emit_signal("weapon_picked_up", weapon.get_texture())
	emit_signal("weapon_switched", prev_index, new_index)
	

func pick_up_breakable(breakable: Node) -> void:
	if held_breakable and is_instance_valid(held_breakable):
		var current_orbit_position = held_breakable.global_position  # Obtener la posición actual en la órbita
		remove_child(held_breakable)
		breakableScene.add_child(held_breakable)
		held_breakable.global_position = current_orbit_position  # Usar la posición actual en la órbita
		held_breakable.is_orbiting = false  # Detener órbita al soltar
		held_breakable = null  # Resetear la referencia
		print('lo soltamos')
		return  

	held_breakable = breakable
	if held_breakable and is_instance_valid(held_breakable):
		breakableScene = breakable.get_parent()
		breakableScene.remove_child(breakable)
		add_child(breakable)
		breakable.position = Vector2(0, -15)  # Ajusta esta posición según necesites
		near_breakable = null
		held_breakable.player = self  # Establecer la referencia al jugador
		held_breakable.is_orbiting = true  # Iniciar órbita al recoger
		print('lo pillamos?')

	
func _drop_weapon() -> void:
	SavedData.weapons.remove(current_weapon.get_index() - 1)
	var weapon_to_drop: Node2D = current_weapon
	_switch_weapon(UP)
	
	emit_signal("weapon_droped", weapon_to_drop.get_index())
	
	weapons.call_deferred("remove_child", weapon_to_drop)
	get_parent().call_deferred("add_child", weapon_to_drop)
	weapon_to_drop.set_owner(get_parent())
	yield(weapon_to_drop.tween, "tree_entered")
		
	var throw_dir: Vector2 = (get_global_mouse_position() - position).normalized()
	var force: int = 100;
	var hitbox_instance = Hitbox.new()
	hitbox_instance.damage = 2 # El daño que quieres que haga
	hitbox_instance.knockback_direction = throw_dir
	hitbox_instance.knockback_force = force;
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
