class_name BloodSplashComponent
extends Component

export var amount: int = 32
export var spread: float = 43.01
export var initial_velocity: float = 100.0
export var lifetime: float = 0.6

var blood_splash_scene = preload("res://Characters/BloodSplash.tscn")

func _init(entity: Node).(entity):
    pass

func initialize():
    pass

func spawn_blood_splash(position: Vector2, direction: Vector2):
    var blood_splash = blood_splash_scene.instance()
    blood_splash.global_position = position
    blood_splash.rotation = direction.angle()
    blood_splash.amount = amount
    blood_splash.spread = spread
    blood_splash.initial_velocity = initial_velocity
    blood_splash.lifetime = lifetime
    
    var main_scene = entity.get_tree().current_scene
    main_scene.add_child(blood_splash)
    
    # Añadir la partícula a la lista en el singleton de la escena para luego borrarlas
    if main_scene.has_method("add_blood_effect"):
        main_scene.add_blood_effect(blood_splash)