extends Enemy

var can_attack: bool = true

var distance_to_player: float
const MAX_DISTANCE_TO_PLAYER: int = 40
const MIN_DISTANCE_TO_PLAYER: int = 20
onready var hitbox: Area2D = get_node("Hitbox")
onready var attack_timer: Timer = get_node("AttackTimer")
onready var aim_raycast: RayCast2D = get_node("AimRayCast")
const HEADBUTT_SPEED: float = 300.0 

func _on_PathTimer_timeout() -> void:
	if is_instance_valid(player):
		distance_to_player = (player.position - global_position).length()
		if distance_to_player > MAX_DISTANCE_TO_PLAYER:
			_get_path_to_player()
		else:
			aim_raycast.cast_to = player.position - global_position
			if can_attack:
				can_attack = false
				_headbutt()
				attack_timer.start()
				
	else:
		path_timer.stop()
		path = []
		mov_direction = Vector2.ZERO
			

func _process(_delta: float) -> void:
	hitbox.knockback_direction = velocity.normalized()

func _headbutt() -> void:
	if not is_instance_valid(player):
		return
	state_machine.set_state(state_machine.states.attack)
	# Calcular la dirección hacia el jugador
	var direction_to_player = (player.position - global_position).normalized()
	
	# Aplicar velocidad en esa dirección
	velocity = direction_to_player * HEADBUTT_SPEED
	print("soy 1 fkin proyectil")
	# Actualizar la animación del enemigo si es necesario
	# animation_player.play("headbutt")  # animación
	yield(attack_timer, "timeout")
	attack_timer.stop()
	state_machine.set_state(state_machine.states.chase)
	can_attack = true

func _ready():
	attack_timer.wait_time = 1
