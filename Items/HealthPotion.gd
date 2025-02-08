extends Area2D

onready var collision_shape: CollisionShape2D = get_node("CollisionShape2D")
onready var tween: Tween = get_node("Tween")
onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
# cargar el shader
onready var outline_shader = preload("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

func _ready() -> void:
	outline_material.shader = outline_shader

func _on_HealthPotion_body_entered(player: KinematicBody2D) -> void:
	pass

func _on_Area2D_body_entered(body):
	print("xd") 
	if body is Player:
		body.near_pickable = self
		apply_outline()

func _on_Area2D_body_exited(body):
	if body is Player:
		body.near_pickable = null
		remove_outline()

func apply_outline():
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material
