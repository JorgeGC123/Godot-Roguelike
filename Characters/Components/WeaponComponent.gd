class_name WeaponComponent
extends Component

var weapon: Weapon
var target: Node2D

export var orbit_radius: float = 5.0
export var rotation_speed: float = 15.0
export var weapon_length: float = 2.0
export var perpendicular_offset: float = PI / 2
export var rotation_offset: int = 0
export var additional_angle_offset: float = 0.5

export var ranged_weapon: bool = false

var can_active_ability: bool = true

onready var animation_player: AnimationPlayer
onready var hitbox: Area2D
onready var charge_particles: Particles2D
onready var tween: Tween
onready var cool_down_timer: Timer
export var attack_cooldown: float = 2.0
export var charge_time: float = 1.0
var charge_timer: Timer
var can_attack: bool = true
var is_charging: bool = false
var is_attacking: bool = false
var charge_start_time: float = 0

export var BASIC_ATTACK_STAMINA = 5
export var CHARGED_ATTACK_STAMINA = 70
export var ABILITY_STAMINA = 70

signal weapon_animation_changed(anim_name)
signal weapon_moved(scale_y, rotation, hitbox_knockback)
signal attack_started
signal attack_finished

func _init(entity: Node2D, weapon_scene: PackedScene).(entity):
	self.entity = entity
	weapon = weapon_scene.instance()
	add_child(weapon)
	weapon.set_as_toplevel(true)

func initialize():
	if not is_instance_valid(weapon):
		return
	
	animation_player = weapon.get_node("AnimationPlayer")
	hitbox = weapon.get_node("Node2D/Sprite/Hitbox")
	# de una vez por todas:
	hitbox.set_collision_mask_bit(0, true) # 1 es la máscara del world -> true
	hitbox.set_collision_mask_bit(1, true) # 1 es la máscara del player -> true
	hitbox.set_collision_mask_bit(2, false) # 2 es la máscara de los enemies -> false
	charge_particles = weapon.get_node("Node2D/Sprite/ChargeParticles")
	tween = weapon.get_node("Tween")
	cool_down_timer = weapon.get_node("CoolDownTimer")
	add_child(cool_down_timer)
	cool_down_timer.connect("timeout", self, "_on_attack_cooldown_timeout")
	
	if animation_player:
		animation_player.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")
		animation_player.connect("animation_started", self, "_on_AnimationPlayer_animation_started")

	weapon.visible = true
	
	target = entity.get_node("/root/Game/Player")
	charge_timer = Timer.new()
	charge_timer.one_shot = true
	charge_timer.connect("timeout", self, "_on_charge_timer_timeout")
	add_child(charge_timer)
	update_weapon_position()

func get_input():
	if entity is Player:
		if Input.is_action_pressed("ui_attack") and not animation_player.is_playing() and entity.stamina > BASIC_ATTACK_STAMINA:
			if entity.stamina > CHARGED_ATTACK_STAMINA:
				animation_player.play("charge")
				emit_signal("weapon_animation_changed", "charge")
		elif Input.is_action_just_released("ui_attack") and entity.stamina > BASIC_ATTACK_STAMINA:
			animation_player.play("attack")
			emit_signal("weapon_animation_changed", "attack")
		if charge_particles.emitting and entity.stamina > CHARGED_ATTACK_STAMINA and Input.is_action_just_released("ui_attack"):
			animation_player.play("strong_attack")
			emit_signal("weapon_animation_changed", "strong_attack")
		elif Input.is_action_just_pressed("ui_active_ability") and animation_player.has_animation("active_ability") and not is_busy() and can_active_ability and entity.stamina > ABILITY_STAMINA:
			can_active_ability = false
			cool_down_timer.start()
			animation_player.play("active_ability")
			emit_signal("weapon_animation_changed", "active_ability")

func move(direction: Vector2):
	if ranged_weapon:
		weapon.rotation_degrees = rad2deg(direction.angle()) + rotation_offset
	else:
		if not animation_player.is_playing() or animation_player.current_animation == "charge":
			weapon.rotation = direction.angle()
			hitbox.knockback_direction = direction

			if weapon.scale.y == 1 and direction.x < 0:
				weapon.scale.y = -1
			elif weapon.scale.y == -1 and direction.x > 0:
				weapon.scale.y = 1

	emit_signal("weapon_moved", weapon.scale.y, weapon.rotation, hitbox.knockback_direction)


func attack():
	if not is_busy() and entity.stamina > BASIC_ATTACK_STAMINA:
		animation_player.play("attack")
		emit_signal("weapon_animation_changed", "attack")

func strong_attack():
	if not is_busy() and entity.stamina > CHARGED_ATTACK_STAMINA:
		animation_player.play("strong_attack")
		emit_signal("weapon_animation_changed", "strong_attack")

func use_ability():
	if not is_busy() and can_active_ability and entity.stamina > ABILITY_STAMINA:
		can_active_ability = false
		cool_down_timer.start()
		animation_player.play("active_ability")
		emit_signal("weapon_animation_changed", "active_ability")

func is_busy() -> bool:
	return animation_player.is_playing() or charge_particles.emitting

# func _on_AnimationPlayer_animation_started(anim_name: String):
# 	print("Animation started:", anim_name)

func _on_CoolDownTimer_timeout():
	can_active_ability = true

func update(delta: float):
	#handle_enemy_attack(delta)
	update_weapon_position()

func handle_enemy_attack(delta: float):
	if can_attack and not is_charging and not is_attacking:
		start_charge()

func start_charge():
	if not is_charging and not is_attacking:
		is_charging = true
		animation_player.play("charge")
		charge_particles.emitting = true
		charge_timer.start(charge_time)

func execute_attack():
	is_charging = false
	is_attacking = true
	charge_particles.emitting = false
	if entity.stamina >= entity.BASIC_ATTACK_STAMINA:
		animation_player.play("attack")
		entity.reduce_stamina(entity.BASIC_ATTACK_STAMINA)
		emit_signal("attack_started")
	else:
		cancel_attack()

func _on_AnimationPlayer_animation_finished(anim_name: String):
	match anim_name:
		"attack":
			is_attacking = false
			can_attack = false
			cool_down_timer.start(attack_cooldown)
			emit_signal("attack_finished")
		"charge":
			if is_charging:
				execute_attack()

func cancel_attack():
	is_charging = false
	is_attacking = false
	charge_particles.emitting = false
	animation_player.play("cancel_attack")

func update_weapon_position():
	if not is_instance_valid(weapon) or not is_instance_valid(entity) or not is_instance_valid(target):
		return

	var direction_to_player = (target.global_position - entity.global_position).normalized()
	var orbit_position = entity.global_position + direction_to_player * orbit_radius

	weapon.global_position = orbit_position
	weapon.look_at(target.global_position)
	# weapon.rotation += perpendicular_offset + additional_angle_offset

	# var weapon_direction = Vector2.RIGHT.rotated(weapon.rotation)
	# weapon.global_position -= weapon_direction * (weapon_length / 2)


func _on_charge_timer_timeout():
	if is_charging:
		execute_attack()

func _on_attack_cooldown_timeout():
	can_attack = true
