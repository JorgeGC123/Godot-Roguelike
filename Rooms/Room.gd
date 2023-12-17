extends Node2D
class_name DungeonRoom

export(bool) var boss_room: bool = false

const SPAWN_EXPLOSION_SCENE: PackedScene = preload("res://Characters/Enemies/SpawnExplosion.tscn")

const ENEMY_SCENES: Dictionary = {
	"FLYING_CREATURE": preload("res://Characters/Enemies/Flying Creature/FlyingCreature.tscn"),
	"GOBLIN": preload("res://Characters/Enemies/Goblin/Goblin.tscn"), "SLIME_BOSS": preload("res://Characters/Enemies/Bosses/SlimeBoss.tscn")
}

var num_enemies: int

onready var tilemap: TileMap = get_node("TileMap2")
onready var entrance: Node2D = get_node("Entrance")
onready var door_container: Node2D = get_node("Doors")
onready var enemy_positions_container: Node2D = get_node("EnemyPositions")
onready var player_detector: Area2D = get_node("PlayerDetector")
const BREAKABLE_SCENE: PackedScene = preload("res://Characters/Breakables/Breakable.tscn")  # Asegúrate de cambiar la ruta

var breakable_positions: Array  # Almacena posiciones potenciales para spawnear Breakables

func _ready() -> void:
	num_enemies = enemy_positions_container.get_child_count()
	determine_breakable_positions()
	spawn_breakables(randi() % 3 + 1)
	
func determine_breakable_positions() -> void:
	breakable_positions = []
	for cell in tilemap.get_used_cells():
		print(tilemap.tile_set.tile_get_name(tilemap.get_cellv(cell)))
		# TODO: mapear el tilemap
		if tilemap.tile_set.tile_get_name(tilemap.get_cellv(cell)) == "full tilemap.png 10":
			breakable_positions.append(tilemap.map_to_world(cell))

func spawn_breakables(count: int) -> void:

	for i in range(count):
		if breakable_positions.size() == 0:
			return  # No hay más posiciones disponibles

		var position_index = randi() % breakable_positions.size()
		var breakable = BREAKABLE_SCENE.instance()
		breakable.position = breakable_positions[position_index]
		add_child(breakable)
		print(breakable.position)
		breakable_positions.remove(position_index)  # Eliminar la posición para evitar spawns superpuestos	
	
func _on_enemy_killed() -> void:
	num_enemies -= 1
	if num_enemies == 0:
		_open_doors()
	
	
func _open_doors() -> void:
	for door in door_container.get_children():
		door.open()
		
		
func _close_entrance() -> void:
	for entry_position in entrance.get_children():
		tilemap.set_cellv(tilemap.world_to_map(entry_position.position), 1)
		tilemap.set_cellv(tilemap.world_to_map(entry_position.position) + Vector2.DOWN, 2)
		
		
func _spawn_enemies() -> void:
	for enemy_position in enemy_positions_container.get_children():
		var enemy: KinematicBody2D
		if boss_room:
			enemy = ENEMY_SCENES.SLIME_BOSS.instance()
			num_enemies = 15
		else:
			if randi() % 2 == 0:
				enemy = ENEMY_SCENES.FLYING_CREATURE.instance()
			else:
				enemy = ENEMY_SCENES.GOBLIN.instance()
		enemy.position = enemy_position.position
		call_deferred("add_child", enemy)
		
		var spawn_explosion: AnimatedSprite = SPAWN_EXPLOSION_SCENE.instance()
		spawn_explosion.position = enemy_position.position
		call_deferred("add_child", spawn_explosion)



func _on_PlayerDetector_body_entered(_body: KinematicBody2D) -> void:
	player_detector.queue_free()
	if num_enemies > 0:
		_close_entrance()
		_spawn_enemies()
	else:
		_close_entrance()
		_open_doors()
