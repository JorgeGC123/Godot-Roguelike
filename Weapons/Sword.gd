extends Weapon

onready var second_attack_timer: Timer = get_node("SecondAttackTimer")  # Asumiendo que has añadido este nodo

var in_first_attack: bool = false
var in_second_attack: bool = false

func get_input() -> void:
	if is_busy_with_active_ability():
		return
	if Input.is_action_just_pressed("ui_attack"):
		print('foks')
		if in_first_attack:
			animation_player.play("attack2")
			in_first_attack = false
			second_attack_timer.stop()  	
			print('attack2')
		elif not animation_player.is_playing():
			animation_player.play("charge")
	elif Input.is_action_just_released("ui_attack"):
		if animation_player.is_playing() and animation_player.current_animation == "charge":
			print("attack1")
			animation_player.play("attack")
		elif charge_particles.emitting:
			animation_player.play("strong_attack")
	elif Input.is_action_just_pressed("ui_active_ability") and animation_player.has_animation("active_ability") and not is_busy() and can_active_ability:
		can_active_ability = false
		in_first_attack = false
		in_second_attack = false
		cool_down_timer.start()
		ui.recharge_ability_animation(cool_down_timer.wait_time)
		animation_player.play("active_ability")

func _on_SecondAttackTimer_timeout() -> void:
	if in_first_attack:
		print('timeouteadisimo')
		animation_player.play("recover_stance")
		in_first_attack = false
	elif in_second_attack:
		in_second_attack = false
		
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		in_first_attack = true
		in_second_attack = false
		second_attack_timer.start()  # Iniciar temporizador para segundo ataque

		print("se lanza temporizador")
	elif anim_name == "attack2":
		in_first_attack = false  # Asegurar que no se pueda realizar un tercer ataque
		in_second_attack = true
		second_attack_timer.start()  # Iniciar temporizador para segundo ataque
		print("se lanza temporizador")
		#animation_player.play("recover_stance")

func is_busy_with_active_ability() -> bool:
	return animation_player.is_playing() and animation_player.current_animation == "active_ability"
		
