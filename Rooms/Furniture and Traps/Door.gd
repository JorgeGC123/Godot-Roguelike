extends StaticBody2D

onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
# Cargar el shader
onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
onready var outline_shader = preload ("res://Shaders/outline_shader.gdshader")
onready var original_material = null
export var is_open = false
onready var outline_material = ShaderMaterial.new()

func open() -> void:
	if !is_open:
		animation_player.play("open")
		is_open = true
		remove_outline()

func get_input() -> void:
	if Input.is_action_pressed("ui_interact"):
		print('abre bro')
		animation_player.play("open")

func _ready():
	outline_material.shader = outline_shader

func _on_Area2D_body_entered(body):
	if body is Player and !is_open:
		body.near_door = self
		print('fokdicion hijo')
		apply_outline()

func _on_Area2D_body_exited(body):
	if body is Player:
		body.near_door = false
		remove_outline()

func apply_outline():
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material
