extends StaticBody2D

export var obstacle_radius: float = 10.0
export var shape_color: Color = Color(255.0, 0.0, 0.0, 0.5)
export var debug_draw: bool = true
export var navigation_cost: float = 1000.0  # Coste muy alto para el pathfinding

var nav_region: RID
onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var nav_instance = get_parent().get_node("NavigationPolygonInstance")
	var main_navpoly = nav_instance.navpoly
	if not main_navpoly:
		main_navpoly = NavigationPolygon.new()
		nav_instance.navpoly = main_navpoly

	# Store original outlines
	var original_outlines = []
	for i in range(main_navpoly.get_outline_count()):
		original_outlines.append(main_navpoly.get_outline(i))

	# Create a simpler octagonal shape instead of a full circle
	var obstacle_points = PoolVector2Array()
	var num_sides = 8  # Using an octagon for simpler navigation
	var radius = obstacle_radius * 1.5  # Slightly larger than collision radius
	
	for i in range(num_sides):
		var angle = i * 2 * PI / num_sides
		var point = Vector2(
			global_position.x + cos(angle) * radius,
			global_position.y + sin(angle) * radius
		)
		obstacle_points.push_back(point)

	# Create a new navigation polygon
	var new_navpoly = NavigationPolygon.new()
	
	# Add the main room outline
	for outline in original_outlines:
		new_navpoly.add_outline(outline)
	
	# Add the octagonal obstacle
	new_navpoly.add_outline(obstacle_points)
	
	# Generate polygons
	new_navpoly.make_polygons_from_outlines()
	
	# Update navigation instance
	nav_instance.navpoly = new_navpoly

	# Adjust navigation parameters
	Navigation2DServer.map_set_edge_connection_margin(
		NavigationManager.nav_map, 
		obstacle_radius * 0.25
	)
	Navigation2DServer.map_set_cell_size(
		NavigationManager.nav_map,
		8.0
	)

	# Force update
	Navigation2DServer.map_force_update(NavigationManager.nav_map)

	# Physical collision still uses circular shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = obstacle_radius
	$CollisionShape2D.shape = circle_shape

func _draw() -> void:
	if debug_draw:
		draw_circle(Vector2.ZERO, obstacle_radius, shape_color)

func _process(_delta: float) -> void:
	if debug_draw:
		update()

func _exit_tree() -> void:
	# Force navigation update when obstacle is removed
	Navigation2DServer.map_force_update(NavigationManager.nav_map)

# Opcional: Método para cambiar el tamaño del obstáculo en tiempo de ejecución
func set_radius(new_radius: float) -> void:
	obstacle_radius = new_radius
	
	# Actualizar la región de navegación
	var navpoly = NavigationPolygon.new()
	var points = PoolVector2Array()
	var num_points = 16
	for i in range(num_points):
		var angle = i * 2 * PI / num_points
		var point = Vector2(
			cos(angle) * new_radius,
			sin(angle) * new_radius
		)
		points.push_back(point)
	
	navpoly.add_outline(points)
	navpoly.make_polygons_from_outlines()
	Navigation2DServer.region_set_navpoly(nav_region, navpoly)
	
	# Actualizar la colisión física
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = new_radius
	collision_shape.shape = circle_shape
	update()
