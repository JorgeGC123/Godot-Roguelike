class_name GenericAttackComponent
extends Component

export var max_distance_to_player: float = 20.0
export var min_distance_to_player: float = 5.0
export var attack_damage: int = 1
export var knockback_force: int = 100
export var attack_cooldown: float = 1.5
export var cast_time: float = 0.75
export var attack_duration: float = 0.8 # Duración del attack
onready var animation_player: AnimationPlayer
var attack_finished: bool = false

var can_attack: bool = true
var is_attacking: bool = false
var is_preparing: bool = false
var attack_direction: Vector2 = Vector2.ZERO

onready var attack_timer: Timer = Timer.new()
onready var cast_timer: Timer = Timer.new()
onready var cooldown_timer: Timer = Timer.new()
onready var hitbox: Area2D

onready var charge_particles: CPUParticles2D

func _init(entity: Node).(entity):
	pass

func initialize():
	add_child(attack_timer)
	attack_timer.one_shot = true
	attack_timer.connect("timeout", self, "_on_attack_timer_timeout")

	add_child(cast_timer)
	cast_timer.one_shot = true
	cast_timer.connect("timeout", self, "_on_cast_timer_timeout")

	add_child(cooldown_timer)
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", self, "_on_cooldown_timer_timeout")

	charge_particles = CPUParticles2D.new()
	charge_particles.emitting = false
	charge_particles.amount = 15
	charge_particles.lifetime = 0.6
	charge_particles.spread = 180
	charge_particles.gravity = Vector2.ZERO
	charge_particles.initial_velocity = 6.63
	charge_particles.scale_amount = 0.5
	entity.add_child(charge_particles)
	animation_player = entity.get_node("AnimationPlayer")


# func update(delta: float):
# 	var player = entity.get_component("detection").get_player()
# 	if player and not is_attacking and not is_preparing:
# 		var distance_to_player = entity.global_position.distance_to(player.global_position)

# 		if distance_to_player <= max_distance_to_player and distance_to_player > min_distance_to_player and can_attack and not aim_raycast.is_colliding():
# 			_prepare_attack()
	
# 	if is_attacking:
# 		var movement_component = entity.get_component("movement")
# 		if movement_component:
# 			movement_component.set_movement_direction(attack_direction)

func _prepare_attack():
	is_preparing = true
	can_attack = false
	charge_particles.emitting = true
	cast_timer.start(cast_time)
	entity.send_message("attack_preparing", {})

func start_attack():
	if not is_instance_valid(entity.get_component("detection").get_player()) or is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	
	var player = entity.get_component("detection").get_player()
	attack_direction = (player.global_position - entity.global_position).normalized()
	
	# Actualizar hitbox
	var hitbox = entity.get_node("Hitbox")
	if hitbox:
		hitbox.knockback_direction = attack_direction
	
	# Asegurarnos de que la animación se reinicie
	entity.get_node("AnimatedSprite").frame = 0
	entity.get_node("AnimatedSprite").playing = true
	animation_player.stop()  # Asegurarnos de que no haya una animación en curso
	animation_player.play("attack")
	
	# Esperar a que termine la animación
	yield(animation_player, "animation_finished")
	
	attack_finished = true
	is_attacking = false
	
	# Volver a idle
	entity.get_node("AnimatedSprite").animation = "idle"
	entity.get_node("AnimatedSprite").playing = true
	
	# Iniciar cooldown
	attack_timer.start(attack_cooldown)
	entity.send_message("attack_finished", {})

func _on_attack_timer_timeout():
	can_attack = true
	attack_finished = false

func _on_cooldown_timer_timeout():
	_reset_attack()

func _on_cast_timer_timeout():
	charge_particles.emitting = false
	if entity.get_component("detection").is_player_in_range():
		start_attack()
	else:
		_reset_attack()

func _reset_attack():
	is_attacking = false
	is_preparing = false
	var movement_component = entity.get_component("movement")
	if movement_component:
		movement_component.stop()
		movement_component.speed = movement_component.default_speed # Reset speed to default
	entity.send_message("attack_finished", {})

func is_attack_available() -> bool:
	return can_attack and not is_attacking and not is_preparing
