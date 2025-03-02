extends Node2D
class_name Weapon, "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/knight/weapon_sword_1.png"

const SWORD_COLLISION_SCENE: PackedScene = preload("res://Characters/SwordCollision.tscn")

export(bool) var on_floor: bool = false

export var ranged_weapon: bool = false
export var rotation_offset: int = 0
var player # referencia al player que la tiene equipada
var can_active_ability: bool = true

onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
onready var hitbox: Area2D = get_node("Node2D/Sprite/Hitbox")
onready var charge_particles: Particles2D = get_node("Node2D/Sprite/ChargeParticles")
onready var player_detector: Area2D = get_node("PlayerDetector")
onready var tween: Tween = get_node("Tween")
onready var cool_down_timer: Timer = get_node("CoolDownTimer")
onready var ui: CanvasLayer = get_node("UI")
onready var ability_icon: TextureProgress = ui.get_node("AbilityIcon")

export var BASIC_ATTACK_STAMINA = 50
export var CHARGED_ATTACK_STAMINA = 70
export var ABILITY_STAMINA = 70

# Métodos para acceder a los costes de stamina desde cualquier componente
func get_basic_attack_cost() -> int:
	return BASIC_ATTACK_STAMINA

func get_charged_attack_cost() -> int:
	return CHARGED_ATTACK_STAMINA

func get_ability_cost() -> int:
	return ABILITY_STAMINA

# para multiplayer
signal weapon_animation_changed(anim_name)
signal weapon_moved(scale_y,rotation,hitbox_knockback)

func _ready() -> void:
	var shape = hitbox.get_node("CollisionShape2D")
	
	if animation_player:
		animation_player.stop()
	if charge_particles:
		charge_particles.emitting = false

	# Determinar si el arma está equipada según el árbol de nodos
	var is_equipped = false
	var parent = get_parent()
	if parent and parent.name == "Weapons":
		is_equipped = true
		# Actualizar on_floor cuando está equipada
		on_floor = false

	# Configurar correctamente las colisiones y detección según el estado
	if on_floor:
		shape.disabled = true
		# Activar el detector de jugador cuando está en el suelo
		player_detector.set_collision_mask_bit(0, true)
		player_detector.set_collision_mask_bit(1, true)
	else:
		# Si no está en el suelo (está equipada), desactivar la detección del jugador
		shape.disabled = true
		player_detector.set_collision_mask_bit(0, false)
		player_detector.set_collision_mask_bit(1, false)
	
	# Configurar hitbox para detectar colisiones con otras armas
	# Layer 3 será para hitboxes de armas
	hitbox.set_collision_layer_bit(3, true)
	hitbox.set_collision_mask_bit(3, true)
	
	# Conectar señal de colisión área-área
	if not hitbox.is_connected("area_entered", self, "_on_Hitbox_area_entered"):
		hitbox.connect("area_entered", self, "_on_Hitbox_area_entered")


func get_input() -> void:
	if Input.is_action_pressed("ui_attack") and not animation_player.is_playing() and player.stamina > BASIC_ATTACK_STAMINA:
		if player.stamina > CHARGED_ATTACK_STAMINA:
			animation_player.play("charge")
			emit_signal("weapon_animation_changed", "charge")
	elif Input.is_action_just_released("ui_attack") and player.stamina > BASIC_ATTACK_STAMINA:
		#if animation_player.is_playing() and animation_player.current_animation == "charge":
			animation_player.play("attack")
			emit_signal("weapon_animation_changed", "attack")
	if charge_particles.emitting and player.stamina > CHARGED_ATTACK_STAMINA and Input.is_action_just_released("ui_attack"):
			animation_player.play("strong_attack")
			emit_signal("weapon_animation_changed", "strong_attack")
	elif Input.is_action_just_pressed("ui_active_ability") and animation_player.has_animation("active_ability") and not is_busy() and can_active_ability and player.stamina > ABILITY_STAMINA:
		can_active_ability = false
		cool_down_timer.start()
		ui.recharge_ability_animation(cool_down_timer.wait_time)
		animation_player.play("active_ability")
		emit_signal("weapon_animation_changed", "active_ability")
			
			
func move(mouse_direction: Vector2) -> void:
	if ranged_weapon:
		rotation_degrees = rad2deg(mouse_direction.angle()) + rotation_offset
	else:
		if not animation_player.is_playing() or animation_player.current_animation == "charge":
			rotation = mouse_direction.angle()
			hitbox.knockback_direction = mouse_direction
			if scale.y == 1 and mouse_direction.x < 0:
				scale.y = -1
			elif scale.y == -1 and mouse_direction.x > 0:
				scale.y = 1

	emit_signal("weapon_moved", scale.y,rotation,hitbox.knockback_direction)
			
			
func cancel_attack() -> void:
	animation_player.play("cancel_attack")
	
	
