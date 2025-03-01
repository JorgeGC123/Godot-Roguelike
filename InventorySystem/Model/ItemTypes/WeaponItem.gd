class_name WeaponItem
extends Item

# Propiedades específicas de armas
export(int) var damage: int = 1
export(float) var attack_speed: float = 1.0
export(PackedScene) var weapon_scene: PackedScene

func _init(p_id: String = "", p_name: String = "", p_description: String = "", p_icon = null).(p_id, p_name, p_description, p_icon):
	item_type = "weapon"
	
	# Si tenemos ID pero no tenemos weapon_scene, intentar cargar la escena
	if p_id != "" and not weapon_scene:
		# Limpiar posibles sufijos numéricos para obtener el tipo base de arma
		var base_id = p_id.rstrip("0123456789")
		var weapon_path = "res://Weapons/" + base_id + ".tscn"
		
		if ResourceLoader.exists(weapon_path):
			weapon_scene = load(weapon_path)
			print("WeaponItem: Cargada escena automáticamente desde ", weapon_path)

# Sobreescribir el método serialize para incluir propiedades específicas
func serialize() -> Dictionary:
	var data = .serialize()
	data["damage"] = damage
	data["attack_speed"] = attack_speed
	data["weapon_scene_path"] = weapon_scene.resource_path if weapon_scene else ""
	return data

# Equipar el arma al jugador
func use(player = null) -> bool:
	if not player or not weapon_scene:
		return false
		
	if player.has_method("pick_up_weapon"):
		var weapon_instance = weapon_scene.instance()
		# Configurar el arma con los datos del item
		weapon_instance.damage = damage
		# Otros ajustes necesarios
		
		player.pick_up_weapon(weapon_instance)
		return true
	
	return false

# Verificar si el arma puede ser usada (equipada)
func can_use(player = null) -> bool:
	return player != null and player.has_method("pick_up_weapon")

# Método para instanciar el arma en el mundo
func instance_in_world(position: Vector2 = Vector2.ZERO) -> Node2D:
	if not weapon_scene:
		return null
	
	var weapon_instance = weapon_scene.instance()
	weapon_instance.position = position
	weapon_instance.on_floor = true
	
	# Configuraciones adicionales
	if weapon_instance.has_method("set_stats"):
		weapon_instance.set_stats({
			"damage": damage,
			"attack_speed": attack_speed
		})
	
	return weapon_instance

# Crear un WeaponItem a partir de un nodo Weapon existente
# Ya no es una función estática, ahora será manejada por el ItemFactory
func configure_from_weapon_node(weapon_node: Node) -> void:
	if not weapon_node:
		return
	
	# Preservar el nombre único completo del arma
	self.id = weapon_node.name.rstrip("0123456789") # Solo para el ID base usamos sin sufijo
	self.name = weapon_node.name # Preservamos el nombre único completo
	
	# Asignar textura del arma
	if weapon_node.has_method("get_texture"):
		self.icon = weapon_node.get_texture()
	
	# Buscar la escena original (sin el sufijo numérico)
	var base_name = self.id # Ya quitamos los números arriba
	var weapon_path = "res://Weapons/" + base_name + ".tscn"
	if ResourceLoader.exists(weapon_path):
		self.weapon_scene = load(weapon_path)
		print("WeaponItem: Cargada escena desde ", weapon_path, " para ", self.name)
	else:
		print("WeaponItem ERROR: No se pudo encontrar la escena para ", self.name, " en ", weapon_path)
	
	# Obtener estadísticas
	if weapon_node.has_node("Node2D/Sprite/Hitbox"):
		var hitbox = weapon_node.get_node("Node2D/Sprite/Hitbox")
		self.damage = hitbox.damage
