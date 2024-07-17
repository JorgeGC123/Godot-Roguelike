extends Character

var held_breakable: Node = null
var player # referencia al jugador
onready var tween: Tween = get_node("Tween")
onready var tooltip: Label = get_node("Node2D/Tooltip")
#onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
onready var collision_area: Area2D = get_node("Area2D")
onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10 # Ajusta el daño según sea necesario
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 0
var is_interpolating: bool = false # Bandera para indicar si está interpolando
var is_orbiting: bool = false

# Cargar el shader
onready var outline_shader = preload ("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

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
	hitbox.monitoring = false # Inicialmente desactivar la hitbox

func _on_Area2D_body_entered(body):
	if body is Player:
		apply_outline()

func _on_Area2D_body_exited(body):
	if body is Player:
		remove_outline()

func apply_outline():
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material
