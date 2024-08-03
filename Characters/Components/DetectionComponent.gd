class_name DetectionComponent
extends Component

export var detection_radius: float = 75.0

var player: KinematicBody2D
var is_player_detected: bool = false

func _init(entity: Node).(entity):
	pass

func initialize():
	player = entity.get_node("/root/Game/Player")

func update(delta: float):
	var was_player_detected = is_player_detected
	is_player_detected = false
	
	if player:
		if entity.global_position.distance_to(player.global_position) <= detection_radius:
			is_player_detected = true
			entity.get_component("ai").update(delta)
		else:
			entity.get_component("movement").set_movement_direction(Vector2.ZERO)
	
	if was_player_detected != is_player_detected:
		if is_player_detected:
			entity.send_message("player_detected", {"player": player})
		else:
			entity.send_message("player_lost", {})

func get_player() -> KinematicBody2D:
	return player

func is_player_in_range() -> bool:
	return is_player_detected
