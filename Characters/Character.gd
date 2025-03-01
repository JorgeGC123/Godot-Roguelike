extends KinematicBody2D
class_name Character, "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/knight/knight_idle_anim_f0.png"

const HIT_EFFECT_SCENE: PackedScene = preload ("res://Characters/HitEffect.tscn")
const BLOOD_EFFECT_SCENE: PackedScene = preload ("res://Characters/BloodSplash.tscn")

const FRICTION: float = 0.15
export(int) var has_blood: bool = true
export(int) var max_hp: int = 2 setget set_max_hp
export(int) var max_stamina: int = 100
export(int) var stamina: int = 100 setget set_stamina
export(int) var hp: int = 2 setget set_hp, get_hp
signal hp_changed(new_hp)
signal stamina_changed(new_stamina)
onready var stamina_timer: Timer = Timer.new()
onready var stamina_delay_timer: Timer = Timer.new() # Timer para el delay
export(int) var stamina_recovery_rate: int = 1 # Cantidad de stamina recuperada por tick
export(float) var stamina_recovery_interval: float = 0.1 # Intervalo de recuperación en segundos
export(float) var stamina_recovery_delay: float = 1.0 # Delay antes de la recuperación
onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
export(int) var accerelation: int = 40
export(int) var max_speed: int = 100
onready var collision_area: Area2D = get_node("Area2D")
export(bool) var flying: bool = false
var is_interpolating: bool = false

onready var state_machine: Node = get_node("FiniteStateMachine")
onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")

var mov_direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

# señales pa multiplayer
signal position_changed(new_pos)
signal flip_h_changed(flip_h)
signal animation_changed(anim_name)

func _ready() -> void:
	is_interpolating = false
	collision_area.connect("body_entered", self, "_on_CollisionArea_body_entered")
	_setup_stamina_timers()

func _setup_stamina_timers() -> void:
	_setup_timer(stamina_timer, stamina_recovery_interval, false, "_on_StaminaTimer_timeout")
	_setup_timer(stamina_delay_timer, stamina_recovery_delay, true, "_on_StaminaDelayTimer_timeout")

func _setup_timer(timer: Timer, wait_time: float, one_shot: bool, callback: String) -> void:
	add_child(timer)
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	timer.connect("timeout", self, callback)

func initialize(id: int, name: String, character_index: int):
	self.name = str(id)
	print('id player: ', self.name)

func _physics_process(_delta: float) -> void:
	velocity = move_and_slide(velocity)
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)
	emit_signal("position_changed", position)
	
func move() -> void:
	mov_direction = mov_direction.normalized()
	velocity += mov_direction * accerelation
	if (stamina > max_stamina / 3):
		velocity = velocity.limit_length(max_speed)
	else:
		velocity = velocity.limit_length(max_speed / 2)
	
func take_damage(dam: int, dir: Vector2, force: int) -> void:
	if state_machine.state != state_machine.states.hurt and state_machine.state != state_machine.states.dead:
		print("estoy sintiendo el dolor")
		_spawn_hit_effect(dir)
		self.hp -= dam
		if name == "Player":
			SavedData.hp = hp
			if hp == 0:
				SceneTransistor.start_transition_to("res://Game.tscn")
				SavedData.reset_data()
		elif name == "MultiplayerCharacter":
			if hp == 0:
				print('me muerto')
				queue_free()
		if hp > 0:
			state_machine.set_state(state_machine.states.hurt)
			velocity += dir * force
			is_interpolating = true
		else:
			print("dead")
			state_machine.set_state(state_machine.states.dead)
			velocity += dir * force * 2
			is_interpolating = true
		
func reduce_stamina(cost: int) -> void:
	self.stamina -= cost
	start_stamina_regeneration()

func set_hp(new_hp: int) -> void:
	hp = clamp(new_hp, 0, max_hp)
	emit_signal("hp_changed", hp)

func get_hp() -> int:
	return hp

func set_max_hp(value: int) -> void:
	max_hp = max(1, value)
	self.hp = min(hp, max_hp)
	
func set_stamina(new_stamina: int) -> void:
	stamina = clamp(new_stamina, 0, max_stamina)
	emit_signal("stamina_changed", stamina)

func start_stamina_regeneration():
	if stamina_delay_timer.is_stopped() and stamina_timer:
		stamina_delay_timer.start()

func _on_StaminaDelayTimer_timeout():
	if stamina_timer.is_stopped():
		stamina_timer.start()

func _on_StaminaTimer_timeout():
	if stamina_delay_timer.is_stopped():
		if stamina < max_stamina:
			set_stamina(stamina + stamina_recovery_rate)
			if stamina >= max_stamina:
				stamina_timer.stop()

func _spawn_hit_effect(dir: Vector2) -> void:
	var hit_effect: Sprite = HIT_EFFECT_SCENE.instance()
	add_child(hit_effect)
	if has_blood:
		var blood_effect: CPUParticles2D = BLOOD_EFFECT_SCENE.instance()
		blood_effect.global_rotation = dir.angle()
		blood_effect.global_position = global_position + dir

		var main_scene = get_tree().root 
		main_scene.add_child(blood_effect)

		# Añadir la partícula a la lista en el singleton de la escena para luego borrarlas
		SceneTransistor.add_blood_effect(blood_effect)

func _on_CollisionArea_body_entered(body):
	if is_interpolating and (body is TileMap or body is StaticBody2D):
		velocity = Vector2(0,0)
		print("Colisión con pared detectada")
