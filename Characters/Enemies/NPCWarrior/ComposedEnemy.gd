class_name ComposedEnemy
extends Entity

var is_stunned: bool = false
export var attack_range: float = 40.0
export var BASIC_ATTACK_STAMINA: int = 5
var stamina: int = 100

func _ready():
	add_component("health", HealthComponent.new(self))
	add_component("movement", MovementComponent.new(self))
	add_component("ai", AIComponent.new(self))
	add_component("detection", DetectionComponent.new(self))
	add_component("combat", CombatComponent.new(self))
	add_component("fsm", EnemyFSMComponent.new(self))
	#add_component("headbutt", HeadbuttAttackComponent.new(self))
	add_component("blood_splash", BloodSplashComponent.new(self))
	add_component("animation", AnimationComponent.new(self))
	

	yield(get_tree().create_timer(0.1), "timeout")
	var weapon_scene = preload("res://Weapons/Sword.tscn")
	var weapon_component = WeaponComponent.new(self, weapon_scene)
	add_component("weapon", weapon_component)
	weapon_component.initialize()

	# esto sería la hitbox tradicional de colisiono y boom me hace daño
	# var hitbox_component = HitboxComponent.new(self)
	# add_component("hitbox", hitbox_component)
	# hitbox_component.damage = 1
	# hitbox_component.knockback_force = 100
	# hitbox_component.collision_layer = 1
	# hitbox_component.collision_mask = 1
	# hitbox_component.shape = CircleShape2D.new()
	# hitbox_component.shape.radius = 12.0
	# yield(get_tree(), "idle_frame")
	# hitbox_component.set_deferred("monitorable", true)
	# hitbox_component.set_deferred("monitoring", true)
	# hitbox_component.initialize()

	var hurtbox_component = HurtboxComponent.new(self)
	add_component("hurtbox", hurtbox_component)

	var health_component = get_component("health")
	health_component.max_health = 2
	health_component.connect("health_changed", self, "_on_health_changed")
	health_component.connect("damaged", self, "_on_damaged")
	health_component.connect("died", self, "_on_died")
	health_component.connect("stun_started", self, "_on_stun_started")
	health_component.connect("stun_ended", self, "_on_stun_ended")
	#health_component.initialize()

	var fsm_component = get_component("fsm")
	fsm_component.connect("state_changed", self, "_on_state_changed")

	for component in components.values():
		component.initialize()

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
	print("ComposedEnemy take_damage called with amount: ", amount, ", direction: ", direction, ", force: ", force)
	print("Stack trace: ", get_stack())
	var health_component = get_component("health")
	if health_component:
		health_component.take_damage(amount, direction, force)
		var bloodsplash_component = get_component("blood_splash")
		if bloodsplash_component:
			bloodsplash_component.spawn_blood_splash(global_position,direction)

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

func _on_state_changed(previous_state, new_state):
	send_message("state_changed", {"previous_state": previous_state, "new_state": new_state})

func reduce_stamina(amount: int):
	stamina = max(0, stamina - amount)

func on_navigation_velocity_computed(safe_velocity: Vector2):
	print("Safe velocity computed: ", safe_velocity)
	print("For entity: ", get_instance_id())
	
	if not is_stunned:  # Importante: verificar si podemos movernos
		var movement_component = get_component("movement")
		if movement_component:
			print("Applying safe velocity to movement component")
			movement_component.set_velocity(safe_velocity)
