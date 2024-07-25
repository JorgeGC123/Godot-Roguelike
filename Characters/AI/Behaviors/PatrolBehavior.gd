extends Node2D
class_name PatrolBehavior

export var patrol_radius: float = 100.0
export var patrol_speed: float = 50.0
export var patrol_idle_time: float = 5.0

var patrol_target: Vector2 = Vector2.ZERO
var initial_position: Vector2 = Vector2.ZERO
var parent: Character
var state_machine: FiniteStateMachine
var navigation: Navigation2D

var patrol_timer: Timer
var idle_timer: Timer

func _ready():
	call_deferred("_setup")

func _setup():
	parent = get_parent()
	state_machine = parent.get_node("FiniteStateMachine")
	navigation = get_tree().current_scene.get_node("Rooms")
	
	initial_position = parent.global_position
	set_new_patrol_target()
	
	patrol_timer = Timer.new()
	add_child(patrol_timer)
	patrol_timer.connect("timeout", self, "set_new_patrol_target")
	patrol_timer.set_wait_time(patrol_idle_time)
	patrol_timer.start()
	
	idle_timer = Timer.new()
	add_child(idle_timer)
	idle_timer.connect("timeout", self, "end_idle")
	idle_timer.set_one_shot(true)

func patrol(delta):
	if state_machine.get_state("patrolling"):
		var direction = (patrol_target - parent.global_position).normalized()
		parent.move_and_slide(direction * patrol_speed)
		
		# Voltear el sprite según la dirección del movimiento
		if direction.x < 0:
			parent.animated_sprite.flip_h = true
		elif direction.x > 0:
			parent.animated_sprite.flip_h = false
		
		if parent.global_position.distance_to(patrol_target) < 5:
			start_idle()

func set_new_patrol_target():
	var random_offset = Vector2(rand_range(-patrol_radius, patrol_radius), rand_range(-patrol_radius, patrol_radius))
	var potential_target = initial_position + random_offset
	patrol_target = navigation.get_closest_point(potential_target)
	state_machine.set_state(state_machine.states.patrolling)

func start_idle():
	state_machine.set_state(state_machine.states.idle)
	idle_timer.start(rand_range(1, patrol_idle_time))

func end_idle():
	set_new_patrol_target()

func adapt_state_machine(state_machine):
	if not "patrolling" in state_machine.states:
		state_machine._add_state("patrolling")
	
	# No reemplazamos las funciones, sino que las extendemos
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
	return -1

func _on_enter_state(previous_state, new_state):
	if new_state == state_machine.states.dead:
		# Stop all movement and timers when dead
		patrol_timer.stop()
		idle_timer.stop()
		parent.velocity = Vector2.ZERO
	elif not state_machine.get_state("dead") and not state_machine.get_state("talking"):
		match new_state:
			state_machine.states.idle:
				parent.animated_sprite.play("idle")
			state_machine.states.patrolling:
				parent.animated_sprite.play("move")
