extends Node

const OutfitRuntime = preload("res://scripts/OutfitRuntime.gd")
const CLOTHING_CATEGORIES = ["tops", "bottoms", "shoes"]

var lobby = null
var world = null
var active_variant = OutfitRuntime.DEFAULT_VARIANT
var last_equipped = {}
var initialized = false
var touch_dragging = false

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

func _process(_delta):
	if not initialized or lobby == null:
		return

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
		if next_variant != "" and next_variant != active_variant:
			_switch_character(next_variant, true)

	last_equipped = current.duplicate(true)

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

	# LobbyUI_v11 ya contiene giro, zoom e idle. Le entregamos el nuevo modelo para
	# que esas funciones sigan trabajando sin duplicar lógica.
	lobby.set("character_node", next_character)
	lobby.set("character_base_y", -0.15)
	lobby.set("character_yaw", current_yaw)

	active_variant = variant
	OutfitRuntime.save_variant(active_variant)

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
