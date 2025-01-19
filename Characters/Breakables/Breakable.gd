extends Character
class_name Breakable

var held_breakable: Node = null
var player setget set_player
onready var tween: Tween = get_node("Tween")
onready var tooltip: Label = get_node("Node2D/Tooltip")

onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10 # Ajusta el daño según sea necesario
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 50

export var obstacle_radius: float = 14.0 # Adjust based on your breakable size

var last_position: Vector2

var is_orbiting: bool = false
var dungeon_room: Node2D # Referencia a la room padre

# Cargar el shader
onready var outline_shader = preload("res://Shaders/outline_shader.gdshader")
onready var original_material = null
onready var outline_material = ShaderMaterial.new()

func _ready():
	add_to_group("breakables")
	is_interpolating = false
	has_blood = false
	tooltip.visible = false
	var font = DynamicFont.new()
	font.size = 12
	tooltip.add_font_override("font", font)
	outline_material.shader = outline_shader
	#collision_area.connect("body_entered", self, "_on_CollisionArea_body_entered")
	hitbox.connect("body_entered", self, "_on_Hitbox_body_entered")
	hitbox.monitoring = false # Inicialmente desactivar la hitbox

	dungeon_room = get_parent()

	if not dungeon_room:
		push_error("Breakable debe ser hijo de DungeonRoom")
		return

func set_player(new_player):
	if player and player.is_connected("breakable_picked_up", self, "_on_Player_breakable_picked_up"):
		# Desconectar señales del player anterior si existe y está conectado
		player.disconnect("breakable_picked_up", self, "_on_Player_breakable_picked_up")
		player.disconnect("breakable_dropped", self, "_on_Player_breakable_dropped")
	
	player = new_player
	
	if player:
		# Conectar señales al nuevo player
		if !player.is_connected("breakable_picked_up", self, "_on_Player_breakable_picked_up"):
			player.connect("breakable_picked_up", self, "_on_Player_breakable_picked_up")
			player.connect("breakable_dropped", self, "_on_Player_breakable_dropped")

func _on_Player_breakable_dropped(breakable_node):
	if breakable_node == self:
		if dungeon_room:
			dungeon_room.update_navigation_with_all_breakables()

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
	hitbox.set_collision_mask_bit(0, false)
	tween.interpolate_property(self, "global_position", initial_pos, final_pos, 0.8, Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	hitbox.monitoring = true
	knockback_direction = (final_pos - initial_pos).normalized()
	tween.connect("tween_completed", self, "_on_tween_completed")

func _on_CollisionArea_body_entered(body):
	if is_interpolating and (body is TileMap or body is StaticBody2D):
		# TODO: Esto debe de monitorizarlo el tilemap
		if body is TileMap:
			print(body)
			var local_position = body.to_local(self.global_position)
			var map_position = body.world_to_map(local_position)
			var WALL_TILE_ID = 2
			var BROKEN_WALL_TILE_ID = 27
			if (body.get_cellv(map_position + Vector2.UP) == WALL_TILE_ID):
				body.set_cellv(map_position + Vector2.UP, BROKEN_WALL_TILE_ID)
		tween.stop_all()
		hitbox.monitoring = false # Desactivar la hitbox al detenerse
		hitbox.set_collision_mask_bit(0, true) # Reactivar colisión con sí mismo
		print("Colisión con pared detectada")
		knockback_direction = Vector2.ZERO
		self.take_damage(damage, knockback_direction, knockback_force)

func _on_Hitbox_body_entered(body):
	if is_interpolating and (body != self and body.has_method("take_damage")):
		print('knockback', knockback_direction)
		body.take_damage(damage, knockback_direction, knockback_force)
		knockback_direction = Vector2.ZERO
		self.take_damage(damage, knockback_direction, knockback_force)
		print("Colisión con entidad detectada, causando daño")

func _on_tween_completed(object, key):
	if object == self and key == "global_position":
		hitbox.monitoring = false # Desactivar la hitbox después de la interpolación
		hitbox.set_collision_mask_bit(0, true) # Reactivar colisión con sí mismo
		is_interpolating = false
		tween.disconnect("tween_completed", self, "_on_tween_completed")

func _physics_process(_delta):
	if not is_orbiting and global_position.distance_to(last_position) > 1.0:
		last_position = global_position

func move_breakable(mouse_position: Vector2) -> void:
	if player and is_orbiting:
		var direction: Vector2 = (mouse_position - player.global_position).normalized()
		var distance: float = 18
		global_position = player.global_position + direction * distance

func _process(delta):
	if player and is_orbiting:
		move_breakable(get_global_mouse_position())
