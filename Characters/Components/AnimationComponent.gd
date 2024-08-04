class_name AnimationComponent
extends Component

var animated_sprite: AnimatedSprite

func _init(entity: Node).(entity):
	pass

func initialize():
	# Asumimos que el entity ya tiene un AnimatedSprite como hijo
	animated_sprite = entity.get_node("AnimatedSprite")
	if not animated_sprite:
		push_error("AnimatedSprite not found in entity")
	
	# Configurar animaciones
	#_setup_animations()
	
	# Iniciar con la animación de idle
	play_animation("idle")

func _setup_animations():
	# Aquí se configuran las animaciones
	# Por ejemplo:
	if animated_sprite:
		animated_sprite.frames = load("res://path/to/your/spriteframes.tres")

func play_animation(animation_name: String):
	if animated_sprite and animated_sprite.frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		push_error("Animation not found: " + animation_name)

func update(_delta: float):
	# Aquí puedes añadir lógica que se ejecute cada frame si es necesario
	pass

func receive_message(message: String, data: Dictionary):
	match message:
		"state_changed":
			# Cambia la animación basándote en el nuevo estado
			var new_state = data.get("new_state")
			match new_state:
				"idle":
					play_animation("idle")
				"chase":
					play_animation("run")
				"attack":
					play_animation("attack")
				"headbutt_prepare":
					play_animation("prepare_headbutt")
				"headbutt_attack":
					play_animation("headbutt")
