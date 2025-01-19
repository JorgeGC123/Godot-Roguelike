extends Node
var nav_map: RID

func force_update():
	if not Navigation2DServer.map_is_active(nav_map):
		print("Reactivating navigation map")
		Navigation2DServer.map_set_active(nav_map, true)
	
	print("Pre-update map parameters:")
	print("Cell size: ", Navigation2DServer.map_get_cell_size(nav_map))
	print("Edge connection margin: ", Navigation2DServer.map_get_edge_connection_margin(nav_map))
	
	# Actualizar parámetros del mapa
	Navigation2DServer.map_set_cell_size(nav_map, 8.0)
	Navigation2DServer.map_set_edge_connection_margin(nav_map, 10.0)
	Navigation2DServer.map_force_update(nav_map)

func _ready():
	nav_map = get_tree().get_root().get_world_2d().get_navigation_map()
	print("Using default navigation map: ", nav_map)
	Navigation2DServer.map_set_active(nav_map, true)
