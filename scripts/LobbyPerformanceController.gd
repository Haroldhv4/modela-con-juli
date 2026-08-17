extends Node

# Reduce el coste del preview 3D del Lobby sin cambiar el tamaño visual del panel.
# El SubViewport se renderiza a menor resolución y con FPS controlados; durante
# arrastre baja temporalmente otro nivel para evitar que equipos modestos se congelen.

const NORMAL_SIZE = Vector2i(512, 480)
const DRAG_SIZE = Vector2i(384, 360)
const IDLE_FPS = 18.0
const DRAG_FPS = 28.0

var lobby = null
var container = null
var viewport = null
var elapsed = 0.0
var touch_dragging = false
var last_drag_state = false
var last_size = Vector2i.ZERO

func _ready():
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	container = lobby.get_node_or_null("CharacterViewportContainer")
	viewport = lobby.get_node_or_null("CharacterViewportContainer/CharacterViewport")
	if viewport == null:
		push_warning("ModelaConJuli: no se encontró CharacterViewport para modo rendimiento")
		return

	# La interfaz conserva exactamente el mismo tamaño; solo reducimos el buffer 3D.
	_apply_preview_size(NORMAL_SIZE)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	set_process(true)
	set_process_input(true)

func _process(delta):
	if viewport == null or lobby == null:
		return

	var mouse_dragging = bool(lobby.get("character_dragging"))
	var dragging = mouse_dragging or touch_dragging
	if dragging != last_drag_state:
		last_drag_state = dragging
		_apply_preview_size(DRAG_SIZE if dragging else NORMAL_SIZE)
		_request_redraw()

	var target_fps = DRAG_FPS if dragging else IDLE_FPS
	elapsed += delta
	if elapsed >= 1.0 / target_fps:
		elapsed = 0.0
		_request_redraw()

func _input(event):
	if container == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_dragging = container.get_global_rect().has_point(event.position)
		else:
			touch_dragging = false

func _apply_preview_size(value: Vector2i):
	if viewport == null or value == last_size:
		return
	last_size = value
	viewport.size = value
	# Desactivamos extras caros que no aportan casi nada en la mini-vista del lobby.
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.use_taa = false
	viewport.use_debanding = false

func _request_redraw():
	if viewport:
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
