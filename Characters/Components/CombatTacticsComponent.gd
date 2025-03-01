class_name CombatTacticsComponent
extends Component

# Configuraciones para tácticas de combate
export var circling_distance: float = 40.0  # Distancia óptima para rodear
export var circling_speed_multiplier: float = 0.8  # Multiplicador de velocidad al rodear
export var retreat_distance: float = 20.0  # Distancia para retroceder
export var approach_distance: float = 60.0  # Distancia para acercarse
export var post_attack_retreat_speed: float = 1.2  # Velocidad de retroceso tras atacar
export var retreat_time: float = 0.4  # Tiempo de retroceso reducido
export var attack_charge_approach_speed: float = 1.1  # Velocidad de acercamiento al cargar

# Estados FSM conocidos
enum FSMState {IDLE = 0, CHASE = 1, ATTACK = 2}

# Variables de estado
var movement_component: MovementComponent
var detection_component: DetectionComponent
var weapon_component: WeaponComponent
var current_tactic: String = "none"  # none, circling, approach, retreat, post_attack_retreat, attack_charge_approach, recovery
var circling_direction: int = 1  # 1: clockwise, -1: counter-clockwise
var tactic_timer: float = 0.0
var tactic_change_interval: float = 1.5  # Cambiar de táctica cada X segundos
var last_player_position: Vector2 = Vector2.ZERO
var is_post_attack: bool = false
var is_recovery: bool = false
var current_fsm_state: int = -1

func _init(entity: Node).(entity):
	randomize()
	# Inicializamos con dirección aleatoria para rodear
	circling_direction = 1 if randf() > 0.5 else -1

func initialize():
	movement_component = entity.get_component("movement")
	detection_component = entity.get_component("detection")
	weapon_component = entity.get_component("weapon")
	
	if not movement_component or not detection_component:
		push_error("CombatTacticsComponent requiere MovementComponent y DetectionComponent")
	
	# Conectamos a las señales del arma si está disponible
	if weapon_component:
		if not weapon_component.is_connected("attack_started", self, "_on_attack_started"):
			weapon_component.connect("attack_started", self, "_on_attack_started")
		if not weapon_component.is_connected("attack_finished", self, "_on_attack_finished"):
			weapon_component.connect("attack_finished", self, "_on_attack_finished")

	# Obtener la referencia a la FSM
	var fsm_component = entity.get_component("fsm")
	if fsm_component:
		if not fsm_component.is_connected("state_changed", self, "_on_fsm_state_changed"):
			fsm_component.connect("state_changed", self, "_on_fsm_state_changed")

func update(delta: float):
	var player = detection_component.get_player()
	if not player:
		return
		
	last_player_position = player.global_position
	
	# Si estamos en estado CHASE, no interferimos con el movimiento (pathfinding)
	if current_fsm_state == FSMState.CHASE and current_tactic != "post_attack_retreat" and not is_recovery:
		return
	
	# Si estamos en estado ATTACK, aplicamos tácticas de combate
	if current_fsm_state == FSMState.ATTACK:
		# Verificar estado del arma si está disponible
		if weapon_component:
			if is_recovery:
				# Estamos en recuperación, mantener distancia
				current_tactic = "recovery"
			elif is_post_attack:
				# Después de atacar, retroceder
				current_tactic = "post_attack_retreat"
			elif weapon_component.is_charging:
				# Durante la carga, acercarse
				current_tactic = "attack_charge_approach"
			else:
				# En otros casos durante el ataque, rodar
				current_tactic = "circling"
		
		# Ejecutar la táctica actual
		match current_tactic:
			"circling":
				_execute_circling()
			"approach":
				_execute_approach()
			"retreat":
				_execute_retreat()
			"post_attack_retreat":
				_execute_post_attack_retreat()
			"attack_charge_approach":
				_execute_attack_charge_approach()
			"recovery":
				_execute_recovery()

func _execute_circling():
	var player = detection_component.get_player()
	if not player:
		return
	
	# Vector desde el jugador hacia el enemigo
	var to_enemy = entity.global_position - player.global_position
	
	# Vector perpendicular (para moverse alrededor del jugador)
	var perpendicular = Vector2(-to_enemy.y, to_enemy.x).normalized() * circling_direction
	
	# Combinamos movimiento circular con un ligero componente de mantenimiento de distancia
	var ideal_position = player.global_position + to_enemy.normalized() * circling_distance
	var to_ideal = (ideal_position - entity.global_position).normalized() * 0.3
	
	var final_direction = (perpendicular + to_ideal).normalized()
	
	# Aplicamos el movimiento con la velocidad ajustada
	movement_component.set_movement_direction(final_direction)
	movement_component.set_speed_multiplier(circling_speed_multiplier)

