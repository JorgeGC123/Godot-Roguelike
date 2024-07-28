extends FSMComponent
class_name EnemyFSMComponent

func _init(entity: Node).(entity):
	_add_state("idle")
	_add_state("chase")
	_add_state("attack")
	_add_state("hurt")
	_add_state("dead")

func initialize():
	set_state(states.idle)

func _state_logic(delta: float):
	match state:
		states.idle:
			entity.get_component("movement").stop()
		states.chase:
			var player = entity.get_component("detection").get_player()
			if player:
				entity.get_component("movement").chase(player)
		states.attack:
			entity.get_component("movement").stop()
			# Lógica de ataque aquí

func _enter_state(previous_state: int, new_state: int):
	match new_state:
		states.idle:
			entity.get_component("movement").stop()
		states.chase:
			# Iniciar animación de movimiento, etc.
			pass
		states.attack:
			entity.get_component("movement").stop()
			#entity.get_component("combat").attack()

func _exit_state(state_exited: int):
	match state_exited:
		states.attack:
			#entity.get_component("combat").end_attack()
			print("end attack")

# Usamos el sistema de mensajes entre la entidad y sus componentes para manejar la lógica de estados

func receive_message(message: String, data: Dictionary):
	match message:
		"player_detected":
			if state == states.idle:
				set_state(states.chase)
		"player_lost":
			if state == states.chase:
				set_state(states.idle)

# Deprecamos por tanto el get_transition para el manejo de estados

# func _get_transition() -> int:
# 	match state:
# 		states.idle:
# 			if entity.get_component("detection").is_player_in_range():
# 				return states.chase
# 		states.chase:
# 			if not entity.get_component("detection").is_player_in_range():
# 				return states.idle
# 		states.attack:
# 			if not entity.get_component("combat").can_attack:
# 				return states.chase
# 	return -1