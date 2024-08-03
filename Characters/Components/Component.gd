class_name Component
extends Node

var entity: Node  # La entidad a la que pertenece este componente

func _init(entity: Node):
	self.entity = entity

func initialize():
	# Método para inicializar el componente
	pass

func update(delta: float):
	# Método para actualizar el componente cada frame
	pass

func receive_message(message: String, data: Dictionary):
	# Los componentes individuales pueden sobrescribir este método
	pass
