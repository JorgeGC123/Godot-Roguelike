class_name MovementComponent
extends Component

export var default_speed: float = 20.0
var speed: float = default_speed
export var acceleration: float = 100.0
export var friction: float = 100.0
var velocity: Vector2 = Vector2.ZERO
var multiplier: float = 1
onready var animated_sprite: AnimatedSprite = entity.get_node("AnimatedSprite")

const PRIORITY_LOW = 0
const PRIORITY_MEDIUM = 1
const PRIORITY_HIGH = 2

var forces: Dictionary = {}

func _init(entity: Node).(entity):
	pass

func update(delta: float) -> void:
	apply_friction(delta)
	apply_forces(delta)
	velocity = velocity.clamped(speed) * multiplier
	entity.move_and_slide(velocity)
	clear_forces()

func set_movement_direction(direction: Vector2) -> void:
	if animated_sprite:
		if direction.x > 0 and animated_sprite.flip_h:
				animated_sprite.flip_h = false
		elif direction.x < 0 and not animated_sprite.flip_h:
				animated_sprite.flip_h = true
		apply_force(direction.normalized() * acceleration, PRIORITY_MEDIUM)

func apply_force(force: Vector2, priority: int = PRIORITY_MEDIUM) -> void:
	if not forces.has(priority):
		forces[priority] = Vector2.ZERO
	forces[priority] += force

func apply_friction(delta: float) -> void:
	if velocity.length() > 0:
		velocity -= velocity.normalized() * friction * delta

func apply_forces(delta: float) -> void:
	var total_force = Vector2.ZERO
	for priority in [PRIORITY_HIGH, PRIORITY_MEDIUM, PRIORITY_LOW]:
		if forces.has(priority):
			total_force += forces[priority]
	velocity += total_force * delta

func clear_forces() -> void:
	forces.clear()

func stop() -> void:
	velocity = Vector2.ZERO
	clear_forces()
	speed = default_speed  # Reset speed to default when stopping

func chase(target: Node2D) -> void:
	if is_instance_valid(target):
		var direction = (target.global_position - entity.global_position).normalized()
		set_movement_direction(direction)

func get_velocity() -> Vector2:
	return velocity
