extends "res://scripts/LobbyUI_v11.gd"

# MODELA CON JULI - LOBBY V12
# Una sola Juli persistente. La UI nunca reemplaza al personaje completo.

const WardrobeRuntime = preload("res://addons/ConfiguraBridge/configura_wardrobe_runtime.gd")
const GameSessionRuntime = preload("res://scripts/GameSession.gd")

var wardrobe_runtime = null
var _runtime_ready := false


func _ready() -> void:
	super()
	selected_mode = GameSessionRuntime.load_mode()
	_refresh_modes()
	call_deferred("_initialize_persistent_juli")


func _process(delta: float) -> void:
	super(delta)
	if wardrobe_runtime != null:
		wardrobe_runtime.update_idle(delta)


func _initialize_persistent_juli() -> void:
	if not _ensure_wardrobe_runtime():
		_show_toast("No se pudo preparar a Juli")
		return

	_runtime_ready = wardrobe_runtime.prepare_character()
	if not _runtime_ready:
		_show_toast("No se pudo preparar a Juli")
		return

	wardrobe_runtime.apply_outfit(equipped)


func _ensure_wardrobe_runtime() -> bool:
	if wardrobe_runtime != null:
		return true

	var world := get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld") as Node3D
	if world == null:
		push_error("[LobbyV12] No se encontro CharacterWorld.")
		return false

	var juli := character_node as Node3D
	if juli == null:
		juli = world.get_node_or_null("Juli") as Node3D
	if juli == null:
		push_error("[LobbyV12] No se encontro la instancia persistente de Juli.")
		return false

	# Esta referencia permanece durante toda la sesion del Lobby.
	character_node = juli
	wardrobe_runtime = WardrobeRuntime.new(world, juli)
	return true


func _equip_item(category, item) -> void:
	var item_id := str(item.get("id", ""))
	var item_name := str(item.get("name", ""))
	equipped[category] = item_id
	_refresh_items()

	if not _ensure_wardrobe_runtime():
		_show_toast("Seleccion guardada: " + item_name)
		return
	if not _runtime_ready:
		_runtime_ready = wardrobe_runtime.prepare_character()

	var visual_change := wardrobe_runtime.apply_style(str(category), item_id)
	if visual_change:
		_show_toast("Equipado: " + item_name)
	else:
		# Nunca sustituimos a Juli por otro GLB para fingir una prenda. Si el GLB
		# actual no expone esa zona/material, conservamos a Juli y el estado queda
		# listo para la futura malla modular real.
		wardrobe_runtime.pulse_selection()
		_show_toast("Seleccionado: " + item_name)


func _select_mode(mode) -> void:
	super(mode)
	GameSessionRuntime.save_mode(str(selected_mode))


func _start_runway() -> void:
	_save_outfit()
	GameSessionRuntime.save_mode(str(selected_mode))
	if ResourceLoader.exists("res://scenes/Runway.tscn"):
		get_tree().change_scene_to_file("res://scenes/Runway.tscn")
	else:
		_show_toast("Pasarela no disponible")
