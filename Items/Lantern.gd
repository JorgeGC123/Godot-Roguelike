extends Area2D
class_name Lantern
onready var collision_shape: CollisionShape2D = get_node("CollisionShape2D")
onready var tween: Tween = get_node("Tween")
onready var lantern = get_node("Lantern")

var following_player := false

func _on_Lantern_body_entered(player: KinematicBody2D) -> void:
	set_as_toplevel(false)
	get_parent().remove_child(self)
	player.add_child(self)
	set_position(Vector2.ZERO)  # Esto colocará la linterna en el centro del player.
	following_player = true
	SavedData.items.append(self.duplicate())


func _process(delta: float) -> void:
	if following_player:
		var mouse_position := get_global_mouse_position()
		var direction := (mouse_position - global_position).angle()
		lantern.rotation = direction
