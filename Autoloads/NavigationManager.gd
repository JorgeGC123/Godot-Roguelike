extends Node
var nav_map: RID

func _ready():
    nav_map = Navigation2DServer.map_create()
    Navigation2DServer.map_set_active(nav_map, true)
    Navigation2DServer.map_set_cell_size(nav_map, 16.0)
    Navigation2DServer.map_set_edge_connection_margin(nav_map, 5.0)

func _exit_tree():
    if nav_map:
        Navigation2DServer.free_rid(nav_map)