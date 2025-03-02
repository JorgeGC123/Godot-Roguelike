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
export var defense_distance: float = 10

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
	
	# Volver a posición normal
	if animation_player and is_instance_valid(animation_player):
		animation_player.play("cancel_attack")
	
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
	
	# Activar el hitbox
	hitbox_collision.disabled = false
	
	# Debug
	print("Sword positioned defensively at angle: ", rad2deg(angle))

func consume_stamina() -> void:
	if player.has_method("reduce_stamina"):
		player.reduce_stamina(defense_stamina_cost)

func cleanup() -> void:
	# Asegurar que se desactiva la defensa
	if is_defending:
		deactivate_defense()
