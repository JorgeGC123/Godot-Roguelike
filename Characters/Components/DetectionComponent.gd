class_name DetectionComponent
extends Component

export var detection_radius: float = 100.0

var player: KinematicBody2D

func _init(entity: Node).(entity):
    pass

func initialize():
    player = entity.get_node("/root/Game/Player")

func update(delta: float):
    if player and entity.global_position.distance_to(player.global_position) <= detection_radius:
        entity.get_component("ai").update(delta)
    else:
        entity.get_component("movement").set_movement_direction(Vector2.ZERO)