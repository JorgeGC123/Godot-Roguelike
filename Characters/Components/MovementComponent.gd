# MovementComponent.gd
class_name MovementComponent
extends Component

export var default_speed: float = 20.0
var speed: float = default_speed
export var acceleration: float = 100.0
var velocity: Vector2 = Vector2.ZERO
var speed_multiplier: float = 1.0

onready var animated_sprite: AnimatedSprite = entity.get_node("AnimatedSprite")

func _init(entity: Node).(entity):
	pass

func update(delta: float) -> void:
	if not entity:
		return
		
	#entity.velocity = velocity
	entity.move_and_slide(velocity)

func set_movement_direction(direction: Vector2) -> void:
	if animated_sprite:
		if direction.x > 0 and animated_sprite.flip_h:
			animated_sprite.flip_h = false
		elif direction.x < 0 and not animated_sprite.flip_h:
			animated_sprite.flip_h = true
	
	velocity = direction * default_speed * speed_multiplier

func stop() -> void:
	velocity = Vector2.ZERO

func get_velocity() -> Vector2:
	return velocity

func get_movement_direction() -> Vector2:
	return velocity.normalized()

func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity
	# Actualizar flip_h del sprite según la dirección
	if animated_sprite:
		if velocity.x > 0 and animated_sprite.flip_h:
			animated_sprite.flip_h = false
		elif velocity.x < 0 and not animated_sprite.flip_h:
			animated_sprite.flip_h = true

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = multiplier
