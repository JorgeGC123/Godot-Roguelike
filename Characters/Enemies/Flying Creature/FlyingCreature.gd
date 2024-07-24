extends Enemy

const MAX_DISTANCE_TO_PLAYER: int = 60
const MIN_DISTANCE_TO_PLAYER: int = 20
const HEADBUTT_SPEED: float = 300.0

enum State {IDLE, CHASE, ATTACK, DEAD}

var can_attack: bool = true
var distance_to_player: float

onready var hitbox: Area2D = $Hitbox
onready var attack_timer: Timer = Timer.new()
onready var cast_timer: Timer = Timer.new()
onready var aim_raycast: RayCast2D = $AimRayCast
onready var charge_particles: CPUParticles2D = $Area2D/ChargeParticles

func _ready():
	add_child(attack_timer)
	add_child(cast_timer)
	attack_timer.wait_time = 1
	cast_timer.wait_time = 0.5
	attack_timer.one_shot = true
	cast_timer.one_shot = true
	attack_timer.connect("timeout", self, "_on_attack_timer_timeout")
	cast_timer.connect("timeout", self, "_on_cast_timer_timeout")

func _on_PathTimer_timeout() -> void:
	if not is_instance_valid(player) or state_machine.get_current_state() == "dead":
		_stop_movement()
		return
	
	if state_machine.get_current_state() == "attack":
		return

	_update_distance_and_aim()
	
	if _should_chase():
		_start_chase()
	elif _can_attack():
		_prepare_attack()
	else:
		_start_chase()

func _process(_delta: float) -> void:
	hitbox.knockback_direction = velocity.normalized()

func _headbutt() -> void:
	if not is_instance_valid(player) or state_machine.get_current_state() == "dead":
		return
	var direction_to_player = (player.position - global_position).normalized()
	velocity = direction_to_player * HEADBUTT_SPEED * 2
	attack_timer.start()

func _update_distance_and_aim() -> void:
	aim_raycast.cast_to = player.position - global_position
	aim_raycast.force_raycast_update()
	distance_to_player = (player.position - global_position).length()

func _should_chase() -> bool:
	return distance_to_player > MAX_DISTANCE_TO_PLAYER and distance_to_player < detection_radius

func _can_attack() -> bool:
	return can_attack and not aim_raycast.is_colliding() and distance_to_player < MAX_DISTANCE_TO_PLAYER

func _start_chase() -> void:
	state_machine.set_state(state_machine.states.chase)
	_get_path_to_player()

func _prepare_attack() -> void:
	state_machine.set_state(state_machine.states.attack)
	can_attack = false
	charge_particles.emitting = true
	cast_timer.start()

func _stop_movement() -> void:
	path_timer.stop()
	path = []
	mov_direction = Vector2.ZERO

func _on_attack_timer_timeout() -> void:
	can_attack = true
	state_machine.set_state(state_machine.states.idle)

func _on_cast_timer_timeout() -> void:
	charge_particles.emitting = false
	if distance_to_player > MAX_DISTANCE_TO_PLAYER:
		state_machine.set_state(state_machine.states.idle)
		can_attack = true
	else:
		_headbutt()