func is_busy() -> bool:
	if animation_player.is_playing() or charge_particles.emitting:
		return true
	return false


func _on_PlayerDetector_body_entered(body: KinematicBody2D) -> void:
	if body != null and body is Player:
		# Desactivar inmediatamente el detector para evitar múltiples detecciones
		player_detector.set_collision_mask_bit(0, false)
		player_detector.set_collision_mask_bit(1, false)
		
		# Asegurarse de que on_floor sea false antes de recoger
		on_floor = false
		
		# Permitir al jugador recogerla
		body.pick_up_weapon(self)
		position = Vector2.ZERO
	else:
		var __ = tween.stop_all()
		assert(__)
		player_detector.set_collision_mask_bit(1, true)
		
		
func interpolate_pos(initial_pos: Vector2, final_pos: Vector2) -> void:
	var __ = tween.interpolate_property(self, "position", initial_pos, final_pos, 0.8, Tween.TRANS_QUART, Tween.EASE_OUT)
	assert(__)
	__ = tween.start()
	assert(__)
	player_detector.set_collision_mask_bit(0, true)


func _on_Tween_tween_completed(_object: Object, _key: NodePath) -> void:
	player_detector.set_collision_mask_bit(1, true)


func _on_CoolDownTimer_timeout() -> void:
	can_active_ability = true
	
	
func show() -> void:
	ability_icon.show()
	.show()
	
	
func hide() -> void:
	ability_icon.hide()
	.hide()
	
	
func get_texture() -> Texture:
	return get_node("Node2D/Sprite").texture


func stamina_tax(amount: int) -> void:
	var character = get_parent().get_parent() # TODO: mejorar esto
	if(character is Player):
		character.reduce_stamina(amount)

func _on_AnimationPlayer_animation_started(anim_name:String):
	if anim_name == "attack":
		stamina_tax(BASIC_ATTACK_STAMINA) # TODO: constantes y futuros incrementos/decrementos por skills pasivas
	elif anim_name == "attack2":
		stamina_tax(BASIC_ATTACK_STAMINA)
	elif anim_name == "strong_attack":
		stamina_tax(CHARGED_ATTACK_STAMINA)
	elif anim_name == "active_ability":
		stamina_tax(ABILITY_STAMINA)


func _on_Hitbox_body_entered(body:Node):
	# aquí llevamos la lógica del daño a tilemaps
	# TODO: sacarla de weapon, aunque sea el emisor
	if body is TileMap:
		var local_position = body.to_local(self.global_position)
		var map_position = body.world_to_map(local_position)
		var WALL_TILE_ID = 2
		var BROKEN_WALL_TILE_ID = 27
		if(body.get_cellv(map_position+Vector2.UP) == WALL_TILE_ID):
			body.set_cellv(map_position+Vector2.UP,BROKEN_WALL_TILE_ID)


func _on_Hitbox_area_entered(area:Area2D):
	# Verificar si el área es un hitbox de otra arma
	if area.get_collision_layer_bit(3) and animation_player.is_playing():
		var other_weapon = _find_parent_weapon(area)
		if other_weapon and other_weapon != self:
			# Si el arma está atacando (animación en curso)
			if other_weapon.animation_player.is_playing():
				print("¡Colisión de armas detectada! " + self.name + " vs " + other_weapon.name)
				
				# Cancelar ataques de ambas armas
				self.cancel_attack()
				
				# Intentar cancelar el ataque de la otra arma
				if other_weapon.has_method("cancel_attack"):
					other_weapon.cancel_attack()
				else:
					# Puede que sea un WeaponComponent de NPC
					var parent = other_weapon.get_parent()
					if parent and parent.has_method("cancel_attack"):
						parent.cancel_attack()
					# Si no, buscar en el árbol hacia arriba
					else:
						var ancestor = other_weapon.get_parent().get_parent()
						if ancestor and ancestor.has_method("cancel_attack"):
							ancestor.cancel_attack()
				
				# Crear efecto de colisión de espadas en el punto de colisión
				var collision_effect: CPUParticles2D = SWORD_COLLISION_SCENE.instance()
				var collision_dir = (global_position - other_weapon.global_position).normalized()
				collision_effect.global_rotation = collision_dir.angle()
				collision_effect.global_position = area.global_position
				
				var main_scene = get_tree().root
				main_scene.add_child(collision_effect)
				
				collision_effect.z_index = 1

				# Añadir la partícula a la lista en el singleton para luego borrarlas
				SceneTransistor.add_blood_effect(collision_effect)


func _find_parent_weapon(node:Node) -> Node:
	# Buscar recursivamente hasta encontrar un nodo que probablemente sea un arma
	var parent = node.get_parent()
	# En lugar de comparar con el tipo, verificamos si tiene los componentes típicos de un arma
	while parent and not (parent.has_node("AnimationPlayer") and parent.has_node("Node2D/Sprite/Hitbox")):
		parent = parent.get_parent()
	return parent
