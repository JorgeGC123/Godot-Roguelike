extends Character

var held_breakable: Node = null
var player # referencia al jugador
onready var tween: Tween = get_node("Tween")
onready var tooltip: Label = get_node("Node2D/Tooltip")
onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 0

var is_orbiting: bool = false
var conversation = preload("res://addons/basicdialogue.tres")
onready var outline_shader = preload ("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

var patrol_behavior: PatrolBehavior

func _ready():
	is_interpolating = false
	has_blood = true
	tooltip.visible = false
	var font = DynamicFont.new()
	font.size = 12
	tooltip.add_font_override("font", font)
	outline_material.shader = outline_shader
	collision_area.connect("body_entered", self, "_on_CollisionArea_body_entered")
	hitbox.connect("body_entered", self, "_on_Hitbox_body_entered")
	hitbox.monitoring = false

	# Crear y configurar dinámicamente el PatrolBehavior
	patrol_behavior = PatrolBehavior.new()
	add_child(patrol_behavior)
	patrol_behavior.patrol_radius = 100.0  # Puedes ajustar estos valores según necesites
	patrol_behavior.patrol_speed = 50.0
	patrol_behavior.patrol_idle_time = 5.0
	patrol_behavior.adapt_state_machine(state_machine)

func _process(_delta):
	print(state_machine.state)
	if !is_talking() and state_machine.state == state_machine.states.talking:
		state_machine.set_state(state_machine.states.patrolling)

func _on_Area2D_body_entered(body):
	if body is Player and state_machine.state != state_machine.states.dead:
		apply_outline()
		body.near_npc = self

func _on_Area2D_body_exited(body):
	if body is Player:
		remove_outline()
		body.near_npc = null

func apply_outline():
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material

func trigger_dialog():
	if state_machine.state != state_machine.states.dead:
		state_machine.set_state(state_machine.states.talking)
		DialogueManager.fetch_basic_dialogue("basicdialogue", \
			conversation)
	
func is_talking():
	return DialogueManager.is_dialogue_running
