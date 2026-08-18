extends "res://scripts/LobbyUI_v11.gd"

# MODELA CON JULI - LOBBY V12
# Functional-first integration: the existing wardrobe UI now drives real 3D
# model variants through the Configura-inspired runtime bridge.

const WardrobeRuntime = preload("res://addons/ConfiguraBridge/configura_wardrobe_runtime.gd")

const LOOK_VARIANTS := {
	"top_1": "res://assets/characters/juli/anime_school_girl_rigged.glb",
	"top_2": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_3": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"top_4": "res://assets/characters/chiyo/Chiyo Yukata.glb",
	"top_5": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_6": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"top_7": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_8": "res://assets/characters/chiyo/Chiyo Yukata.glb",
	"top_9": "res://assets/characters/chiyo/Chiyo School Dress.glb"
}

var wardrobe_runtime = null


func _ready() -> void:
	super()
	# Wait one frame so the V11 viewport/character setup is fully ready.
	call_deferred("_sync_saved_3d_outfit")


func _ensure_wardrobe_runtime() -> bool:
	if wardrobe_runtime != null:
		return true

	var world := get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld") as Node3D
	if world == null:
		push_warning("[LobbyV12] CharacterWorld not found.")
		return false

	var initial := character_node as Node3D
	if initial == null:
		initial = world.get_node_or_null("Juli") as Node3D

	wardrobe_runtime = WardrobeRuntime.new(world, initial)
	for variant_id in LOOK_VARIANTS.keys():
		wardrobe_runtime.register_variant(str(variant_id), str(LOOK_VARIANTS[variant_id]))
	return true


func _sync_saved_3d_outfit() -> void:
	_apply_real_3d_outfit(str(equipped.get("tops", "top_1")), false)


func _equip_item(category, item) -> void:
	var item_id := str(item.get("id", ""))
	equipped[category] = item_id
	_refresh_items()

	if category == "tops":
		if _apply_real_3d_outfit(item_id, true):
			_show_toast("3D equipado: " + str(item.get("name", "")))
		else:
			_show_toast("Guardado: " + str(item.get("name", "")))
	else:
		# These slots are already persisted and flow into scoring/runway state.
		# They become visual 3D swaps as soon as their modular rigged assets are
		# exported for Juli; no UI/save-game rewrite will be necessary.
		_show_toast("Equipado: " + str(item.get("name", "")))


func _apply_real_3d_outfit(top_id: String, reset_view: bool) -> bool:
	if not LOOK_VARIANTS.has(top_id):
		return false
	if not _ensure_wardrobe_runtime():
		return false

	var next_character := wardrobe_runtime.equip_variant(top_id) as Node3D
	if next_character == null:
		return false

	character_node = next_character
	character_base_y = next_character.position.y
	character_yaw = 0.0
	idle_time = 0.0

	if reset_view:
		character_camera_z = 4.04
		_apply_character_zoom()
	return true
