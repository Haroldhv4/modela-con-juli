extends Node

const OutfitRuntime = preload("res://scripts/OutfitRuntime.gd")
const CLOTHING_CATEGORIES = ["tops", "bottoms", "shoes"]

var lobby = null
var world = null
var active_variant = OutfitRuntime.DEFAULT_VARIANT
var last_equipped = {}
var initialized = false
var touch_dragging = false

# Carga asíncrona del siguiente outfit. El personaje actual permanece visible
# mientras el nuevo GLB se prepara en segundo plano.
var pending_variant = ""
var pending_animate = false
var pending_started_msec = 0
var pending_toast_shown = false

# Idle esquelético ligero para que Chiyo no parezca una imagen estática.
var idle_skeleton = null
var idle_indices = {}
var idle_base = {}
var idle_clock = 0.0

func _ready():
	set_process(false)
	# Los hijos reciben _ready antes que el nodo Lobby. Esperamos a que la UI haya
	# creado y configurado cámara, luces y variables públicas del personaje.
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

func _process(delta):
	if not initialized or lobby == null:
		return

	_poll_pending_character()

	var current = lobby.get("equipped")
	if current is Dictionary:
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

	_animate_idle(delta)

func _input(event):
	# Control táctil adicional para Android. En PC se conserva el mouse/rueda que ya
	# maneja LobbyUI_v11. En celular: arrastrar horizontal gira y vertical hace zoom.
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
		yaw_value += event.relative.x * 0.34
		lobby.set("character_yaw", yaw_value)

		var camera = lobby.get("character_camera")
		if camera:
			var z_value = float(lobby.get("character_camera_z"))
			z_value = clamp(z_value + event.relative.y * 0.008, 3.25, 4.75)
			lobby.set("character_camera_z", z_value)
			var position = camera.position
			position.z = z_value
			camera.position = position

		get_viewport().set_input_as_handled()

func _reset_touch_view():
	lobby.set("character_yaw", 0.0)
	lobby.set("character_camera_z", 4.04)
	var camera = lobby.get("character_camera")
	if camera:
		var position = camera.position
		position.z = 4.04
		camera.position = position

func _request_character(variant: String, animate: bool):
	if world == null or not OutfitRuntime.is_valid_variant(variant):
		return

	# Si el mismo outfit ya está visible, no hacemos trabajo extra.
	if variant == active_variant and world.get_node_or_null("Juli") != null and pending_variant == "":
		return

	pending_variant = variant
	pending_animate = animate
	pending_started_msec = Time.get_ticks_msec()
	pending_toast_shown = false

	var error = OutfitRuntime.request_variant(variant)
	if error != OK:
		pending_variant = ""
		_show_load_message("No se pudo preparar el outfit 3D")
		push_error("ModelaConJuli: fallo al solicitar outfit " + variant + " error=" + str(error))
		return

	# El toast informa sin esconder el personaje ni bloquear la interfaz.
	_show_load_message("Preparando outfit 3D…")
	pending_toast_shown = true

func _poll_pending_character():
	if pending_variant == "":
		return

	var requested_variant = pending_variant
	var status = OutfitRuntime.variant_load_status(requested_variant)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# Si una máquina tarda bastante, mantenemos el outfit anterior visible y damos
		# feedback; nunca quitamos el personaje antes de tener listo el reemplazo.
		if not pending_toast_shown and Time.get_ticks_msec() - pending_started_msec > 350:
			_show_load_message("Cargando outfit 3D…")
			pending_toast_shown = true
		return

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var next_character = OutfitRuntime.instantiate_requested_variant(requested_variant)
		if next_character == null:
			pending_variant = ""
			_show_load_message("No se pudo mostrar ese outfit")
			return

		# La petición activa pudo cambiar mientras cargaba otro modelo. Solo aplicamos
		# el outfit que sigue siendo el seleccionado por el usuario.
		if requested_variant != pending_variant:
			next_character.queue_free()
			return

		var animate = pending_animate
		pending_variant = ""
		pending_toast_shown = false
		_commit_character_swap(next_character, requested_variant, animate)
		return

	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pending_variant = ""
		pending_toast_shown = false
		_show_load_message("No se pudo cargar ese outfit")
		push_error("ModelaConJuli: carga de outfit fallida: " + requested_variant)

