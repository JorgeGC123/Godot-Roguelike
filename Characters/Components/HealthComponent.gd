class_name HealthComponent
extends Component

signal health_changed(new_health)
signal damaged(amount)
signal died()
signal stun_started(duration)
signal stun_ended()

export var max_health: int = 40
var current_health: int setget set_health, get_health
var is_stunned: bool = false
var stun_timer: Timer

func _init(entity: Node).(entity):
    pass

func initialize():
    current_health = max_health
    stun_timer = Timer.new()
    stun_timer.one_shot = true
    stun_timer.connect("timeout", self, "_on_stun_timer_timeout")
    add_child(stun_timer)

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO, force: float = 0):
    set_health(current_health - amount)
    emit_signal("damaged", amount)
    
    var movement = entity.get_component("movement")
    if movement and direction != Vector2.ZERO:
        print("Applying knockback force: ", direction * force)
        movement.apply_force(direction * force *50, MovementComponent.PRIORITY_HIGH)
    
    # Aplicar stun
    apply_stun(0.5)  # 0.5 segundos de stun
    
    if current_health <= 0:
        emit_signal("died")

func apply_stun(duration: float):
    is_stunned = true
    stun_timer.start(duration)
    emit_signal("stun_started", duration)

func _on_stun_timer_timeout():
    is_stunned = false
    emit_signal("stun_ended")

func set_health(value: int):
    var prev_health = current_health
    current_health = clamp(value, 0, max_health)
    if current_health != prev_health:
        emit_signal("health_changed", current_health)

func get_health() -> int:
    return current_health