class_name AIComponent
extends Component

var navigation: Navigation2D
var player: KinematicBody2D
var path: PoolVector2Array

func _init(entity: Node).(entity):
    pass

func initialize():
    navigation = entity.get_node("/root/Game/Rooms")
    player = entity.get_node("/root/Game/Player")

func update(delta: float):
    if player and navigation:
        path = navigation.get_simple_path(entity.global_position, player.global_position)
        if path.size() > 1:
            var direction = (path[1] - entity.global_position).normalized()
            entity.get_component("movement").set_movement_direction(direction)
