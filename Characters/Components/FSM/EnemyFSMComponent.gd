class_name EnemyFSMComponent
extends FSMComponent

var weapon_component: WeaponComponent
var generic_atack_component: GenericAttackComponent

func _init(entity: Node).(entity):
	_add_state("idle")
	_add_state("chase")
	_add_state("attack")
	_add_state("strong_attack")
	_add_state("use_ability")
	_add_state("retreat")
	_add_state("hurt")
	_add_state("dead")
	_add_state("headbutt_prepare")
	_add_state("headbutt_attack")
	Logger.debug("Estados FSM inicializados", "Enemy/FSM")

func initialize():
	set_state(states.idle)
	weapon_component = entity.get_component("weapon")
	generic_atack_component = entity.get_component("attack")
	if not weapon_component:
		Logger.error("WeaponComponent no encontrado en la entidad", "Enemy/FSM")
		push_error("WeaponComponent not found in entity")
	else:
		Logger.debug("WeaponComponent inicializado correctamente", "Enemy/FSM")

func _state_logic(delta: float):
	match state:
		states.idle:
			_idle_logic(delta)
		states.chase:
			_chase_logic(delta)
		states.attack:
			_attack_logic(delta)
		states.strong_attack:
			_strong_attack_logic(delta)
		states.use_ability:
			_use_ability_logic(delta)
		states.retreat:
			_retreat_logic(delta)

func _get_transition() -> int:
	var obstacle_avoidance = entity.get_component("obstacle_avoidance")
	var transition = -1
	match state:
		states.idle:
			if _can_see_player():
				transition = states.chase
		states.chase:
			if weapon_component:
				if _is_player_in_attack_range() and not weapon_component.is_charging and not weapon_component.is_attacking and not obstacle_avoidance.is_obstacle_to_player():
					transition = states.attack
				elif not _can_see_player():
					transition = states.idle
			else:
				if _is_player_in_attack_range():
					transition = states.attack
				elif not _can_see_player():
					transition = states.idle
		states.attack:
			# Solo salimos de ATTACK si:
			if weapon_component:
				if not _is_player_in_attack_range():
					# El jugador está fuera de rango
					transition = states.chase
				elif not weapon_component.is_charging and not weapon_component.is_attacking:
					# El ataque ha terminado completamente
					transition = states.chase
			# Si no cumple ninguna condición, se mantiene en ATTACK

	return transition

func _exit_state(state_exited):
	match state_exited:
		states.attack:
			if weapon_component:
				Logger.debug("Cancelando ataque al salir del estado ATTACK", "Enemy/FSM")
				weapon_component.cancel_attack()
			else:
				Logger.error("Intento de usar WeaponComponent no disponible", "Enemy/FSM")
				push_error("Attempted to use WeaponComponent, but it's not available")

func _attack_logic(delta: float):
	Logger.debug("Ejecutando lógica de ataque", "Enemy/FSM")
	entity.get_component("movement").stop()
	var player = entity.get_component("detection").get_player()
	if player:
		_update_weapon_direction(player)
		Logger.debug("Actualizando dirección del arma hacia el jugador", "Enemy/FSM")
	
	if weapon_component:
		if not weapon_component.is_charging and not weapon_component.is_attacking:
			Logger.info("Iniciando carga de ataque", "Enemy/FSM")
			weapon_component.start_charge()
	else:
		if generic_atack_component:
			Logger.debug("Ejecutando ataque genérico (sin arma)", "Enemy/FSM")
			generic_atack_component.start_attack()
		Logger.debug("No ejecuto ataque ya que no tengo componente", "Enemy/FSM")

func _idle_logic(delta: float):
	entity.get_component("movement").stop()
	Logger.debug("Estado IDLE: enemigo detenido", "Enemy/FSM")

func _chase_logic(delta: float):
	var player = entity.get_component("detection").get_player()
	if player:
		# Logger.debug("Persiguiendo al jugador", "Enemy/FSM")
		entity.get_component("movement").chase(player)

func _strong_attack_logic(delta: float):
	# Logger.debug("Lógica de ataque fuerte (no implementada)", "Enemy/FSM")
	pass

func _use_ability_logic(delta: float):
	# Logger.debug("Lógica de uso de habilidad (no implementada)", "Enemy/FSM")
	pass

func _retreat_logic(delta: float):
	var player = entity.get_component("detection").get_player()
	if player:
		var retreat_direction = (entity.global_position - player.global_position).normalized()
		#Logger.debug("Retrocediendo del jugador, dirección: %s" % retreat_direction, "Enemy/FSM")
		entity.get_component("movement").set_movement_direction(retreat_direction)

func _update_weapon_direction(player: Node2D):
	if weapon_component:
		# Calculamos el vector dirección hacia el jugador
		var direction = (player.global_position - entity.global_position).normalized()

		if direction.x < 0:
			weapon_component.move(Vector2.LEFT)
			
		else:
			weapon_component.move(Vector2.RIGHT)


func _can_see_player() -> bool:
	var can_see = entity.get_component("detection").is_player_in_range()
	Logger.debug("Comprobando visibilidad del jugador: %s" % can_see, "Enemy/FSM")
	return can_see

func _is_player_in_attack_range() -> bool:
	var player = entity.get_component("detection").get_player()
	if player:
		var distance = entity.global_position.distance_to(player.global_position)
		var in_range = distance <= entity.attack_range
		Logger.debug("Distancia al jugador: %f (rango máximo: %f) - En rango: %s" % 
			[distance, entity.attack_range, in_range], "Enemy/FSM")
		return in_range
	return false

func _should_use_strong_attack() -> bool:
	return false

func _should_use_ability() -> bool:
	return false

func _start_retreat():
	pass

func receive_message(message: String, data: Dictionary):
	Logger.debug("Mensaje recibido: %s" % message, "Enemy/FSM")
	match message:
		"player_detected":
			if state == states.idle:
				Logger.info("Jugador detectado, cambiando a estado CHASE", "Enemy/FSM")
				set_state(states.chase)
		"player_lost":
			if state == states.chase:
				Logger.info("Jugador perdido, cambiando a estado IDLE", "Enemy/FSM")
				set_state(states.idle)
		"headbutt_preparing":
			Logger.info("Preparando headbutt", "Enemy/FSM")
			set_state(states.headbutt_prepare)
		"headbutt_started":
			Logger.info("Iniciando headbutt", "Enemy/FSM")
			set_state(states.headbutt_attack)
		"headbutt_finished":
			Logger.info("Headbutt finalizado", "Enemy/FSM")
			set_state(states.chase)
		"attack_finished":
			print("recidibod bro")
			set_state(states.chase)
