class_name ComposedEnemy
extends Entity

var is_stunned: bool = false
export var attack_range: float = 40.0
export var ideal_attack_distance: float = 30.0  # Distancia ideal para atacar
export var post_attack_recovery_time: float = 1.2  # Tiempo de recuperación después de un ataque

func _ready():
	add_component("health", HealthComponent.new(self))
	add_component("movement", MovementComponent.new(self))
	add_component("ai", AIComponent.new(self))
	add_component("detection", DetectionComponent.new(self))
	add_component("combat", CombatComponent.new(self))
	add_component("combat_tactics", CombatTacticsComponent.new(self))
	add_component("fsm", EnemyFSMComponent.new(self))
	add_component("stamina", StaminaComponent.new(self))
	#add_component("headbutt", HeadbuttAttackComponent.new(self))
	add_component("blood_splash", BloodSplashComponent.new(self))
	add_component("animation", AnimationComponent.new(self))
	
	# Configurar componente de stamina
	var stamina_component = get_component("stamina")
	stamina_component.max_stamina = 100
	stamina_component.stamina = 100
	stamina_component.stamina_regen_rate = 10.0  # Aumentado para regeneración más rápida
	stamina_component.stamina_regen_delay = 0.8  # Menos retraso en regeneración

	yield(get_tree().create_timer(0.1), "timeout")
	var weapon_scene = preload("res://Weapons/Sword.tscn")
	var weapon_component = EnemyWeaponComponent.new(self, weapon_scene)
	add_component("weapon", weapon_component)
	weapon_component.initialize()
	
	# Configurar el arma para que use menos stamina que el jugador
	if weapon_component.weapon:
		weapon_component.weapon.BASIC_ATTACK_STAMINA = 50
		weapon_component.weapon.CHARGED_ATTACK_STAMINA = 15
		weapon_component.weapon.ABILITY_STAMINA = 25
		print("Arma de enemigo configurada con costes personalizados de stamina")

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

func reduce_stamina(amount: int) -> bool:
	var stamina_component = get_component("stamina")
	if stamina_component:
		return stamina_component.use_stamina(amount)
	return false

func get_stamina() -> int:
	var stamina_component = get_component("stamina")
	if stamina_component:
		return stamina_component.stamina
	return 0

func on_navigation_velocity_computed(safe_velocity: Vector2):
	print("Safe velocity computed: ", safe_velocity)
	print("For entity: ", get_instance_id())
	
	if not is_stunned:  # Importante: verificar si podemos movernos
		var movement_component = get_component("movement")
		if movement_component:
			print("Applying safe velocity to movement component")
			movement_component.set_velocity(safe_velocity)
