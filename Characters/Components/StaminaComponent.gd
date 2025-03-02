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
var stamina_accumulated: float = 0.0  # Acumulador para valores decimales

func _init(entity: Node).(entity):
	pass

func initialize():
	stamina = max_stamina
	emit_signal("stamina_changed", stamina, max_stamina)

func update(delta: float):
	# Debug temporal
	if entity.name.find("Enemy") >= 0 and entity.get_instance_id() % 10 == 0:
		print("Stamina: ", stamina, ", can_regenerate: ", can_regenerate, ", timer: ", regen_timer)
	
	if not can_regenerate:
		regen_timer += delta
		if regen_timer >= stamina_regen_delay:
			print("Reactivando regeneración")
			can_regenerate = true
			regen_timer = 0.0
	
	if can_regenerate and stamina < max_stamina:
		# Acumulamos la cantidad a regenerar
		stamina_accumulated += stamina_regen_rate * delta
		
		# Solo aplicamos cuando acumulamos al menos 1 punto
		if stamina_accumulated >= 1.0:
			var amount_to_add = int(stamina_accumulated)
			stamina_accumulated -= amount_to_add  # Guardamos el remanente
			var old_stamina = stamina
			stamina = min(stamina + amount_to_add, max_stamina)
			
			print("Regenerando stamina: ", old_stamina, " -> ", stamina, " (acumulado: ", stamina_accumulated, ")")
			emit_signal("stamina_changed", stamina, max_stamina)
		
		if stamina == max_stamina:
			print("Stamina completamente recuperada")
			emit_signal("stamina_recovered")

func use_stamina(amount: int) -> bool:
	# Si el amount es inválido (negativo o cero), no hacemos nada
	if amount <= 0:
		return false
	
	# Si no hay suficiente stamina, devolvemos false pero no realizamos cambios
	if amount > stamina:
		return false
	
	# Reducir la stamina
	stamina -= amount
	emit_signal("stamina_changed", stamina, max_stamina)
	
	print("Stamina reducida a: ", stamina, ", amount: ", amount)
	
	# Si la stamina llega a 0, emitimos la señal de agotamiento
	if stamina <= 0:
		print("Stamina agotada!")
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
