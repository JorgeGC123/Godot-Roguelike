extends Component
class_name HitboxComponent

# esta es la hitbox del enemigo, la que golpea al jugador cuando se acerca mucho

export var damage: int = 1
export var knockback_force: float = 50.0
export var collision_layer: int = 1
export var collision_mask: int = 1
export var shape: Shape2D

var hitbox_area: Area2D
var collision_shape: CollisionShape2D

func _init(entity: Node).(entity):
	pass

func initialize():
	hitbox_area = Area2D.new()
	hitbox_area.collision_layer = collision_layer
	hitbox_area.collision_mask = collision_mask

	collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape

	hitbox_area.add_child(collision_shape)
	hitbox_area.connect("body_entered", self, "_on_body_entered")

	entity.add_child(hitbox_area)

func _on_body_entered(body):
	print(body)
	print(entity)
	if body.has_method("take_damage") and body != entity:
		print("le endiño")
		var direction = (body.global_position - entity.global_position).normalized()
		body.take_damage(damage, direction, knockback_force)
