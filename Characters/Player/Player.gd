extends Character

const DUST_SCENE: PackedScene = preload("res://Characters/Player/Dust.tscn")

enum {UP, DOWN}

var current_weapon: Node2D

signal weapon_switched(prev_index, new_index)
signal weapon_picked_up(weapon_texture)
signal weapon_droped(index)

onready var parent: Node2D = get_parent()
onready var weapons: Node2D = get_node("Weapons")
onready var dust_position: Position2D = get_node("DustPosition")
var dash_speed: float = 300
var dash_duration: float = 0.15
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2()
var dash_cooldown = 1
var can_dash: bool = true
# Variables para el cooldown
onready var dash_timer: Timer = Timer.new() # Timer para el dash
onready var cooldown_timer: Timer = Timer.new() # Timer para el cooldown

func _ready() -> void:
	emit_signal("weapon_picked_up", weapons.get_child(0).get_texture())
	
	_restore_previous_state()
	add_child(dash_timer)
	dash_timer.connect("timeout", self, "_on_dash_timer_timeout")

	add_child(cooldown_timer)
	cooldown_timer.connect("timeout", self, "_on_cooldown_timer_timeout")
	
	
func _restore_previous_state() -> void:
	self.hp = SavedData.hp
	for weapon in SavedData.weapons:
		weapon = weapon.duplicate()
		weapon.position = Vector2.ZERO
		weapons.add_child(weapon)
		weapon.hide()
		
		emit_signal("weapon_picked_up", weapon.get_texture())
		emit_signal("weapon_switched", weapons.get_child_count() - 2, weapons.get_child_count() - 1)
		
	current_weapon = weapons.get_child(SavedData.equipped_weapon_index)
	current_weapon.show()
	
	emit_signal("weapon_switched", weapons.get_child_count() - 1, SavedData.equipped_weapon_index)

func _process(_delta: float) -> void:
	var mouse_direction: Vector2 = (get_global_mouse_position() - global_position).normalized()
	
	if mouse_direction.x > 0 and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	elif mouse_direction.x < 0 and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
		
	current_weapon.move(mouse_direction)
	if Input.is_action_just_pressed("ui_dodge"):
		print(Input.is_action_just_pressed("ui_dodge"))
		print(not is_dashing)
		print(not cooldown_timer.is_stopped())
	if Input.is_action_just_pressed("ui_dodge") and not is_dashing and can_dash:
		print('fok')
		_start_dash()

	if is_dashing:
		_handle_dash(_delta)
		
		
func _start_dash():
	is_dashing = true
	can_dash = false # Deshabilitar el dash hasta que el cooldown termine
	dash_timer.start(dash_duration)
	cooldown_timer.start(dash_cooldown) 
	dash_direction = mov_direction.normalized()
	if dash_direction.length() == 0:
		dash_direction = Vector2(1, 0) # Dash por defecto en alguna dirección si está parado

	dash_timer.start(dash_duration)

func _handle_dash(delta: float):
	translate(dash_direction * dash_speed * delta)

func _on_dash_timer_timeout():
	is_dashing = false

func _on_cooldown_timer_timeout():
	print('xd');
	can_dash = true # El cooldown ha terminado, listo para otro dash
		
func get_input() -> void:
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
	
	emit_signal("weapon_picked_up", weapon.get_texture())
	emit_signal("weapon_switched", prev_index, new_index)
	
	
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
