extends KinematicBody2D
class_name Character, "res://Art/v1.1 dungeon crawler 16x16 pixel pack/heroes/knight/knight_idle_anim_f0.png"

const HIT_EFFECT_SCENE: PackedScene = preload("res://Characters/HitEffect.tscn")

const FRICTION: float = 0.15

export(int) var max_hp: int = 2
export(int) var max_stamina: int = 100
export(int) var stamina: int = 100 setget set_stamina
export(int) var hp: int = 2 setget set_hp
signal hp_changed(new_hp)
signal stamina_changed(new_stamina)
onready var stamina_timer: Timer = Timer.new()
onready var stamina_delay_timer: Timer = Timer.new()  # Timer para el delay
export(int) var stamina_recovery_rate: int = 1  # Cantidad de stamina recuperada por tick
export(float) var stamina_recovery_interval: float = 0.1  # Intervalo de recuperación en segundos
export(float) var stamina_recovery_delay: float = 1.0  # Delay antes de la recuperación

export(int) var accerelation: int = 40
export(int) var max_speed: int = 100

export(bool) var flying: bool = false

onready var state_machine: Node = get_node("FiniteStateMachine")
onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")

var mov_direction: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

func _ready():
	add_child(stamina_timer)
	stamina_timer.wait_time = stamina_recovery_interval
	stamina_timer.one_shot = false
	stamina_timer.connect("timeout", self, "_on_StaminaTimer_timeout")

	add_child(stamina_delay_timer)
	stamina_delay_timer.wait_time = stamina_recovery_delay
	stamina_delay_timer.one_shot = true
	stamina_delay_timer.connect("timeout", self, "_on_StaminaDelayTimer_timeout")
	print("Timers added and connected.")

func _physics_process(_delta: float) -> void:
	velocity = move_and_slide(velocity)
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)
	
	
func move() -> void:
	mov_direction = mov_direction.normalized()
	velocity += mov_direction * accerelation
	velocity = velocity.limit_length(max_speed)
	
	
func take_damage(dam: int, dir: Vector2, force: int) -> void:
	if state_machine.state != state_machine.states.hurt and state_machine.state != state_machine.states.dead:
		_spawn_hit_effect()
		self.hp -= dam
		if name == "Player":
			SavedData.hp = hp
			if hp == 0:
				SceneTransistor.start_transition_to("res://Game.tscn")
				SavedData.reset_data()
		if hp > 0:
			state_machine.set_state(state_machine.states.hurt)
			velocity += dir * force
		else:
			state_machine.set_state(state_machine.states.dead)
			velocity += dir * force * 2
		
func reduce_stamina(cost: int) -> void:
	self.stamina -= cost
	print("Stamina reduced: ", self.stamina)
	start_stamina_regeneration()
	print("start_stamina_regeneration called.")

func set_hp(new_hp: int) -> void:
	hp = clamp(new_hp, 0, max_hp)
	emit_signal("hp_changed", hp)

func set_stamina(new_stamina: int) -> void:
	stamina = clamp(new_stamina, 0, max_stamina)
	emit_signal("stamina_changed", stamina)

func start_stamina_regeneration():
	if stamina_delay_timer.is_stopped() and stamina_timer:
		stamina_delay_timer.start()
		print("Delay timer started.")

func _on_StaminaDelayTimer_timeout():
	if stamina_timer.is_stopped():
		stamina_timer.start()
		print("Stamina recovery timer started.")

func _on_StaminaTimer_timeout():
	print("Timer timeout: current stamina = ", stamina)
	if stamina_delay_timer.is_stopped():
		if stamina < max_stamina:
			set_stamina(stamina + stamina_recovery_rate)
			print("Stamina increased: ", stamina)
			if stamina >= max_stamina:
				stamina_timer.stop()
				print("Timer stopped.")

func _spawn_hit_effect() -> void:
	var hit_effect: Sprite = HIT_EFFECT_SCENE.instance()
	add_child(hit_effect)
