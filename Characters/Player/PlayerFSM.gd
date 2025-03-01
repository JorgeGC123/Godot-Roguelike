extends FiniteStateMachine


func _init() -> void:
	_add_state("idle")
	_add_state("move")
	_add_state("hurt")
	_add_state("dead")
	_add_state("inventory_open")
	
	
func _ready() -> void:
	set_state(states.idle)
	
	
func _state_logic(_delta: float) -> void:
	# Solo procesar entradas y movimiento si no estamos en el estado de inventario
	if state == states.idle or state == states.move:
		parent.get_input()
		parent.move()
	# En el estado de inventario, no procesamos ninguna entrada ni movimiento
	
	
func _get_transition() -> int:
	match state:
		states.idle:
			if parent.velocity.length() > 10:
				return states.move
		states.move:
			if parent.velocity.length() < 10:
				return states.idle
		states.hurt:
			if not animation_player.is_playing():
				return states.idle
		states.inventory_open:
			# Verificar si el inventario ya no está abierto para regresar al estado idle
			if not InventoryDisplayManager.is_inventory_visible():
				return states.idle
	return -1
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.move:
			animation_player.play("move")
		states.hurt:
			animation_player.play("hurt")
			parent.cancel_attack()
		states.dead:
			animation_player.play("dead")
			parent.cancel_attack()
		states.inventory_open:
			animation_player.play("idle")
			parent.cancel_attack()
