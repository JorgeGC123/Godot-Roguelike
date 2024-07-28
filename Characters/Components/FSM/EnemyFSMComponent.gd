extends FSMComponent
class_name EnemyFSMComponent

func _init(entity: Node).(entity):
	_add_state("idle")
	_add_state("chase")
	_add_state("attack")
	_add_state("hurt")
	_add_state("dead")
	_add_state("headbutt_prepare")
	_add_state("headbutt_attack")

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
		states.headbutt_prepare:
			entity.get_component("movement").stop()
			entity.get_component("headbutt").update(delta)
		states.headbutt_attack:
			entity.get_component("headbutt").update(delta)


func _enter_state(previous_state: int, new_state: int):
	match new_state:
		states.idle:
			entity.get_component("movement").stop()
		states.attack:
			entity.get_component("movement").stop()


func _exit_state(state_exited: int):
	match state_exited:
		states.headbutt_attack:
			entity.get_component("movement").stop()

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
