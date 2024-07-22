extends Node2D
class_name Weapon, "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/knight/weapon_sword_1.png"

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

# para multiplayer
signal weapon_animation_changed(anim_name)
signal weapon_moved(scale_y,rotation,hitbox_knockback)

func _ready() -> void:
	var shape = hitbox.get_node("CollisionShape2D")
	if on_floor:
		shape.disabled = true
	if not on_floor:
		player_detector.set_collision_mask_bit(0, false)
		player_detector.set_collision_mask_bit(1, false)


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
	if body != null:
		player_detector.set_collision_mask_bit(0, false)
		player_detector.set_collision_mask_bit(1, false)
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
		var tile_pos = body.world_to_map(self.global_position)
		var WALL_TILE_ID = 2
		var BROKEN_WALL_TILE_ID = 27
		if(body.get_cellv(tile_pos+Vector2.UP) == WALL_TILE_ID):
			body.set_cellv(tile_pos+Vector2.UP,BROKEN_WALL_TILE_ID)
