extends Character
class_name Enemy, "res://Art/v1.1 dungeon crawler 16x16 pixel pack/enemies/goblin/goblin_idle_anim_f0.png"

var path: PoolVector2Array

onready var navigation: Navigation2D = get_tree().current_scene.get_node("Rooms")
onready var player: KinematicBody2D = get_tree().current_scene.get_node("Player")
onready var path_timer: Timer = get_node("PathTimer")
onready var raycast: RayCast2D = RayCast2D.new()

export var detection_radius: int = 150
export var obstacle_avoid_distance: float = 50.0
export var avoid_force: float = 0.5
export var path_follow_weight: float = 1

var avoid_time: float = 0.0
export var max_avoid_time: float = 1.0

# Sistema de memoria a corto plazo
var obstacle_memory: Array = []
export var memory_size: int = 5
export var memory_duration: float = 3.0

# Variables para evitar atascamiento en esquinas
var stuck_time: float = 0.0
export var max_stuck_time: float = 0.25
export var unstuck_force: float = 20000
var last_position: Vector2 = Vector2.ZERO
export var stuck_distance_threshold: float = 0.5

func _ready() -> void:
	var __ = connect("tree_exited", get_parent(), "_on_enemy_killed")
	add_child(raycast)
	raycast.enabled = true
	raycast.collision_mask = 1  # Ajusta esto según la capa de colisión de tus obstáculos
	last_position = global_position

func chase() -> void:
	if path:
		var vector_to_next_point: Vector2 = path[0] - global_position
		var distance_to_next_point: float = vector_to_next_point.length()
		if distance_to_next_point < 3:
			path.remove(0)
			if not path:
				return
		
		var desired_direction = vector_to_next_point.normalized()
		var steering = Vector2.ZERO
		
		# Comprueba obstáculos en múltiples direcciones
		for i in range(-2, 3):
			var angle = i * PI / 4
			raycast.cast_to = desired_direction.rotated(angle) * obstacle_avoid_distance
			raycast.force_raycast_update()
			
			if raycast.is_colliding():
				var collision_point = raycast.get_collision_point()
				_remember_obstacle(collision_point)
				var avoid_vector = global_position - collision_point
				steering += avoid_vector.normalized() * (obstacle_avoid_distance - avoid_vector.length())
				avoid_time = max_avoid_time
		
		# Considera los obstáculos recordados
		for obstacle in obstacle_memory:
			var avoid_vector = global_position - obstacle.position
			if avoid_vector.length() < obstacle_avoid_distance:
				steering += avoid_vector.normalized() * (obstacle_avoid_distance - avoid_vector.length())
		
		# Lógica para evitar atascamiento
		if global_position.distance_to(last_position) < stuck_distance_threshold:
			stuck_time += get_physics_process_delta_time()
		else:
			stuck_time = 0.0
		
		if stuck_time > max_stuck_time:
			# Intenta moverse hacia arriba
			var perpendicular_direction = Vector2(0, -200)
			steering = perpendicular_direction * unstuck_force
		
		if avoid_time > 0 or not steering.is_equal_approx(Vector2.ZERO):
			avoid_time -= get_physics_process_delta_time()
			mov_direction = (steering.normalized() * avoid_force + desired_direction * path_follow_weight).normalized()
		else:
			mov_direction = desired_direction
		
		if mov_direction.x > 0 and animated_sprite.flip_h:
			animated_sprite.flip_h = false
		elif mov_direction.x < 0 and not animated_sprite.flip_h:
			animated_sprite.flip_h = true
		
		last_position = global_position

func _on_PathTimer_timeout() -> void:
	if is_instance_valid(player):
		if(self.global_position.distance_to(player.global_position) < detection_radius):
			_get_path_to_player()
	else:
		path_timer.stop()
		path = []
		mov_direction = Vector2.ZERO
		
func _get_path_to_player() -> void:
	path = navigation.get_simple_path(global_position, player.position)

func _remember_obstacle(position: Vector2) -> void:
	var current_time = OS.get_ticks_msec() / 1000.0
	obstacle_memory.append({"position": position, "time": current_time})
	if obstacle_memory.size() > memory_size:
		obstacle_memory.pop_front()

func _physics_process(delta: float) -> void:
	_forget_old_obstacles()

func _forget_old_obstacles() -> void:
	var current_time = OS.get_ticks_msec() / 1000.0
	var new_obstacle_memory = []
	
	for obstacle in obstacle_memory:
		if current_time - obstacle.time < memory_duration:
			new_obstacle_memory.append(obstacle)
			
	obstacle_memory = new_obstacle_memory
