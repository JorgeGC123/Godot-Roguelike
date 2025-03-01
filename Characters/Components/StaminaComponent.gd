class_name StaminaComponent
extends Component

signal stamina_changed(new_stamina, max_stamina)
signal stamina_depleted()
signal stamina_recovered()

export var max_stamina: int = 100
export var stamina: int = 100
export var stamina_regen_rate: float = 10.0  # Stamina recuperada por segundo
export var stamina_regen_delay: float = 1.0  # Segundos de espera antes de regenerar

var regen_timer: float = 0.0
var can_regenerate: bool = true

func _init(entity: Node).(entity):
	pass

func initialize():
	stamina = max_stamina
	emit_signal("stamina_changed", stamina, max_stamina)

func update(delta: float):
	if not can_regenerate:
		regen_timer += delta
		if regen_timer >= stamina_regen_delay:
			can_regenerate = true
			regen_timer = 0.0
	
	if can_regenerate and stamina < max_stamina:
		var stamina_to_add = stamina_regen_rate * delta
		stamina = min(stamina + stamina_to_add, max_stamina)
		emit_signal("stamina_changed", stamina, max_stamina)
		
		if stamina == max_stamina:
			emit_signal("stamina_recovered")

func use_stamina(amount: int) -> bool:
	if amount <= 0 or amount > stamina:
		return false
	
	stamina -= amount
	emit_signal("stamina_changed", stamina, max_stamina)
	
	if stamina <= 0:
		emit_signal("stamina_depleted")
	
	# Reiniciar el timer de regeneración
	can_regenerate = false
	regen_timer = 0.0
	
	return true

func has_stamina(amount: int) -> bool:
	return stamina >= amount

func get_stamina_percentage() -> float:
	return float(stamina) / float(max_stamina) * 100.0

func receive_message(message: String, data: Dictionary):
	match message:
		"attack_started":
			# Parar regeneración brevemente
			can_regenerate = false
			regen_timer = 0.0
