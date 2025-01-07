# AIComponent.gd
class_name AIComponent
extends Component

var navigation: Navigation2D
var player: KinematicBody2D
var path: PoolVector2Array = []
var movement_component: MovementComponent
var debug_line: Line2D

export var path_update_interval: float = 0.5
export var arrival_threshold: float = 5.0  # Reduced from 10.0
var path_update_timer: float = 0.0

export var debug_draw_path: bool = true

func _init(entity: Node).(entity):
	pass

func initialize():
	navigation = entity.get_node("/root/Game/Rooms")
	player = entity.get_node("/root/Game/Player")
	
	if debug_draw_path:
		debug_line = Line2D.new()
		debug_line.default_color = Color.red
		debug_line.width = 2.0
		add_child(debug_line)
	
	movement_component = entity.get_component("movement")

func update(delta: float):
	if not player or not navigation or not movement_component:
		return

	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		_update_path()

	if not path.empty():
		_follow_path(delta)
		if debug_draw_path and debug_line:
			_update_debug_line()

func _update_path():
	if not is_instance_valid(player):
		return
		
	path = navigation.get_simple_path(
		entity.global_position,
		player.global_position,
		true
	)

func _follow_path(delta: float):
	if path.empty():
		movement_component.stop()
		return

	var target = path[0]
	var distance = entity.global_position.distance_to(target)
	
	if distance < arrival_threshold:
		path.remove(0)
		if path.empty():
			movement_component.stop()
			return
		target = path[0]
	
	var direction = (target - entity.global_position).normalized()
	movement_component.set_movement_direction(direction)

func _update_debug_line() -> void:
	var points = PoolVector2Array()
	points.append(entity.global_position)
	for point in path:
		points.append(point)
	debug_line.points = points
