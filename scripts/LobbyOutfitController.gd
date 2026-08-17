extends Node

const OutfitRuntime = preload("res://scripts/OutfitRuntime.gd")
const CLOTHING_CATEGORIES = ["tops", "bottoms", "shoes"]

var lobby = null
var world = null
var active_variant = OutfitRuntime.DEFAULT_VARIANT
var last_equipped = {}
var initialized = false
var touch_dragging = false

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

	_switch_character(active_variant, false)
	initialized = true
	set_process(true)
	set_process_input(true)

func _process(delta):
	if not initialized or lobby == null:
		return

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
			if next_variant != "" and next_variant != active_variant:
				_switch_character(next_variant, true)

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

func _switch_character(variant: String, animate: bool):
	if world == null:
		return

	var next_character = OutfitRuntime.instantiate_variant(variant)
	if next_character == null:
		return

	var current_yaw = 0.0
	var existing = world.get_node_or_null("Juli")
	if existing:
		current_yaw = existing.rotation_degrees.y
		world.remove_child(existing)
		existing.queue_free()
	else:
		var yaw_value = lobby.get("character_yaw")
		if yaw_value != null:
			current_yaw = float(yaw_value)

	next_character.name = "Juli"
	world.add_child(next_character)
	next_character.position = Vector3(0.0, -0.15, 0.0)
	next_character.rotation_degrees = Vector3(0.0, current_yaw, 0.0)
	next_character.scale = Vector3.ONE

	# LobbyUI_v11 ya contiene giro, zoom e idle del nodo raíz. Le entregamos el
	# modelo actual para conservar esos controles.
	lobby.set("character_node", next_character)
	lobby.set("character_base_y", -0.15)
	lobby.set("character_yaw", current_yaw)

	active_variant = variant
	OutfitRuntime.save_variant(active_variant)
	_prepare_idle_skeleton(next_character)

	if animate:
		next_character.scale = Vector3(0.94, 0.94, 0.94)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(next_character, "scale", Vector3.ONE, 0.24)

		var toast_method = Callable(lobby, "_show_toast")
		if toast_method.is_valid():
			var pretty = {
				"base": "Base",
				"normal": "Casual",
				"school": "Escolar",
				"yukata": "Yukata"
			}
			toast_method.call("Outfit 3D: " + str(pretty.get(active_variant, active_variant)))

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