func _execute_approach():
	var player = detection_component.get_player()
	if not player:
		return
	
	var direction = (player.global_position - entity.global_position).normalized()
	movement_component.set_movement_direction(direction)
	movement_component.set_speed_multiplier(1.0)  # Velocidad normal

func _execute_retreat():
	var player = detection_component.get_player()
	if not player:
		return
	
	var direction = (entity.global_position - player.global_position).normalized()
	movement_component.set_movement_direction(direction)
	movement_component.set_speed_multiplier(0.9)  # Ligeramente más lento al retroceder

func _execute_post_attack_retreat():
	var player = detection_component.get_player()
	if not player:
		return
	
	# Verificar distancia al jugador
	var distance = entity.global_position.distance_to(player.global_position)
	
	# Solo retroceder si estamos más cerca que la distancia ideal de ataque
	if distance < entity.ideal_attack_distance:
		# Alejarse del jugador después de atacar
		var direction = (entity.global_position - player.global_position).normalized()
		movement_component.set_movement_direction(direction)
		movement_component.set_speed_multiplier(post_attack_retreat_speed)
	else:
		# Si ya estamos a buena distancia o más lejos, intentar mantener la distancia ideal
		_maintain_attack_distance()

func _execute_attack_charge_approach():
	var player = detection_component.get_player()
	if not player:
		return
	
	# Acercarse al jugador durante la carga del ataque
	var direction = (player.global_position - entity.global_position).normalized()
	movement_component.set_movement_direction(direction)
	movement_component.set_speed_multiplier(attack_charge_approach_speed)

# Estado de recuperación después de un ataque
func _execute_recovery():
	var player = detection_component.get_player()
	if not player:
		return
	
	# Mantener la distancia circulando a una velocidad más lenta
	var to_enemy = entity.global_position - player.global_position
	var distance = to_enemy.length()
	
	if distance < entity.ideal_attack_distance - 10:
		# Demasiado cerca, retroceder
		var direction = to_enemy.normalized()
		movement_component.set_movement_direction(direction)
		movement_component.set_speed_multiplier(0.7)
	else:
		# Mantener distancia y moverse lateralmente
		var perpendicular = Vector2(-to_enemy.y, to_enemy.x).normalized() * circling_direction
		movement_component.set_movement_direction(perpendicular)
		movement_component.set_speed_multiplier(0.5)

# Función para mantener la distancia ideal de ataque
func _maintain_attack_distance():
	var player = detection_component.get_player()
	if not player:
		return
	
	var distance = entity.global_position.distance_to(player.global_position)
	var direction: Vector2
	
	if distance < entity.ideal_attack_distance - 5:
		# Estamos demasiado cerca, retroceder un poco
		direction = (entity.global_position - player.global_position).normalized()
		movement_component.set_speed_multiplier(0.8)
	elif distance > entity.ideal_attack_distance + 5:
		# Estamos demasiado lejos, acercarnos
		direction = (player.global_position - entity.global_position).normalized()
		movement_component.set_speed_multiplier(1.1)
	else:
		# Distancia perfecta, rodear lateralmente
		var to_enemy = entity.global_position - player.global_position
		direction = Vector2(-to_enemy.y, to_enemy.x).normalized() * circling_direction
		movement_component.set_speed_multiplier(circling_speed_multiplier)
	
	movement_component.set_movement_direction(direction)

# Manejadores de eventos
func _on_fsm_state_changed(old_state, new_state):
	current_fsm_state = new_state
	print("CombatTacticsComponent: FSM cambió a estado " + str(new_state))
	
	if new_state != FSMState.ATTACK:
		# Reseteamos estados si no estamos en ataque
		current_tactic = "none"
		movement_component.set_speed_multiplier(1.0)

func _on_attack_started():
	is_post_attack = false
	is_recovery = false
	
func _on_attack_finished():
	is_post_attack = true
	# Establecer un timer para volver a las tácticas normales
	yield(get_tree().create_timer(retreat_time), "timeout")
	is_post_attack = false
	
	# Iniciar fase de recuperación
	is_recovery = true
	yield(get_tree().create_timer(entity.post_attack_recovery_time), "timeout")
	is_recovery = false
