extends AnimatedSprite2D
var playing: int = 0

func _ready() -> void:
	playing = true


func _on_SpawnExplosion_animation_finished() -> void:
	queue_free()
