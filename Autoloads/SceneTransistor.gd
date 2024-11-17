extends CanvasLayer

var new_scene: String

onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
var blood_effects: Array = []

func start_transition_to(path_to_scene: String) -> void:
	new_scene = path_to_scene
	clear_blood_effects()
	animation_player.play("change_scene")
	
	
func change_scene() -> void:
	var __ = get_tree().change_scene(new_scene) == OK
	assert(__)

func add_blood_effect(effect: CPUParticles2D) -> void:
	blood_effects.append(effect)

func clear_blood_effects() -> void:
	for effect in blood_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	blood_effects.clear()