func _commit_character_swap(next_character: Node3D, variant: String, animate: bool):
	if world == null or next_character == null:
		return

	var current_yaw = 0.0
	var existing = world.get_node_or_null("Juli")
	if existing:
		current_yaw = existing.rotation_degrees.y
	else:
		var yaw_value = lobby.get("character_yaw")
		if yaw_value != null:
			current_yaw = float(yaw_value)

	# Montamos primero el nuevo personaje fuera de la vista. Solo cuando ya está
	# dentro del árbol ocultamos/eliminamos el anterior. Así nunca existe un frame vacío.
	next_character.name = "JuliIncoming"
	next_character.position = Vector3(0.0, -0.15, 0.0)
	next_character.rotation_degrees = Vector3(0.0, current_yaw, 0.0)
	next_character.scale = Vector3.ONE
	next_character.visible = false
	world.add_child(next_character)

	# Aplicamos estado al nodo entrante antes de hacerlo visible.
	lobby.set("character_node", next_character)
	lobby.set("character_base_y", -0.15)
	lobby.set("character_yaw", current_yaw)
	_prepare_idle_skeleton(next_character)

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
		next_character.scale = Vector3(0.97, 0.97, 0.97)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(next_character, "scale", Vector3.ONE, 0.16)

	var pretty = {
		"base": "Base",
		"normal": "Casual",
		"school": "Escolar",
		"yukata": "Yukata"
	}
	_show_load_message("Outfit 3D: " + str(pretty.get(active_variant, active_variant)))

func _show_load_message(text: String):
	if lobby == null:
		return
	var toast_method = Callable(lobby, "_show_toast")
	if toast_method.is_valid():
		toast_method.call(text)

func _prepare_idle_skeleton(character: Node):
	idle_skeleton = OutfitRuntime.find_first_skeleton(character)
	idle_indices.clear()
	idle_base.clear()
	idle_clock = 0.0
	if idle_skeleton == null:
		return

	var definitions = {
		"spine": ["spine", "chest", "upperchest"],
		"head": ["head"],
		"left_arm": ["leftupperarm", "lupperarm", "upperarml", "leftarm"],
		"right_arm": ["rightupperarm", "rupperarm", "upperarmr", "rightarm"]
	}
	for key_variant in definitions.keys():
		var key = str(key_variant)
		var index = _find_idle_bone(definitions[key_variant])
		if index >= 0:
			idle_indices[key] = index
			idle_base[key] = idle_skeleton.get_bone_pose_rotation(index)

func _find_idle_bone(tokens: Array) -> int:
	if idle_skeleton == null:
		return -1
	for i in range(idle_skeleton.get_bone_count()):
		var bone_name = _normalize_bone(str(idle_skeleton.get_bone_name(i)))
		for token_variant in tokens:
			if bone_name.find(_normalize_bone(str(token_variant))) != -1:
				return i
	return -1

func _normalize_bone(value: String) -> String:
	return value.to_lower().replace("_", "").replace("-", "").replace(".", "").replace(" ", "")

func _animate_idle(delta):
	if idle_skeleton == null:
		return
	idle_clock += delta
	_apply_idle_bone("spine", Vector3.FORWARD, sin(idle_clock * 0.85) * 0.018)
	_apply_idle_bone("head", Vector3.UP, sin(idle_clock * 0.55) * 0.025)
	_apply_idle_bone("left_arm", Vector3.FORWARD, sin(idle_clock * 0.72) * 0.014)
	_apply_idle_bone("right_arm", Vector3.FORWARD, -sin(idle_clock * 0.72) * 0.014)

func _apply_idle_bone(key: String, axis: Vector3, angle: float):
	if not idle_indices.has(key) or not idle_base.has(key):
		return
	var index = int(idle_indices[key])
	var base_rotation = idle_base[key]
	idle_skeleton.set_bone_pose_rotation(index, base_rotation * Quaternion(axis, angle))
