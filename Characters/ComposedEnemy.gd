class_name ComposedEnemy
extends KinematicBody2D

var components: Dictionary = {}
var is_stunned: bool = false

func _ready():
	add_component("health", HealthComponent.new(self))
	add_component("movement", MovementComponent.new(self))
	add_component("ai", AIComponent.new(self))
	add_component("detection", DetectionComponent.new(self))
	add_component("combat", CombatComponent.new(self))
	add_component("obstacle_avoidance", ObstacleAvoidanceComponent.new(self))

	var hitbox_component = HitboxComponent.new(self)
	hitbox_component.damage = 1
	hitbox_component.knockback_force = 100
	hitbox_component.collision_layer = 1
	hitbox_component.collision_mask = 1
	hitbox_component.shape = CircleShape2D.new()
	hitbox_component.shape.radius = 12.0
	add_component("hitbox", hitbox_component)

	var health_component = get_component("health")
	health_component.max_health = 2
	health_component.connect("health_changed", self, "_on_health_changed")
	health_component.connect("damaged", self, "_on_damaged")
	health_component.connect("died", self, "_on_died")
	health_component.connect("stun_started", self, "_on_stun_started")
	health_component.connect("stun_ended", self, "_on_stun_ended")

func _physics_process(delta: float):
	if not is_stunned:
		for component_name in components:
			components[component_name].update(delta)
	else:
		# Durante el stun, solo actualiza el MovementComponent para aplicar el knockback
		components["movement"].update(delta)

func add_component(component_name: String, component: Component):
	components[component_name] = component
	add_child(component)
	component.initialize()

func get_component(component_name: String) -> Component:
	return components.get(component_name)

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO, force: float = 0):
	print("ComposedEnemy take_damage called")
	var health_component = get_component("health")
	if health_component:
		health_component.take_damage(amount, direction, force)

func _on_health_changed(new_health: int):
	print("Enemy health changed to: ", new_health)

func _on_damaged(amount: int):
	print("Enemy took ", amount, " damage")

func _on_died():
	print("Enemy died")
	queue_free()

func _on_stun_started(duration: float):
	print("Enemy stunned for ", duration, " seconds")
	is_stunned = true

func _on_stun_ended():
	print("Enemy stun ended")
	is_stunned = false

func _on_HitboxArea_body_entered(body):
	if body.is_in_group("player"):
		var combat_component = get_component("combat")
		if combat_component:
			combat_component.attack(body)
