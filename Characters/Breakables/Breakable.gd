extends Character

var held_breakable: Node = null  # Referencia al objeto Breakable que está sosteniendo
onready var tween: Tween = Tween.new()

func _ready():
	add_child(tween)
	
func _on_Area2D_body_entered(body):
	if body is Player:
		print('entro')
		body.near_breakable = self  # Establece que el jugador está cerca de un Breakable

func _on_Area2D_body_exited(body):
	if body is Player:
		print('salgo')
		body.near_breakable = null  # Establece que el jugador ya no está cerca de un Breakable
