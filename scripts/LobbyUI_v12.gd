extends "res://scripts/LobbyUI_v11.gd"

# MODELA CON JULI - LOBBY V12
# Una sola Juli persistente. La UI nunca reemplaza al personaje completo.

const WardrobeRuntime = preload("res://addons/ConfiguraBridge/wardrobe_runtime_v2.gd")
const GameSessionRuntime = preload("res://scripts/GameSession.gd")

var wardrobe_runtime = null
var _runtime_ready: bool = false

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
	_runtime_ready = bool(wardrobe_runtime.prepare_character())
	if not _runtime_ready:
		_show_toast("No se pudo preparar a Juli")
		return
	wardrobe_runtime.apply_outfit(equipped)

func _ensure_wardrobe_runtime() -> bool:
	if wardrobe_runtime != null:
		return true
	var world: Node3D = get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld") as Node3D
	if world == null:
		push_error("[LobbyV12] No se encontro CharacterWorld")
		return false
	var juli: Node3D = character_node as Node3D
	if juli == null:
		juli = world.get_node_or_null("Juli") as Node3D
	if juli == null:
		push_error("[LobbyV12] No se encontro la instancia persistente de Juli")
		return false
	character_node = juli
	wardrobe_runtime = WardrobeRuntime.new(world, juli)
	return true

func _equip_item(category, item) -> void:
	var slot: String = str(category)
	var item_id: String = str(item.get("id", ""))
	var item_name: String = str(item.get("name", ""))
	equipped[slot] = item_id
	_refresh_items()

	if not _ensure_wardrobe_runtime():
		_show_toast("Seleccion guardada: " + item_name)
		return
	if not _runtime_ready:
		_runtime_ready = bool(wardrobe_runtime.prepare_character())

	# Primero intenta una prenda 3D real por slot. Convencion:
	# assets/wardrobe3d/<slot>/<item_id>.glb o .tscn
	var equipped_3d: bool = bool(wardrobe_runtime.equip_item_3d(slot, item_id))
	if equipped_3d:
		_show_toast("3D equipado: " + item_name)
		return

	# Mientras un item aun no tenga malla 3D, nunca sustituimos a Juli ni tocamos huesos.
	# Solo aplicamos una variacion de material cuando el GLB base expone esa zona.
	var visual_change: bool = bool(wardrobe_runtime.apply_style(slot, item_id))
	if visual_change:
		_show_toast("Estilo aplicado: " + item_name)
	else:
		wardrobe_runtime.pulse_selection()
		_show_toast("Falta modelo 3D: " + item_name)

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
