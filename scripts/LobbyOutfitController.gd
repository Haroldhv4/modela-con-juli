extends Node

const OutfitRuntime = preload("res://scripts/OutfitRuntime.gd")
const CLOTHING_CATEGORIES = ["tops", "bottoms", "shoes"]

var lobby = null
var world = null
var active_variant = OutfitRuntime.DEFAULT_VARIANT
var last_equipped = {}
var initialized = false
var touch_dragging = false

# El siguiente outfit se prepara en un hilo. El actual permanece visible hasta
# que el reemplazo ya está instanciado, evitando pantallas vacías y bloqueos largos.
var pending_variant = ""
var pending_animate = false
var pending_started_msec = 0

func _ready():
	set_process(false)
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	world = lobby.get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld")
	if world == null:
		push_error("ModelaConJuli: no se encontró CharacterWorld en Lobby")
		return

	var current = lobby.get("equipped")
	if current is Dictionary:
		last_equipped = current.duplicate(true)

	var saved_variant = OutfitRuntime.load_variant()
	if OutfitRuntime.is_valid_variant(saved_variant):
		active_variant = saved_variant
	else:
		active_variant = OutfitRuntime.variant_from_equipped(last_equipped)

	initialized = true
	set_process(true)
	set_process_input(true)
	_request_character(active_variant, false)

func _process(_delta):
	if not initialized or lobby == null:
		return

	_poll_pending_character()

	var current = lobby.get("equipped")
	if not (current is Dictionary):
		return

	var changed_category = ""
	for category in CLOTHING_CATEGORIES:
		if str(current.get(category, "")) != str(last_equipped.get(category, "")):
			changed_category = category
			break

	if changed_category != "":
		var item_id = str(current.get(changed_category, ""))
		var next_variant = OutfitRuntime.variant_from_item(changed_category, item_id)
		if next_variant != "" and (next_variant != active_variant or world.get_node_or_null("Juli") == null):
			_request_character(next_variant, true)

	last_equipped = current.duplicate(true)

func _input(event):
	# Android: arrastre horizontal gira y vertical controla zoom. No tocamos huesos
	# durante el drag; rotar el nodo raíz es mucho más barato para la GPU/CPU.
	if not initialized or lobby == null:
		return

	var container = lobby.get_node_or_null("CharacterViewportContainer")
	if container == null:
		return

	if event is InputEventScreenTouch:
		var inside = container.get_global_rect().has_point(event.position)
		if event.pressed and inside:
			touch_dragging = true
			if event.double_tap:
				_reset_touch_view()
			get_viewport().set_input_as_handled()
		elif not event.pressed:
			touch_dragging = false

	elif event is InputEventScreenDrag and touch_dragging:
		var yaw_value = float(lobby.get("character_yaw"))
		yaw_value += event.relative.x * 0.30
		lobby.set("character_yaw", yaw_value)

		var camera = lobby.get("character_camera")
		if camera:
			var z_value = float(lobby.get("character_camera_z"))
			z_value = clamp(z_value + event.relative.y * 0.007, 3.25, 4.75)
			lobby.set("character_camera_z", z_value)
			var camera_position = camera.position
			camera_position.z = z_value
			camera.position = camera_position

		get_viewport().set_input_as_handled()

func _reset_touch_view():
	lobby.set("character_yaw", 0.0)
	lobby.set("character_camera_z", 4.04)
	var camera = lobby.get("character_camera")
	if camera:
		var camera_position = camera.position
		camera_position.z = 4.04
		camera.position = camera_position

func _request_character(variant: String, animate: bool):
	if world == null or not OutfitRuntime.is_valid_variant(variant):
		return

	if variant == active_variant and world.get_node_or_null("Juli") != null and pending_variant == "":
		return

	pending_variant = variant
	pending_animate = animate
	pending_started_msec = Time.get_ticks_msec()

	var error = OutfitRuntime.request_variant(variant)
	if error != OK:
		pending_variant = ""
		_show_message("No se pudo preparar el outfit 3D")
		push_error("ModelaConJuli: fallo al solicitar outfit " + variant + " error=" + str(error))
		return

	_show_message("Preparando outfit 3D…")

func _poll_pending_character():
	if pending_variant == "":
		return

	var requested_variant = pending_variant
	var status = OutfitRuntime.variant_load_status(requested_variant)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var next_character = OutfitRuntime.instantiate_requested_variant(requested_variant)
		if next_character == null:
			pending_variant = ""
			_show_message("No se pudo mostrar ese outfit")
			return

		if requested_variant != pending_variant:
			next_character.queue_free()
			return

		var animate = pending_animate
		pending_variant = ""
		_commit_character_swap(next_character, requested_variant, animate)
		return

	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pending_variant = ""
		_show_message("No se pudo cargar ese outfit")
		push_error("ModelaConJuli: carga de outfit fallida: " + requested_variant)

func _commit_character_swap(next_character: Node3D, variant: String, animate: bool):
	if world == null or next_character == null:
		return

	var current_yaw = float(lobby.get("character_yaw"))
	var existing = world.get_node_or_null("Juli")
	if existing:
		current_yaw = existing.rotation_degrees.y

	next_character.name = "JuliIncoming"
	next_character.position = Vector3(0.0, -0.15, 0.0)
	next_character.rotation_degrees = Vector3(0.0, current_yaw, 0.0)
	next_character.scale = Vector3.ONE
	next_character.visible = false
	world.add_child(next_character)

	lobby.set("character_node", next_character)
	lobby.set("character_base_y", -0.15)
	lobby.set("character_yaw", current_yaw)

	next_character.visible = true
	if existing:
		existing.visible = false
		existing.name = "JuliOutgoing"
		world.remove_child(existing)
		existing.queue_free()
	next_character.name = "Juli"

	active_variant = variant
	OutfitRuntime.save_variant(active_variant)

	if animate:
		next_character.scale = Vector3(0.985, 0.985, 0.985)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(next_character, "scale", Vector3.ONE, 0.12)

	var pretty = {
		"base": "Base",
		"normal": "Casual",
		"school": "Escolar",
		"yukata": "Yukata"
	}
	_show_message("Outfit 3D: " + str(pretty.get(active_variant, active_variant)))

func _show_message(text: String):
	if lobby == null:
		return
	var toast_method = Callable(lobby, "_show_toast")
	if toast_method.is_valid():
		toast_method.call(text)
