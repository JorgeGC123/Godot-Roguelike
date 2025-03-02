extends Weapon

# Importamos explícitamente el script para evitar problemas de referencia
const SwordDefenseHandlerScript = preload("res://Weapons/SwordDefenseHandler.gd")

onready var second_attack_timer: Timer = get_node("SecondAttackTimer")
var defense_handler = null

var in_first_attack: bool = false
var in_second_attack: bool = false

# Procesamiento continuo para actualizar la defensa
func _process(delta):
	# Actualizar la posición defensiva si está activa
	if defense_handler and defense_handler.is_defending:
		defense_handler.update_defense_position()

# Función para capturar eventos de input directamente
func _input(event):
	# Capturar botón derecho del ratón
	if event is InputEventMouseButton and event.button_index == 2:
		if event.pressed: # Botón presionado
			print("DEBUG: Botón derecho presionado")
			
			# Verificar que player esté inicializado
			if player == null:
				print("ERROR: player es null en Sword._input")
				# Intentar inicializar player desde el árbol
				var potential_player = get_parent().get_parent()
				if potential_player is Player:
					player = potential_player
					print("DEBUG: player recuperado del árbol: ", player)
				else:
					print("ERROR: No se pudo recuperar player del árbol")
					return
			
			# Solo proceder si tenemos lo necesario
			if player and defense_handler and player.stamina > 20 and not is_busy():
				print("DEBUG: Condiciones cumplidas, activando defensa")
				# Cancelar ataques activos
				in_first_attack = false
				in_second_attack = false
				
				# Verificar handler
				print("DEBUG: defense_handler.player antes: ", defense_handler.player)
				defense_handler.player = player # Asegurar que handler tiene la referencia actualizada
				
				# Activar defensa
				var success = defense_handler.activate_defense()
				print("DEBUG: Resultado de activate_defense: ", success)
				
				# Consumir el evento
				get_tree().set_input_as_handled()
		else: # Botón liberado
			print("DEBUG: Botón derecho liberado")
			# Desactivar defensa si estaba activa
			if defense_handler:
				defense_handler.deactivate_defense()
				# Consumir el evento
				get_tree().set_input_as_handled()

func _ready() -> void:
	# Intentar inicializar player
	var parent = get_parent()
	if parent and parent.name == "Weapons":
		var potential_player = parent.get_parent()
		if potential_player is Player and player == null:
			player = potential_player
			print("DEBUG: player inicializado desde _ready: ", player)
	
	# Instanciar el manejador de defensa
	print("DEBUG: Creando defense_handler")
	defense_handler = SwordDefenseHandlerScript.new(self)
	if defense_handler != null:
		print("DEBUG: defense_handler creado exitosamente")
		# Asegurarnos que tenga el player actualizado
		if player != null and defense_handler.player == null:
			defense_handler.player = player
			print("DEBUG: Actualizada referencia a player en defense_handler")
	else:
		print("ERROR: No se pudo crear defense_handler")
	
	# Determinar si el arma está equipada basado en la jerarquía de nodos
	var is_equipped = false

	
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
	
	# Nueva habilidad defensiva con botón derecho usando el handler
	if Input.is_action_just_pressed("ui_active_ability") and not is_busy() and player.stamina > 20:
		print("DEBUG: Botón derecho presionado, intentando activar defensa")
		# Cancelar cualquier ataque en progreso
		in_first_attack = false
		in_second_attack = false
		# Verificar handler
		if defense_handler == null:
			print("ERROR: defense_handler es null!")
			return
		# Delegar la defensa al handler
		var success = defense_handler.activate_defense()
		print("DEBUG: Resultado de activate_defense: ", success)
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
	elif Input.is_action_just_pressed("ui_first_quickslot") and animation_player.has_animation("active_ability") and not is_busy() and can_active_ability and player.stamina > 30:
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
		
func _exit_tree() -> void:
	# Aseguramos la limpieza adecuada
	if defense_handler:
		defense_handler.cleanup()
