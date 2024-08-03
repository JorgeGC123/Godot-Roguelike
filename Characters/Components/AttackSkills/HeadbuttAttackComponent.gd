class_name HeadbuttAttackComponent
extends Component

export var max_distance_to_player: float = 60.0
export var min_distance_to_player: float = 20.0
export var headbutt_speed: float = 500.0
export var headbutt_damage: int = 1
export var knockback_force: int = 100
export var attack_cooldown: float = 1.5
export var cast_time: float = 0.75
export var headbutt_duration: float = 0.6  # Duración del headbutt

var can_attack: bool = true
var is_attacking: bool = false
var is_preparing: bool = false
var attack_direction: Vector2 = Vector2.ZERO

onready var attack_timer: Timer = Timer.new()
onready var cast_timer: Timer = Timer.new()
onready var headbutt_timer: Timer = Timer.new()
onready var hitbox: Area2D
onready var aim_raycast: RayCast2D
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

	add_child(headbutt_timer)
	headbutt_timer.one_shot = true
	headbutt_timer.connect("timeout", self, "_on_headbutt_timer_timeout")

	hitbox = Area2D.new()
	hitbox.collision_layer = 1
	hitbox.collision_mask = 1
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	collision_shape.shape = shape
	hitbox.add_child(collision_shape)
	hitbox.connect("body_entered", self, "_on_Hitbox_body_entered")
	entity.add_child(hitbox)
	hitbox.set_deferred("monitoring", false)

	aim_raycast = RayCast2D.new()
	aim_raycast.enabled = true
	aim_raycast.collision_mask = 1
	entity.add_child(aim_raycast)

	charge_particles = CPUParticles2D.new()
	charge_particles.emitting = false
	charge_particles.amount = 15
	charge_particles.lifetime = 0.6
	charge_particles.spread = 180
	charge_particles.gravity = Vector2.ZERO
	charge_particles.initial_velocity = 6.63
	charge_particles.scale_amount = 0.5
	entity.add_child(charge_particles)

func update(delta: float):
	var player = entity.get_component("detection").get_player()
	if player and not is_attacking and not is_preparing:
		var distance_to_player = entity.global_position.distance_to(player.global_position)
		aim_raycast.cast_to = player.global_position - entity.global_position
		aim_raycast.force_raycast_update()
		
		if distance_to_player <= max_distance_to_player and distance_to_player > min_distance_to_player and can_attack and not aim_raycast.is_colliding():
			_prepare_attack()
	
	if is_attacking:
		var movement_component = entity.get_component("movement")
		if movement_component:
			movement_component.set_movement_direction(attack_direction)

func _prepare_attack():
	is_preparing = true
	can_attack = false
	charge_particles.emitting = true
	cast_timer.start(cast_time)
	entity.send_message("headbutt_preparing", {})

func start_headbutt():
	if not is_instance_valid(entity.get_component("detection").get_player()):
		_reset_attack()
		return
	
	is_preparing = false
	is_attacking = true
	var player = entity.get_component("detection").get_player()
	attack_direction = (player.global_position - entity.global_position).normalized()
	hitbox.set_deferred("monitoring", true)
	
	var movement_component = entity.get_component("movement")
	if movement_component:
		movement_component.speed = headbutt_speed  # Set speed for headbutt
		movement_component.friction = 25
		movement_component.acceleration = 125
		movement_component.set_movement_direction(attack_direction)
	
	headbutt_timer.start(headbutt_duration)
	attack_timer.start(attack_cooldown)
	entity.send_message("headbutt_started", {})

func _on_attack_timer_timeout():
	can_attack = true

func _on_headbutt_timer_timeout():
	_reset_attack()

func _on_cast_timer_timeout():
	charge_particles.emitting = false
	if entity.get_component("detection").is_player_in_range():
		start_headbutt()
	else:
		_reset_attack()

func _reset_attack():
	is_attacking = false
	is_preparing = false
	hitbox.set_deferred("monitoring", false)
	var movement_component = entity.get_component("movement")
	if movement_component:
		movement_component.stop()
		movement_component.speed = movement_component.default_speed  # Reset speed to default
	entity.send_message("headbutt_finished", {})

func _on_Hitbox_body_entered(body):
	if body.has_method("take_damage") and body != entity:
		body.take_damage(headbutt_damage, attack_direction, knockback_force)
		print("Headbutt hit: ", body.name)

func is_headbutt_available() -> bool:
	return can_attack and not is_attacking and not is_preparing
