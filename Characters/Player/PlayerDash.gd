extends Node
class_name PlayerDash
signal dash_started
signal dash_ended

var dash_speed: float = 300
var dash_duration: float = 0.15
var dash_cooldown: float = 1.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2()

var dash_timer: Timer = Timer.new()
var cooldown_remaining: float = 0.0  # Tiempo restante de cooldown

func _ready():
	add_child(dash_timer)
	dash_timer.connect("timeout", self, "_on_dash_timer_timeout")

func _process(delta: float):
	if cooldown_remaining > 0:
		cooldown_remaining -= delta

func start_dash(direction: Vector2):
	if is_dashing or cooldown_remaining > 0:
		return
	dash_direction = direction.normalized()
	if dash_direction.length() == 0:
		dash_direction = Vector2(1, 0)
	is_dashing = true
	emit_signal("dash_started", dash_direction)
	dash_timer.start(dash_duration)

func _on_dash_timer_timeout():
	is_dashing = false
	emit_signal("dash_ended")
	dash_timer.stop()
	cooldown_remaining = dash_cooldown  # Reinicia el tiempo de cooldown

func is_dash_available():
	var available = not is_dashing and cooldown_remaining <= 0
	return available
