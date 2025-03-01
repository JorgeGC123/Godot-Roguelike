class_name SlotUI
extends TextureRect

# Implementamos un handler para eventos directos
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("SlotUI[" + str(index) + "]: Recibido click directo")

signal item_dropped(from_index, to_index)

export(StyleBox) var normal_style: StyleBox
export(StyleBox) var hover_style: StyleBox
export(StyleBox) var selected_style: StyleBox

var index: int = -1
var item: Item = null
var selected: bool = false
var hovered: bool = false

onready var item_texture = $ItemTexture
onready var selection_panel = $SelectionPanel
onready var border = $Border

func _ready():
	# STOP significa que este nodo captura eventos y no los pasa a nodos por debajo
	# pero los sigue enviando a sus padres si no los procesa
	mouse_filter = MOUSE_FILTER_STOP
	
	# Configurar estilos visuales
	if normal_style:
		self_modulate = normal_style.bg_color
	
	# Configurar elementos visuales
	selection_panel.visible = false
	
	# Depuración
	print("SlotUI inicializado: ", get_path(), " - mouse_filter: ", mouse_filter)
	
	# Por defecto el slot está vacío
	item_texture.texture = null

# Establecer el item en el slot
func set_item(new_item: Item):
	print("SlotUI[" + str(index) + "]: set_item llamado con item: ", new_item.name if new_item else "None")

	item = new_item
	if item and item.icon:
		item_texture.texture = item.icon
		item_texture.visible = true
	else:
		item_texture.texture = null
		item_texture.visible = false
	
	# Forzar actualización visual
	update()

# Limpiar el slot
func clear_item():
	item = null
	item_texture.texture = null
	item_texture.visible = false

# Seleccionar el slot
func select():
	selected = true
	if selected_style:
		selection_panel.visible = true
		selection_panel.add_stylebox_override("panel", selected_style)

# Deseleccionar el slot
func deselect():
	selected = false
	selection_panel.visible = false

# Aplicar estilo de hover
func highlight():
	hovered = true
	if hover_style:
		self_modulate = hover_style.bg_color

# Quitar estilo de hover
func unhighlight():
	hovered = false
	if normal_style:
		self_modulate = normal_style.bg_color

# Funciones para drag & drop
func get_drag_data(position):
	print("SlotUI: get_drag_data llamado en slot ", index)
	if not item:
		print("SlotUI: No hay item para arrastrar")
		return null
	
	# Crear datos para el drag
	var data = {
		"source_index": index,
		"item": item
	}
	
	# Crear preview visual
	var drag_preview = TextureRect.new()
	drag_preview.texture = item.icon
	drag_preview.rect_size = rect_size
	drag_preview.modulate = Color(1, 1, 1, 0.7)
	
	# Centrar preview en el puntero
	var control = Control.new()
	control.add_child(drag_preview)
	drag_preview.rect_position = -drag_preview.rect_size / 2
	
	set_drag_preview(control)
	
	# Debug
	print("Drag started from slot: ", index, " with item: ", item.name if item else "none")
	
	return data

func can_drop_data(position, data):
	var can_drop = data is Dictionary and data.has("source_index")
	return can_drop

func drop_data(position, data):
	var source_index = data.get("source_index", -1)
	
	# Debug 
	print("Dropping from slot ", source_index, " to slot ", index)
	
	# No hacer nada si es el mismo slot
	if source_index == index:
		return
		
	emit_signal("item_dropped", source_index, index)

# Conectar señales de ratón
func _on_Border_mouse_entered():
	highlight()

func _on_Border_mouse_exited():
	unhighlight()
