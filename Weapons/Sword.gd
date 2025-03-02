extends Weapon

onready var second_attack_timer: Timer = get_node("SecondAttackTimer")  # Asumiendo que has añadido este nodo

var in_first_attack: bool = false
var in_second_attack: bool = false

func _ready() -> void:
	# Determinar si el arma está equipada basado en la jerarquía de nodos
	var is_equipped = false
	var parent = get_parent()
	
	# Verificar si el arma está en un nodo Weapons (equipada)
	if parent and parent.name == "Weapons":
		is_equipped = true
	
	# Solo activar on_floor si no está equipada
	if not is_equipped:
		on_floor = true
	else:
		# Cuando está equipada, asegurarse de que on_floor sea false
		on_floor = false
	
	# Llamar al _ready de la clase padre (que ahora configurará correctamente el PlayerDetector)
	._ready()
	
	# Asegurarnos de que el PlayerDetector tenga una forma de colisión adecuada
	var detector_shape = player_detector.get_node("CollisionShape2D")
	if not detector_shape.shape:
		var capsule_shape = CapsuleShape2D.new()
		capsule_shape.radius = 5.0
		capsule_shape.height = 8.0
		detector_shape.shape = capsule_shape
		detector_shape.position = Vector2(-5, -8)
		detector_shape.rotation = 1.5708  # ~90 grados en radianes
	
	# Configurar detector según si está equipada o no
	if is_equipped:
		# Si está equipada, desactivar el detector
		detector_shape.disabled = true
		player_detector.set_collision_mask_bit(1, false)
		player_detector.set_collision_mask_bit(0, false)
	else:
		# Si está en el suelo, activar el detector
		detector_shape.disabled = false
		player_detector.set_collision_mask_bit(1, true)  # Detectar al jugador
		player_detector.set_collision_mask_bit(0, true)  # También detectar al mundo si es necesario
	
	# Imprimir estado para depuración
	print("Sword ready - is_equipped: ", is_equipped, ", on_floor: ", on_floor)
	print("PlayerDetector shape: ", detector_shape.shape)
	print("PlayerDetector disabled: ", detector_shape.disabled)

func get_input() -> void:
	if is_busy_with_active_ability():
		return
	if Input.is_action_just_pressed("ui_attack") and player.stamina > 20:
		if in_first_attack:
			animation_player.play("attack2")
			emit_signal("weapon_animation_changed", "attack2")
			in_first_attack = false
			second_attack_timer.stop()  	
		elif not animation_player.is_playing():
			animation_player.play("charge")
			emit_signal("weapon_animation_changed", "charge")
	elif Input.is_action_just_released("ui_attack"):
		if animation_player.is_playing() and animation_player.current_animation == "charge":
			animation_player.play("attack")
			emit_signal("weapon_animation_changed", "attack")
		elif charge_particles.emitting and player.stamina > 50:
			animation_player.play("strong_attack")
			emit_signal("weapon_animation_changed", "strong_attack")
	elif Input.is_action_just_pressed("ui_active_ability") and animation_player.has_animation("active_ability") and not is_busy() and can_active_ability and player.stamina > 30:
		can_active_ability = false
		in_first_attack = false
		in_second_attack = false
		cool_down_timer.start()
		ui.recharge_ability_animation(cool_down_timer.wait_time)
		animation_player.play("active_ability")
		emit_signal("weapon_animation_changed", "active_ability")

func _on_SecondAttackTimer_timeout() -> void:
	if in_first_attack:
		animation_player.play("recover_stance")
		emit_signal("weapon_animation_changed", "recover_stance")
		in_first_attack = false
	elif in_second_attack:
		in_second_attack = false
		
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "attack":
		in_first_attack = true
		in_second_attack = false
		second_attack_timer.start()  # Iniciar temporizador para segundo ataque

	elif anim_name == "attack2":
		in_first_attack = false  # Asegurar que no se pueda realizar un tercer ataque
		in_second_attack = true
		second_attack_timer.start()  # Iniciar temporizador para segundo ataque
		#animation_player.play("recover_stance")

func is_busy_with_active_ability() -> bool:
	return animation_player.is_playing() and animation_player.current_animation == "active_ability"
		
func stamina_tax(amount: int) -> void:
	var character = get_parent().get_parent() # TODO: mejorar esto
	if(character is Player):
		character.reduce_stamina(amount)

func _on_AnimationPlayer_animation_started(anim_name:String):
	if anim_name == "attack":
		stamina_tax(20) # TODO: constantes y futuros incrementos/decrementos por skills pasivas
	elif anim_name == "attack2":
		stamina_tax(20)
	elif anim_name == "strong_attack":
		stamina_tax(50)
	elif anim_name == "active_ability":
		stamina_tax(30)
