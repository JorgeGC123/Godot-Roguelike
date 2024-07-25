extends FiniteStateMachine

signal state_logic(delta)
signal get_transition
signal enter_state(previous_state, new_state)

func _init() -> void:
	_add_state("idle")
	_add_state("hurt")
	_add_state("dead")
	_add_state("patrolling")
	_add_state("talking")

func _ready() -> void:
	set_state(states.idle)

func _state_logic(delta: float) -> void:
	emit_signal("state_logic", delta)

func _get_transition() -> int:
	emit_signal("get_transition")
	return -1

func _enter_state(previous_state: int, new_state: int) -> void:
	emit_signal("enter_state", previous_state, new_state)
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.patrolling:
			print("playeo move")
			animation_player.play("move")
		states.dead:
			animation_player.play("dead")
			flipear_verticalmente()
