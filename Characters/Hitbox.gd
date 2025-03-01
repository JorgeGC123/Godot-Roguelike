extends Area2D
class_name Hitbox

export(int) var damage: int = 1
var knockback_direction: Vector2 = Vector2.ZERO
export(int) var knockback_force: int = 300

var body_inside: bool = false

onready var collision_shape: CollisionShape2D = get_child(0)
onready var timer: Timer = Timer.new()
signal mpdamage(damage)

func _init() -> void:
	var __ = connect("body_entered", self, "_on_body_entered")
	__ = connect("body_exited", self, "_on_body_exited")
	
	
func _ready() -> void:
	assert(collision_shape != null)
	timer.wait_time = 1
	add_child(timer)
	
	
func _on_body_entered(body: PhysicsBody2D) -> void:
	body_inside = true
	timer.start()
	while body_inside:
		_collide(body)
		yield(timer, "timeout")
	
	
func _on_body_exited(_body: KinematicBody2D) -> void:
	body_inside = false
	timer.stop()
	
	
func _collide(body) -> void:
	print('maldicion hijo')
	if body == null or not body.has_method("take_damage"):
		return
	else:
		print('dano takeadisimo, emitiendo señal')
		print(body)
		if knockback_direction == Vector2.ZERO:
			position = body.to_local(self.global_position)
			knockback_direction = position *-1
			knockback_force = 50
		body.take_damage(damage, knockback_direction, knockback_force)
		#print("Escena actual: ", current_scene)
		print("el body de ",int(body.name)," siente el dolor")
		emit_signal("mpdamage",int(body.name),damage, knockback_direction, knockback_force)
