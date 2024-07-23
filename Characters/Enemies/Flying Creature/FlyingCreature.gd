extends Enemy

var can_attack: bool = true

var distance_to_player: float
const MAX_DISTANCE_TO_PLAYER: int = 60
const MIN_DISTANCE_TO_PLAYER: int = 20
onready var hitbox: Area2D = get_node("Hitbox")
onready var attack_timer: Timer = get_node("AttackTimer")
onready var cast_timer: Timer = Timer.new()
onready var aim_raycast: RayCast2D = get_node("AimRayCast")
onready var charge_particles: CPUParticles2D = get_node("Area2D/ChargeParticles")
const HEADBUTT_SPEED: float = 300.0 

func _on_PathTimer_timeout() -> void:
	if is_instance_valid(player) and state_machine.get_current_state() != "dead":
		aim_raycast.cast_to = player.position - global_position
		aim_raycast.force_raycast_update()
		distance_to_player = (player.position - global_position).length()
		if distance_to_player > MAX_DISTANCE_TO_PLAYER and distance_to_player < detection_radius and state_machine.get_current_state() != "dead":
			state_machine.set_state(state_machine.states.chase)
			_get_path_to_player()
		else:
			if distance_to_player < detection_radius and distance_to_player < MAX_DISTANCE_TO_PLAYER:
				print(aim_raycast.is_colliding())
				if can_attack and not aim_raycast.is_colliding():
					state_machine.set_state(state_machine.states.attack)
					can_attack = false
					charge_particles.emitting = true
					cast_timer.start()
					yield(cast_timer, "timeout")
					cast_timer.stop()
					charge_particles.emitting = false
					if distance_to_player > MAX_DISTANCE_TO_PLAYER:
						state_machine.set_state(state_machine.states.idle)
						can_attack = true
						return
					else:
						_headbutt()
						attack_timer.start()
				else:
					state_machine.set_state(state_machine.states.chase)
					can_attack = true
					_get_path_to_player()

				
	else:
		path_timer.stop()
		path = []
		mov_direction = Vector2.ZERO
			

func _process(_delta: float) -> void:
	print(state_machine.get_current_state())
	hitbox.knockback_direction = velocity.normalized()

func _headbutt() -> void:
	if not is_instance_valid(player) or state_machine.get_current_state() == "dead":
		return
	# Calcular la dirección hacia el jugador
	var direction_to_player = (player.position - global_position).normalized()
	
	# Aplicar velocidad en esa dirección
	velocity = direction_to_player * HEADBUTT_SPEED * 2
	# Actualizar la animación del enemigo si es necesario
	yield(attack_timer, "timeout")
	attack_timer.stop()
	can_attack = true
	state_machine.set_state(state_machine.states.idle)

func _ready():
	add_child(cast_timer)
	attack_timer.wait_time = 1
	cast_timer.wait_time = 0.5
