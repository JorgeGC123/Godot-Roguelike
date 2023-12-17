extends FiniteStateMachine

func _init() -> void:
	_add_state("idle")
	_add_state("hurt")
	_add_state("dead")
	
	
func _ready() -> void:
	set_state(states.idle)
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.dead:
			animation_player.play("dead")


