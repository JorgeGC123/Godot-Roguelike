class_name ObstacleAvoidanceComponent
extends Component

export var avoid_distance: float = 60.0
export var avoid_force: float = 60.0
export var num_rays: int = 16
export var ray_angle: float = PI * 1.5

var raycast: RayCast2D
var movement_component: MovementComponent
var health_component: HealthComponent
var influence_reduction_timer: Timer
var current_influence: float = 1.0

func _init(entity: Node).(entity):
	pass

func initialize():
	raycast = RayCast2D.new()
	raycast.enabled = true
	entity.add_child(raycast)
	movement_component = entity.get_component("movement")
	health_component = entity.get_component("health")
	
	influence_reduction_timer = Timer.new()
	influence_reduction_timer.one_shot = true
	influence_reduction_timer.connect("timeout", self, "_on_influence_reduction_timeout")
	add_child(influence_reduction_timer)
	
	health_component.connect("stun_started", self, "_on_stun_started")

func update(delta: float):
	if health_component.is_stunned:
		return

	var steering = Vector2.ZERO
	var obstacle_count = 0

	for i in range(num_rays):
		var angle = (i / float(num_rays)) * ray_angle - ray_angle / 2
		raycast.cast_to = Vector2.RIGHT.rotated(angle) * avoid_distance
		raycast.force_raycast_update()

		if raycast.is_colliding():
			var collision_point = raycast.get_collision_point()
			var avoid_vector = entity.global_position - collision_point
			steering += avoid_vector.normalized() * (avoid_distance - avoid_vector.length())
			obstacle_count += 1

	if obstacle_count > 0:
		steering /= obstacle_count
		steering = steering.normalized() * avoid_force * current_influence
		movement_component.apply_force(steering, MovementComponent.PRIORITY_LOW)

	if obstacle_count > 0 and movement_component.get_velocity().length() < 10:
		var random_force = Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * avoid_force * 0.5 * current_influence
		movement_component.apply_force(random_force, MovementComponent.PRIORITY_LOW)

func _on_stun_started(duration: float):
	current_influence = 0.1  # Reduce la influencia al 10%
	influence_reduction_timer.start(duration + 0.5)  # Mantén la influencia reducida por 0.5 segundos más que el stun

func _on_influence_reduction_timeout():
	current_influence = 1.0  # Restaura la influencia completa

func is_obstacle_to_player() -> int:
	var player = entity.get_component("detection").get_player()
	if not player:
		return 0
	
	var direction_to_player = (player.global_position - entity.global_position).normalized()
	raycast.cast_to = direction_to_player * avoid_distance
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("player"):
			return 0  # No hay obstáculo, el raycast golpea al jugador
		else:
			return 1  # Hay un obstáculo entre el enemigo y el jugador
	else:
		return 0  # No hay obstáculo, el raycast no golpea nada
