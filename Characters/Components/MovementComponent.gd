class_name MovementComponent
extends Component

export var speed: float = 50.0
export var acceleration: float = 100.0
export var friction: float = 100.0
var velocity: Vector2 = Vector2.ZERO setget ,get_velocity
var forces: Dictionary = {}

const PRIORITY_LOW = 0
const PRIORITY_MEDIUM = 1
const PRIORITY_HIGH = 2

func _init(entity: Node).(entity):
	pass

func update(delta: float) -> void:
	apply_friction(delta)
	apply_forces(delta)
	velocity = velocity.clamped(speed)
	entity.move_and_slide(velocity)
	clear_forces()

func set_movement_direction(direction: Vector2) -> void:
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

func get_velocity() -> Vector2:
	return velocity
