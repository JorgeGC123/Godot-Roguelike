extends Node

signal slow_motion_started(scale)
signal slow_motion_ended

export var default_time_scale: float = 1.0
export var min_time_scale: float = 0.05  # Cámara súper lenta
export var toggle_slow_motion_scale: float = 0.3  # Escala usada con el toggle
var toggle_active: bool = false
export var transition_duration: float = 0.2  # Segundos para transición suave

var _current_scale: float = 1.0
var _target_scale: float = 1.0
var _transitioning: bool = false
var _timer: float = 0.0
var _duration_timer: float = 0.0
var _duration: float = 0.0

func _ready():
	print("SlowMotionManager inicializado!")
	# Verificar si tenemos el efecto visual
	var effect_rect = get_node_or_null("CanvasLayer/VisualEffect")
	if effect_rect:
		print("Efecto visual disponible")
	else:
		push_warning("SlowMotionManager: no se encontró el efecto visual")

func _input(event):
	if event.is_action_pressed("ui_slow_motion"):
		toggle_slow_motion()

func toggle_slow_motion():
	toggle_active = !toggle_active
	if toggle_active:
		start_slow_motion(toggle_slow_motion_scale)
	else:
		restore_normal_time()

func _process(delta):
	if _transitioning:
		_timer += delta / _current_scale  # Delta ajustado por escala de tiempo actual
		var t = min(_timer / transition_duration, 1.0)
		
		# Interpolación suave
		var new_scale = lerp(_current_scale, _target_scale, ease(t, 0.5))
		_current_scale = new_scale
		Engine.time_scale = new_scale
		
		if t >= 1.0:
			_transitioning = false
			_timer = 0.0
			_current_scale = _target_scale
			
			# Si hemos vuelto a la normalidad, emitir señal
			if _target_scale == default_time_scale:
				emit_signal("slow_motion_ended")
				_on_slow_motion_ended()
	
	# Gestionar temporizador de duración
	if _duration > 0:
		_duration_timer += delta / _current_scale
		if _duration_timer >= _duration:
			restore_normal_time()
			_duration = 0
			_duration_timer = 0

# Inicia cámara lenta con una escala dada y duración opcional
func start_slow_motion(scale: float = 0.3, duration: float = 0.0) -> void:
	if scale < min_time_scale:
		scale = min_time_scale
	
	_target_scale = scale
	_transitioning = true
	_timer = 0.0
	
	# Configurar duración si se proporciona
	if duration > 0:
		_duration = duration
		_duration_timer = 0.0
	
	emit_signal("slow_motion_started", scale)
	_on_slow_motion_started(scale)

# Restaura el tiempo normal
func restore_normal_time() -> void:
	_target_scale = default_time_scale
	_transitioning = true
	_timer = 0.0
	_duration = 0.0

# Instantáneo - sin transición
func set_time_scale_immediate(scale: float) -> void:
	_current_scale = scale
	_target_scale = scale
	Engine.time_scale = scale
	
	if scale < default_time_scale:
		emit_signal("slow_motion_started", scale)
		_on_slow_motion_started(scale)
	else:
		emit_signal("slow_motion_ended")
		_on_slow_motion_ended()

# Obtener escala de tiempo actual
func get_current_time_scale() -> float:
	return _current_scale

# Estamos en cámara lenta?
func is_in_slow_motion() -> bool:
	return _current_scale < default_time_scale or _transitioning and _target_scale < default_time_scale

# Métodos para gestionar efectos visuales
func _on_slow_motion_started(scale):
	print("Modo cámara lenta ACTIVADO - escala: ", scale)
	# Activar efecto visual si existe
	var effect_rect = get_node_or_null("CanvasLayer/VisualEffect")
	if effect_rect:
		var effect_tween = get_node("EffectTween")
		effect_tween.stop_all()
		effect_tween.interpolate_property(effect_rect.material, "shader_param/intensity",
			effect_rect.material.get_shader_param("intensity"), 1.0, 0.2 / scale, 
			Tween.TRANS_SINE, Tween.EASE_OUT)
		effect_tween.start()

func _on_slow_motion_ended():
	print("Modo cámara lenta DESACTIVADO")
	# Desactivar efecto visual si existe
	var effect_rect = get_node_or_null("CanvasLayer/VisualEffect")
	if effect_rect:
		var effect_tween = get_node("EffectTween")
		effect_tween.stop_all()
		effect_tween.interpolate_property(effect_rect.material, "shader_param/intensity",
			effect_rect.material.get_shader_param("intensity"), 0.0, 0.2, 
			Tween.TRANS_SINE, Tween.EASE_IN)
		effect_tween.start()
