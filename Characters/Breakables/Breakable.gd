extends Character

var held_breakable: Node = null
onready var tween: Tween = Tween.new()
onready var tooltip: Label = get_node("Node2D/Tooltip")  # Asegúrate de tener un nodo Label como hijo para el tooltip
#onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")  # Obtén una referencia al nodo AnimatedSprite
var initial_tooltip_position: Vector2

# Cargar el shader
onready var outline_shader = preload("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

func _ready():
	has_blood = false
	add_child(tween)
	tooltip.visible = false  # El tooltip se inicia invisible
	var font = DynamicFont.new()
	#font.font_data = load("res://Fonts/Rubik-DoodleShadow-Regular.ttf")
	font.size = 12
	tooltip.add_font_override("font", font)
	outline_material.shader = outline_shader

func _on_Area2D_body_entered(body):
	if body is Player:
		body.near_breakable = self
		apply_outline()
		tooltip.visible = false

func _on_Area2D_body_exited(body):
	if body is Player:
		body.near_breakable = null
		remove_outline()

func apply_outline():
	print(outline_material)
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material
	print(animated_sprite.material)

func remove_outline():
	animated_sprite.material = original_material
