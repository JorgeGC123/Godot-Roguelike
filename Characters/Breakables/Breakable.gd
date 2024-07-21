extends Character

var held_breakable: Node = null
var player # referencia al jugador
@onready var tween: Tween = get_tree().create_tween()
@onready var tooltip: Label = get_node("Node2D/Tooltip")
#onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
@onready var collision_area: Area2D = get_node("Area2D")
@onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10 # Ajusta el daño según sea necesario
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 0
var is_interpolating: bool = false # Bandera para indicar si está interpolando
var is_orbiting: bool = false

# Cargar el shader
@onready var outline_shader = preload ("res://Shaders/outline_shader.gdshader")
@onready var original_material = null
@onready var outline_material = ShaderMaterial.new()

func _ready():
	is_interpolating = false
	has_blood = false
	tooltip.visible = false
	# var font = FontFile.new()
	# font.size = 12
	# tooltip.add_theme_font_override("font", font)
	outline_material.shader = outline_shader
	collision_area.connect("body_entered", Callable(self, "_on_CollisionArea_body_entered"))
	hitbox.connect("body_entered", Callable(self, "_on_Hitbox_body_entered"))
	hitbox.monitoring = false # Inicialmente desactivar la hitbox

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
	if original_material == null:
		original_material = animated_sprite.material
	animated_sprite.material = outline_material

func remove_outline():
	animated_sprite.material = original_material

func interpolate_pos(initial_pos: Vector2, final_pos: Vector2) -> void:
	is_interpolating = true
	is_orbiting = false
	hitbox.set_collision_mask_value(0, false) # Desactivar colisión con sí mismo
	# tween.interpolate_property(self, "global_position", initial_pos, final_pos, 0.8, Tween.TRANS_QUART, Tween.EASE_OUT)
	# tween.start()
	tween.set_loops()
	tween.tween_property(self, "scale", initial_pos, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "scale", final_pos, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tween.play()
	hitbox.monitoring = true # Activar la hitbox durante la interpolación
	tween.connect("tween_completed", Callable(self, "_on_tween_completed"))

func _on_CollisionArea_body_entered(body):
	if is_interpolating and (body is TileMap or body is StaticBody2D):
		tween.stop_all()
		hitbox.monitoring = false # Desactivar la hitbox al detenerse
		hitbox.set_collision_mask_value(0, true) # Reactivar colisión con sí mismo
		print("Colisión con pared detectada")
		self.take_damage(damage, knockback_direction, knockback_force)

func _on_Hitbox_body_entered(body):
	if is_interpolating and (body != self and body is Character):
		body.take_damage(damage, knockback_direction, knockback_force)
		self.take_damage(damage, knockback_direction, knockback_force)
		print("Colisión con entidad detectada, causando daño")

func _on_tween_completed(object, key):
	if object == self and key == "global_position":
		hitbox.monitoring = false # Desactivar la hitbox después de la interpolación
		hitbox.set_collision_mask_value(0, true) # Reactivar colisión con sí mismo
		is_interpolating = false
		tween.disconnect("tween_completed", Callable(self, "_on_tween_completed"))

func move_breakable(mouse_position: Vector2) -> void:
	if player and is_orbiting:
		var direction: Vector2 = (mouse_position - player.global_position).normalized()
		var distance: float = 18 # Distancia del breakable respecto al jugador
		global_position = player.global_position + direction * distance

func _process(delta: float) -> void:
	if player and is_orbiting:
		move_breakable(get_global_mouse_position())
