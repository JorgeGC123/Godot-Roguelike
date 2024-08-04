class_name EnemyFSMComponent
extends FSMComponent

var weapon_component: WeaponComponent

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

func initialize():
	set_state(states.idle)
	weapon_component = entity.get_component("weapon")
	if not weapon_component:
		push_error("WeaponComponent not found in entity")

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
					print("te ataco bro")
					transition = states.attack
				elif not _can_see_player():
					transition = states.idle
			else:
				if _is_player_in_attack_range():
					transition = states.attack
				elif not _can_see_player():
					transition = states.idle
		states.attack:
			if weapon_component and not _is_player_in_attack_range():
				transition = states.chase
			elif weapon_component and not weapon_component.is_charging and not weapon_component.is_attacking:
				transition = states.chase
			else:
				transition = states.chase

	return transition

# func _enter_state(previous_state, new_state):
# 	print("Entering state:", new_state, "from", previous_state)
# 	match new_state:
# 		states.attack:
# 			if weapon_component:
# 				print("Starting charge in attack state")
# 				#weapon_component.start_charge()
# 			else:
# 				push_error("Attempted to use WeaponComponent, but it's not available")

func _exit_state(state_exited):
	match state_exited:
		states.attack:
			if weapon_component:
				weapon_component.cancel_attack()
			else:
				push_error("Attempted to use WeaponComponent, but it's not available")

func _attack_logic(delta: float):
	entity.get_component("movement").stop()
	var player = entity.get_component("detection").get_player()
	if player:
		_update_weapon_direction(player)
	if weapon_component:
		if not weapon_component.is_charging and not weapon_component.is_attacking:
			weapon_component.start_charge()
	else:
		print("otro kind of ataque")

func _idle_logic(delta: float):
	entity.get_component("movement").stop()
	pass

func _chase_logic(delta: float):
	var player = entity.get_component("detection").get_player()
	if player:
		print("te chaseo bro")
		entity.get_component("movement").chase(player)

func _strong_attack_logic(delta: float):
	pass

func _use_ability_logic(delta: float):
	pass

func _retreat_logic(delta: float):
	var player = entity.get_component("detection").get_player()
	if player:
		var retreat_direction = (entity.global_position - player.global_position).normalized()
		entity.get_component("movement").set_movement_direction(retreat_direction)

func _update_weapon_direction(player: Node2D):
	pass

func _can_see_player() -> bool:
	return entity.get_component("detection").is_player_in_range()

func _is_player_in_attack_range() -> bool:
	var player = entity.get_component("detection").get_player()
	if player:
		var distance = entity.global_position.distance_to(player.global_position)
		return distance <= entity.attack_range 
	return false

func _should_use_strong_attack() -> bool:
	# Implementa la lógica para decidir cuándo usar un ataque fuerte
	# Por ejemplo, basado en la salud del jugador, la distancia, o un temporizador
	return false

func _should_use_ability() -> bool:
	# Implementa la lógica para decidir cuándo usar una habilidad
	# Por ejemplo, basado en si la habilidad está disponible y las condiciones son favorables
	return false

func _start_retreat():
	# Implementa lógica adicional para iniciar la retirada si es necesario
	pass

func receive_message(message: String, data: Dictionary):
	match message:
		"player_detected":
			if state == states.idle:
				set_state(states.chase)
		"player_lost":
			if state == states.chase:
				set_state(states.idle)
		"headbutt_preparing":
			set_state(states.headbutt_prepare)
		"headbutt_started":
			set_state(states.headbutt_attack)
		"headbutt_finished":
			set_state(states.chase)
