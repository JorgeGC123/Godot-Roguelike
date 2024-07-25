extends Node2D
class_name PatrolBehavior

export var patrol_radius: float = 100.0
export var patrol_speed: float = 40.0
export var patrol_idle_time: float = 4.0
export var obstacle_detection_radius: float = 40.0
export var wall_avoidance_force: float = 200.0

var patrol_target: Vector2 = Vector2.ZERO
var initial_position: Vector2 = Vector2.ZERO
var parent: Character
var state_machine: FiniteStateMachine
var navigation: Navigation2D

var patrol_timer: Timer
var idle_timer: Timer

var raycast: RayCast2D

func _ready():
	call_deferred("_setup")

func _setup():
	parent = get_parent()
	state_machine = parent.get_node("FiniteStateMachine")
	navigation = get_tree().current_scene.get_node("Rooms")
	
	initial_position = parent.global_position
	set_new_patrol_target()
	
	# Inicialización de patrol_timer
	patrol_timer = Timer.new()
	add_child(patrol_timer)
	patrol_timer.connect("timeout", self, "set_new_patrol_target")
	patrol_timer.set_wait_time(patrol_idle_time)
	patrol_timer.set_one_shot(false) # El timer se repetirá
	patrol_timer.start()
	
	# Inicialización de idle_timer
	idle_timer = Timer.new()
	add_child(idle_timer)
	idle_timer.connect("timeout", self, "end_idle")
	idle_timer.set_one_shot(true)
	
	# Configurar el RayCast2D para detección de obstáculos
	raycast = RayCast2D.new()
	add_child(raycast)
	raycast.enabled = true
	raycast.cast_to = Vector2(obstacle_detection_radius, 0)
	raycast.collision_mask = 1 # Ajusta esto según la capa de colisión de tus obstáculos

func patrol(delta):
	if state_machine.get_state("patrolling"):
		var direction = (patrol_target - parent.global_position).normalized()
		
		# Aplicar fuerza de evitación de obstáculos
		var avoidance_force = check_obstacles()
		direction += avoidance_force
		
		direction = direction.normalized()
		parent.move_and_slide(direction * patrol_speed)
		
		# Voltear el sprite según la dirección del movimiento
		if direction.x < 0:
			parent.animated_sprite.flip_h = true
		elif direction.x > 0:
			parent.animated_sprite.flip_h = false
		
		if parent.global_position.distance_to(patrol_target) < 5:
			start_idle()

func check_obstacles() -> Vector2:
	var avoidance_force = Vector2.ZERO
	for i in range(8): # Comprueba en 8 direcciones
		var angle = i * PI / 4
		raycast.rotation = angle
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var avoid_vector = parent.global_position - collision_point
			avoidance_force += avoid_vector.normalized() * (obstacle_detection_radius - avoid_vector.length()) * wall_avoidance_force
	
	return avoidance_force

func set_new_patrol_target():
	var attempts = 0
	var max_attempts = 10
	var valid_target_found = false

	while attempts < max_attempts and not valid_target_found:
		var random_offset = Vector2(rand_range( - patrol_radius, patrol_radius), rand_range( - patrol_radius, patrol_radius))
		var potential_target = initial_position + random_offset
		var path = navigation.get_simple_path(parent.global_position, potential_target)
		
		if path.size() > 0 and is_point_in_open_space(potential_target):
			patrol_target = potential_target
			valid_target_found = true
		
		attempts += 1

	if valid_target_found:
		state_machine.set_state(state_machine.states.patrolling)
	else:
		# Si no se encuentra un punto válido, quédate en el lugar actual
		start_idle()

func is_point_in_open_space(point: Vector2) -> bool:
	for i in range(8): # Comprueba en 8 direcciones
		var angle = i * PI / 4
		raycast.global_position = point
		raycast.rotation = angle
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			return false
	
	return true

func start_idle():
	state_machine.set_state(state_machine.states.idle)
	if idle_timer:
		idle_timer.start(rand_range(1, patrol_idle_time))
	else:
		print("Error: idle_timer is null")

func end_idle():
	set_new_patrol_target()

func adapt_state_machine(state_machine):
	if not "patrolling" in state_machine.states:
		state_machine._add_state("patrolling")
	
	state_machine.connect("state_logic", self, "_on_state_logic")
	state_machine.connect("get_transition", self, "_on_get_transition")
	state_machine.connect("enter_state", self, "_on_enter_state")

func _on_state_logic(delta):
	if state_machine.state == state_machine.states.patrolling and not state_machine.get_state("dead") and not state_machine.get_state("talking"):
		patrol(delta)

func _on_get_transition():
	match state_machine.state:
		state_machine.states.patrolling:
			if parent.global_position.distance_to(patrol_target) < 5:
				return state_machine.states.idle
		state_machine.states.idle:
			if idle_timer and not idle_timer.is_stopped():
				return state_machine.states.patrolling
	return - 1

func _on_enter_state(previous_state, new_state):
	if new_state == state_machine.states.dead:
		patrol_timer.stop()
		idle_timer.stop()
		parent.velocity = Vector2.ZERO
	elif not state_machine.get_state("dead") and not state_machine.get_state("talking"):
		match new_state:
			state_machine.states.idle:
				parent.animated_sprite.play("idle")
			state_machine.states.patrolling:
				parent.animated_sprite.play("move")
