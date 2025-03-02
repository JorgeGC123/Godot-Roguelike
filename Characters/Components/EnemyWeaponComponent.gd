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
    
    # Comprobar que el arma tiene métodos de coste de stamina
    if weapon and weapon.has_method("get_basic_attack_cost"):
        print("Arma configurada con coste: ", weapon.get_basic_attack_cost())
    else:
        print("Advertencia: El arma no proporciona métodos para obtener costes de stamina")

# Sobrescribir el método execute_attack para usar la stamina del NPC
func execute_attack():
    is_charging = false
    is_attacking = true
    charge_particles.emitting = false
    
    # Obtener el componente de stamina directamente
    var stamina_component = null
    if entity.has_method("get_component"):
        stamina_component = entity.get_component("stamina")
    
    # Obtener coste directamente del arma
    var attack_cost = 5  # Valor por defecto
    if weapon and weapon.has_method("get_basic_attack_cost"):
        attack_cost = weapon.get_basic_attack_cost()
    else:
        # Fallback a constante del NPC si existe
        if entity.has_method("get") and entity.get("BASIC_ATTACK_STAMINA") != null:
            attack_cost = entity.BASIC_ATTACK_STAMINA
    
    # Depuración: imprimir valores de stamina
    print("EnemyWeaponComponent: Usando coste de ataque = ", attack_cost)
    if stamina_component:
        print("EnemyWeaponComponent: stamina actual = ", stamina_component.stamina)
    
    var has_enough = false
    if stamina_component:
        has_enough = stamina_component.has_stamina(attack_cost)
    print("Suficiente stamina: ", has_enough, " (necesita ", attack_cost, ")")
    
    # Verificar si hay suficiente stamina para el ataque
    if stamina_component and stamina_component.has_stamina(attack_cost):
        animation_player.play("attack")
        stamina_component.use_stamina(attack_cost)
        emit_signal("attack_started")
    else:
        # Si no hay suficiente stamina, cancelar ataque
        cancel_attack()
        print("Ataque cancelado por stamina insuficiente")

# Sobrescribir el método start_charge para usar el tiempo de carga del enemigo
func start_charge():
    if not is_charging and not is_attacking:
        is_charging = true
        animation_player.play("charge")
        charge_particles.emitting = true
        charge_timer.start(enemy_charge_time)
