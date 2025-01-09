extends Node
var nav_map: RID

func _ready():
    # En lugar de crear un nuevo mapa, usa el mapa por defecto
    nav_map = get_tree().get_root().get_world_2d().get_navigation_map()
    print("Using default navigation map: ", nav_map)
    
    # Verificar que el mapa esté activo
    if not Navigation2DServer.map_is_active(nav_map):
        print("Activating navigation map")
        Navigation2DServer.map_set_active(nav_map, true)
    
    # Configurar el mapa
    Navigation2DServer.map_set_cell_size(nav_map, 16.0)
    Navigation2DServer.map_set_edge_connection_margin(nav_map, 5.0)
    
    # Forzar una actualización
    Navigation2DServer.map_force_update(nav_map)

func _physics_process(_delta):
    if not Navigation2DServer.map_is_active(nav_map):
        push_warning("Navigation map became inactive!")
        Navigation2DServer.map_set_active(nav_map, true)
        Navigation2DServer.map_force_update(nav_map)

func _exit_tree():
    if nav_map:
        Navigation2DServer.free_rid(nav_map)