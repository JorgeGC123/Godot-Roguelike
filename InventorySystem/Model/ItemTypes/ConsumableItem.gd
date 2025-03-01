class_name ConsumableItem
extends Item

# Propiedades específicas de consumibles
export(int) var heal_amount: int = 1 # Cantidad de curación para pociones de vida
export(int) var uses_left: int = 1  # Número de usos restantes (si es de un solo uso, será 1)
export(PackedScene) var item_scene: PackedScene # Referencia a la escena original

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_icon = null).(p_id, p_name, p_description, p_icon):
	item_type = "consumable"
	
	# Si tenemos ID pero no tenemos item_scene, intentar cargar la escena
	if p_id != "" and not item_scene:
		var item_path = "res://Items/" + p_id + ".tscn"
		
		if ResourceLoader.exists(item_path):
			item_scene = load(item_path)
			print("ConsumableItem: Cargada escena automáticamente desde ", item_path)

# Sobreescribir el método serialize para incluir propiedades específicas
func serialize() -> Dictionary:
	var data = .serialize()
	data["heal_amount"] = heal_amount
	data["uses_left"] = uses_left
	data["item_scene_path"] = item_scene.resource_path if item_scene else ""
	return data

# Usar el item (consumirlo)
func use(player = null) -> bool:
	if not player or uses_left <= 0:
		return false
		
	if player.has_method("heal"):
		# Curar al jugador
		player.heal(heal_amount)
		
		# Reducir el número de usos
		uses_left -= 1
		
		# Retornar verdadero si el item se usó exitosamente
		return true
	
	return false

# Verificar si el consumible puede ser usado
func can_use(player = null) -> bool:
	return player != null and player.has_method("heal") and uses_left > 0

# Método para instanciar el consumible en el mundo
func instance_in_world(position: Vector2 = Vector2.ZERO) -> Node2D:
	if not item_scene:
		return null
	
	var item_instance = item_scene.instance()
	item_instance.position = position
	
	return item_instance

# Configurar un ConsumableItem a partir de un nodo de item existente
func configure_from_item_node(item_node: Node) -> void:
	if not item_node:
		return
	
	# Preservar el nombre del item
	self.id = item_node.name
	self.name = item_node.name
	
	# Asignar textura del item
	if item_node.has_node("Sprite"):
		self.icon = item_node.get_node("Sprite").texture
	elif item_node.has_node("AnimatedSprite"):
		var animated_sprite = item_node.get_node("AnimatedSprite")
		if animated_sprite.frames.has_animation("idle"):
			self.icon = animated_sprite.frames.get_frame("idle", 0)
	
	# Buscar la escena original
	var item_path = "res://Items/" + self.id + ".tscn"
	if ResourceLoader.exists(item_path):
		self.item_scene = load(item_path)
		print("ConsumableItem: Cargada escena desde ", item_path, " para ", self.name)
	else:
		print("ConsumableItem ERROR: No se pudo encontrar la escena para ", self.name, " en ", item_path)
	
	# Configurar propiedades específicas según el tipo de item
	if self.id.to_lower().find("health") >= 0 or self.id.to_lower().find("potion") >= 0:
		self.heal_amount = 1  # Valor por defecto, ajustar según la poción
		self.description = "Restaura " + str(self.heal_amount) + " punto de salud"
