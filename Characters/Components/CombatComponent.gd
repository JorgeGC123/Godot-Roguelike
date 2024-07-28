class_name CombatComponent
extends Component

export var damage: int = 1
export var attack_cooldown: float = 1.0

var can_attack: bool = true
var attack_timer: Timer

func _init(entity: Node).(entity):
    pass

func initialize():
    attack_timer = Timer.new()
    attack_timer.connect("timeout", self, "_on_attack_timer_timeout")
    entity.add_child(attack_timer)

func attack(target: Node):
    print("en teoria estoy atacando xd")
    if can_attack and target.has_method("take_damage"):
        target.take_damage(damage)
        can_attack = false
        attack_timer.start(attack_cooldown)

func _on_attack_timer_timeout():
    can_attack = true