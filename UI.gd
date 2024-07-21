extends CanvasLayer

const INVENTORY_ITEM_SCENE: PackedScene = preload("res://InventoryItem.tscn")

const MIN_HEALTH: int = 23

var max_hp: int = 4
var max_stamina: int = 100

@onready var player: CharacterBody2D = get_parent().get_node("Player")
@onready var health_bar: TextureProgressBar = get_node("HealthBar")
@onready var health_bar_tween: Tween = get_tree().create_tween().bind_node(self)
@onready var stamina_bar: TextureProgressBar = get_node("StaminaBar")
@onready var stamina_bar_tween: Tween = get_tree().create_tween().bind_node(self)

@onready var inventory: HBoxContainer = get_node("PanelContainer/Inventory")


func _ready() -> void:
	var health_bar_tween: Tween = get_tree().create_tween().bind_node(self)
	var stamina_bar_tween: Tween = get_tree().create_tween().bind_node(self)
	max_hp = player.max_hp
	#_update_health_bar(100)
	max_stamina = player.max_stamina
	#_update_stamina_bar(100)
	
	
func _update_health_bar(new_value: int) -> void:
	health_bar_tween.set_loops()
	health_bar_tween.tween_property(health_bar, "scale", Vector2(0,0), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	health_bar_tween.tween_property(health_bar, "scale", Vector2(0,0), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	health_bar_tween.play()

func _update_stamina_bar(new_value: int) -> void:
	health_bar_tween.set_loops()
	# rehacer todo esto
	# health_bar_tween.tween_property(stamina_bar, "scale", Vector2(0,0), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	# health_bar_tween.tween_property(stamina_bar, "scale", Vector2(0,0), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	# health_bar_tween.play()
	
func _on_Player_hp_changed(new_hp: int) -> void:
	var new_health: int = int((100 - MIN_HEALTH) * float(new_hp) / max_hp) + MIN_HEALTH
	_update_health_bar(new_health)

func _on_Player_stamina_changed(new_st: int) -> void:
	var new_stamina: int = int((100 - MIN_HEALTH) * float(new_st) / max_stamina) + MIN_HEALTH
	_update_stamina_bar(new_stamina)

func _on_Player_weapon_switched(prev_index: int, new_index: int) -> void:
	inventory.get_child(prev_index).deselect()
	inventory.get_child(new_index).select()


func _on_Player_weapon_picked_up(weapon_texture: Texture2D) -> void:
	var new_inventory_item: TextureRect = INVENTORY_ITEM_SCENE.instantiate()
	inventory.add_child(new_inventory_item)
	new_inventory_item.initialize(weapon_texture)


func _on_Player_weapon_droped(index: int) -> void:
	inventory.get_child(index).queue_free()
