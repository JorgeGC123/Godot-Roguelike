extends Character
class_name Breakable

var held_breakable: Node = null
var player # referencia al jugador
onready var tween: Tween = get_node("Tween")
onready var tooltip: Label = get_node("Node2D/Tooltip")
#onready var animated_sprite: AnimatedSprite = get_node("AnimatedSprite")
# onready var collision_area: Area2D = get_node("Area2D")
onready var hitbox: Area2D = get_node("Hitbox")
var initial_tooltip_position: Vector2
var damage: int = 10 # Ajusta el daño según sea necesario
var knockback_direction: Vector2 = Vector2.ZERO
var knockback_force: int = 50

var nav_region: RID
var obstacle_radius: float = 8.0 # Adjust based on your breakable size
var nav_instance: Node
export var shape_color: Color = Color(255.0, 0.0, 0.0, 0.5)
export var debug_draw: bool = true
var original_navpoly: NavigationPolygon = null

var is_orbiting: bool = false

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

	print("Breakable: Setting up navigation obstacle")
	var nav_instance = get_parent().get_node("NavigationPolygonInstance")
	print("Navigation instance found:", nav_instance != null)

	if nav_instance:
		setup_navigation_obstacle(nav_instance)

func setup_navigation_obstacle(nav_instance):
	# Store the original navigation polygon
	original_navpoly = nav_instance.navpoly
	if not original_navpoly:
		print("No original navpoly found, creating new one")
		original_navpoly = NavigationPolygon.new()
		nav_instance.navpoly = original_navpoly
	
	# Create a new working navpoly
	var working_navpoly = NavigationPolygon.new()
	
	# Copy all original outlines
	for i in range(original_navpoly.get_outline_count()):
		working_navpoly.add_outline(original_navpoly.get_outline(i))
	
	print("Original outlines preserved:", working_navpoly.get_outline_count())

	# Create octagonal shape for obstacle
	var obstacle_points = PoolVector2Array()
	var num_sides = 8
	var radius = obstacle_radius * 1.5
	
	for i in range(num_sides):
		var angle = i * 2 * PI / num_sides
		var point = Vector2(
			global_position.x + cos(angle) * radius,
			global_position.y + sin(angle) * radius
		)
		obstacle_points.push_back(point)

	# Add obstacle outline
	working_navpoly.add_outline(obstacle_points)
	
	# Generate new polygons with the obstacle
	working_navpoly.make_polygons_from_outlines()
	
	# Verify the navpoly is valid before assigning
	if working_navpoly.get_polygon_count() > 0:
		nav_instance.navpoly = working_navpoly
		print("Updated navigation polygon with obstacle. Polygon count:", working_navpoly.get_polygon_count())
	else:
		print("ERROR: Generated navpoly has no polygons!")
		nav_instance.navpoly = original_navpoly
		return

	# Update navigation parameters
	Navigation2DServer.map_set_edge_connection_margin(
		NavigationManager.nav_map, 
		obstacle_radius * 0.25
	)
	Navigation2DServer.map_set_cell_size(
		NavigationManager.nav_map,
		8.0
	)

	Navigation2DServer.map_force_update(NavigationManager.nav_map)

func restore_original_navigation():
	var nav_instance = get_parent().get_node("NavigationPolygonInstance")
	if nav_instance and original_navpoly:
		nav_instance.navpoly = original_navpoly
		Navigation2DServer.map_force_update(NavigationManager.nav_map)
		print("Restored original navigation mesh")

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
	
	# Re-enable navigation when thrown
	if nav_instance:
		setup_navigation_obstacle(nav_instance)

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

func move_breakable(mouse_position: Vector2) -> void:
	if player and is_orbiting:
		var direction: Vector2 = (mouse_position - player.global_position).normalized()
		var distance: float = 18
		global_position = player.global_position + direction * distance
		
		# Disable navigation region while being carried
		if nav_region:
			Navigation2DServer.region_set_navpoly(nav_region, null)

func _process(delta):
	# Original process code
	if player and is_orbiting:
		move_breakable(get_global_mouse_position())
		restore_original_navigation()
	elif not is_orbiting:
		var nav_instance = get_parent().get_node("NavigationPolygonInstance")
		# if nav_instance:
		# 	setup_navigation_obstacle(nav_instance)

func _draw() -> void:
	if debug_draw:
		draw_circle(Vector2.ZERO, obstacle_radius, shape_color)

func _exit_tree() -> void:
	print("Breakable: Cleaning up navigation obstacle")
	var nav_instance = get_parent().get_node("NavigationPolygonInstance")
	if nav_instance:
		var main_navpoly = nav_instance.navpoly
		if main_navpoly:
			var new_navpoly = NavigationPolygon.new()
			for i in range(main_navpoly.get_outline_count()):
				var outline = main_navpoly.get_outline(i)
				if outline.size() != 8:  # Skip our octagonal obstacle
					new_navpoly.add_outline(outline)
			new_navpoly.make_polygons_from_outlines()
			nav_instance.navpoly = new_navpoly
			Navigation2DServer.map_force_update(NavigationManager.nav_map)
