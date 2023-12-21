extends Character

var held_breakable: Node = null
onready var tween: Tween = Tween.new()
onready var tooltip: Label = get_node("Node2D/Tooltip")  # Asegúrate de tener un nodo Label como hijo para el tooltip
var initial_tooltip_position: Vector2

func _ready():
	add_child(tween)
	tooltip.visible = false  # El tooltip se inicia invisible
	var font = DynamicFont.new()
	font.font_data = load("res://Fonts/Rubik-DoodleShadow-Regular.ttf")
	font.size = 12
	tooltip.add_font_override("font", font)

func _on_Area2D_body_entered(body):
	if body is Player:
		body.near_breakable = self
		update_tooltip_position()
		tooltip.text = str("e")  # Muestra la tecla de interacción
		tooltip.visible = true

func _on_Area2D_body_exited(body):
	if body is Player:
		body.near_breakable = null
		tooltip.visible = false

func update_tooltip_position():
	tooltip.rect_position = initial_tooltip_position + Vector2(-5, -20)
		
