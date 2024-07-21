extends Area2D
class_name Hitbox

@export var damage: int = 1
var knockback_direction: Vector2 = Vector2.ZERO
@export var knockback_force: int = 300

var body_inside: bool = false

@onready var collision_shape: CollisionShape2D = get_child(0)
@onready var timer: Timer = Timer.new()
signal mpdamage(damage)

func _init() -> void:
	var __ = connect("body_entered", Callable(self, "_on_body_entered"))
	__ = connect("body_exited", Callable(self, "_on_body_exited"))
	
	
func _ready() -> void:
	assert(collision_shape != null)
	timer.wait_time = 1
	add_child(timer)
	
	
func _on_body_entered(body: PhysicsBody2D) -> void:
	body_inside = true
	timer.start()
	while body_inside:
		_collide(body)
		await timer.timeout
	
	
func _on_body_exited(_body: CharacterBody2D) -> void:
	body_inside = false
	timer.stop()
	
	
func _collide(body: CharacterBody2D) -> void:
	print('maldicion hijo')
	print(body)
	print(body.has_method("take_damage"))
	if body == null or not body.has_method("take_damage"):
		queue_free()
	else:
		print('dano takeadisimo, emitiendo señal')
		print(body)
		body.take_damage(damage, knockback_direction, knockback_force)
		#print("Escena actual: ", current_scene)
		print("el body de ",int(body.name)," siente el dolor")
		emit_signal("mpdamage",int(body.name),damage, knockback_direction, knockback_force)
