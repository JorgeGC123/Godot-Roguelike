class_name SwordDefenseHandler
extends Reference

# Referencias a nodos necesarios
var weapon: Weapon
var player: Node2D
var animation_player: AnimationPlayer
var hitbox_collision: CollisionShape2D
var node2d: Node2D
var sprite: Sprite

# Configuración
export var defense_stamina_cost: int = 20
export var defense_distance: float = 5 # Reducido de 10 a 5 para que esté más cerca del jugador

# Estado
var is_defending: bool = false

func _init(weapon_instance: Weapon):
	self.weapon = weapon_instance
	self.player = weapon_instance.player
	print("DEBUG: SwordDefenseHandler inicializado, player: ", player)
	self.animation_player = weapon_instance.animation_player
	self.node2d = weapon_instance.get_node("Node2D")
	self.sprite = weapon_instance.get_node("Node2D/Sprite")
	self.hitbox_collision = weapon_instance.get_node("Node2D/Sprite/Hitbox/CollisionShape2D")

# Activa la posición defensiva
func activate_defense() -> bool:
	# Verificar que hay suficiente stamina
	print("DEBUG: Verificando condiciones en activate_defense()")
	print("DEBUG: player: ", player, ", player válido: ", is_instance_valid(player))
	
	if !player:
		print("DEBUG: player es null o inválido")
		return false
		
	print("DEBUG: player.stamina: ", player.stamina, ", defense_stamina_cost: ", defense_stamina_cost)
	if player.stamina < defense_stamina_cost:
		print("DEBUG: Stamina insuficiente")
		return false
		
	# Consumir stamina
	consume_stamina()
	
	# Posicionar la espada defensivamente
	position_weapon_defensively()
	
	# Marcar como defendiendo
	is_defending = true
	return true

# Desactiva la posición defensiva
func deactivate_defense() -> void:
	if !is_defending:
		return
		
	# Desactivar el hitbox
	if hitbox_collision and is_instance_valid(hitbox_collision):
		hitbox_collision.disabled = true
	
	# Desconectar la señal de colisión si estaba conectada
	var hitbox = weapon.hitbox
	if hitbox.is_connected("area_entered", self, "_on_defensive_hitbox_area_entered"):
		hitbox.disconnect("area_entered", self, "_on_defensive_hitbox_area_entered")
	
	# Volver a posición normal
	if animation_player and is_instance_valid(animation_player):
		animation_player.play("cancel_attack")
		
	# Restaurar posición original del arma (junto al jugador)
	if weapon:
		weapon.position = Vector2.ZERO
	
	# Actualizar estado
	is_defending = false
	print("DEBUG: Defensa desactivada")

# Actualiza la posición del arma mientras se está defendiendo
func update_defense_position() -> void:
	if !is_defending or !player or !weapon:
		return
		
	# Obtener la dirección hacia el ratón
	var mouse_pos = weapon.get_global_mouse_position()
	var player_pos = player.global_position
	var direction = (mouse_pos - player_pos).normalized()
	
	# Calcular la rotación para colocar la espada perpendicular a la dirección
	var angle = direction.angle()
	
	# Posicionar la espada frente al jugador
	weapon.global_position = player_pos + direction * defense_distance
	
	# Orientar horizontalmente
	node2d.rotation = angle + PI/2
	
	# Ajustar la orientación del sprite
	sprite.rotation = -PI/4

func position_weapon_defensively() -> void:
	# Obtener la dirección hacia el ratón
	print("DEBUG: Calculando posición defensiva")
	var mouse_pos = weapon.get_global_mouse_position()
	var player_pos = player.global_position
	var direction = (mouse_pos - player_pos).normalized()
	
	# Calcular la rotación para colocar la espada perpendicular a la dirección
	var angle = direction.angle()
	print("DEBUG: Ángulo: ", rad2deg(angle), ", dirección: ", direction)
	
	# Posicionar la espada frente al jugador
	weapon.global_position = player_pos + direction * defense_distance
	print("DEBUG: Posición del arma: ", weapon.global_position)
	
	# Orientar horizontalmente
	node2d.rotation = angle + PI/2 # +90 grados
	
	# Ajustar la orientación del sprite
	sprite.rotation = -PI/4 # -45 grados
	
	# Activar el hitbox para colisión de armas
	hitbox_collision.disabled = false
	
	# Configurar hitbox para detectar colisiones con otras armas
	var hitbox = weapon.hitbox
	hitbox.set_collision_layer_bit(3, true) # Capa para hitboxes de armas
	hitbox.set_collision_mask_bit(3, true) # Detectar otras hitboxes de armas
	
	# Conectar la señal de colisión de áreas si no está conectada ya
	if not hitbox.is_connected("area_entered", self, "_on_defensive_hitbox_area_entered"):
		hitbox.connect("area_entered", self, "_on_defensive_hitbox_area_entered")
		
	# Debug
	print("Sword positioned defensively at angle: ", rad2deg(angle))

# Manejador de colisión para modo defensivo
func _on_defensive_hitbox_area_entered(area: Area2D) -> void:
	# Verificar si el área es un hitbox de otra arma
	if area.get_collision_layer_bit(3):
		# Encontrar a qué arma pertenece este hitbox
		var other_weapon = _find_parent_weapon(area)
		
		if other_weapon and other_weapon != weapon:
			# Verificar si la otra arma está atacando
			var other_animation_player = other_weapon.get_node("AnimationPlayer")
			if other_animation_player and other_animation_player.is_playing():
				print("¡Colisión de defensa! " + weapon.name + " (defensa) vs " + other_weapon.name + " (ataque)")
				
				# Intentar cancelar el ataque de la otra arma
				if other_weapon.has_method("cancel_attack"):
					other_weapon.cancel_attack()
				else:
					# Puede que sea un WeaponComponent de NPC
					var parent = other_weapon.get_parent()
					if parent and parent.has_method("cancel_attack"):
						parent.cancel_attack()
					# Si no, buscar en el árbol hacia arriba
					else:
						var ancestor = other_weapon.get_parent().get_parent()
						if ancestor and ancestor.has_method("cancel_attack"):
							ancestor.cancel_attack()
				
				# Crear efecto de colisión de espadas en el punto de colisión
				var collision_effect: CPUParticles2D = weapon.SWORD_COLLISION_SCENE.instance()
				var collision_dir = (weapon.global_position - other_weapon.global_position).normalized()
				collision_effect.global_rotation = collision_dir.angle()
				collision_effect.global_position = area.global_position
				
				var main_scene = weapon.get_tree().root
				main_scene.add_child(collision_effect)
				collision_effect.z_index = 1

				# Añadir la partícula a la lista en el singleton para luego borrarlas
				SceneTransistor.add_blood_effect(collision_effect)

func consume_stamina() -> void:
	if player.has_method("reduce_stamina"):
		player.reduce_stamina(defense_stamina_cost)

# Busca recursivamente el nodo Weapon padre de un nodo
func _find_parent_weapon(node: Node) -> Node:
	# Buscar recursivamente hasta encontrar un nodo que probablemente sea un arma
	var parent = node.get_parent()
	# En lugar de comparar con el tipo, verificamos si tiene los componentes típicos de un arma
	while parent and not (parent.has_node("AnimationPlayer") and parent.has_node("Node2D/Sprite/Hitbox")):
		parent = parent.get_parent()
	return parent

func cleanup() -> void:
	# Asegurar que se desactiva la defensa
	if is_defending:
		deactivate_defense()
