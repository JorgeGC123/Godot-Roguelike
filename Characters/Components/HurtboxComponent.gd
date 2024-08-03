extends Component
class_name HurtboxComponent


var collision_shape: CollisionShape2D

func _init(entity: Node).(entity):
	pass

func initialize():
	var custom_shape = CircleShape2D.new()
	custom_shape.radius = 7.0  


	collision_shape = CollisionShape2D.new()
	collision_shape.shape = custom_shape

	entity.add_child(collision_shape)
