class_name EnemyWeaponComponent
extends WeaponComponent

export var enemy_attack_cooldown: float = 3.0  # Tiempo entre ataques para enemigos
export var enemy_charge_time: float = 1.5      # Tiempo de carga para enemigos

func _init(entity: Node2D, weapon_scene: PackedScene).(entity, weapon_scene):
    pass
    
func initialize():
    .initialize()  # Llamar al initialize del padre
    
    # Sobrescribir los tiempos para enemigos
    attack_cooldown = enemy_attack_cooldown
    charge_time = enemy_charge_time

# Sobrescribir el método execute_attack para usar la stamina del NPC
func execute_attack():
    is_charging = false
    is_attacking = true
    charge_particles.emitting = false
    
    # Usa las constantes definidas en la entidad
    if entity.has_method("get_stamina") and entity.get_stamina() >= entity.BASIC_ATTACK_STAMINA:
        animation_player.play("attack")
        entity.reduce_stamina(entity.BASIC_ATTACK_STAMINA)
        emit_signal("attack_started")
    else:
        cancel_attack()
