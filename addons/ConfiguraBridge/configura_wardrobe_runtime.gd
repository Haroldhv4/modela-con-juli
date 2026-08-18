## Lightweight runtime bridge for Modela con Juli.
## Architecture inspired by Configura's runtime mesh-swap approach (MIT).
## See third_party/Configura/LICENSE.txt and docs/OPEN_SOURCE_BASE_DECISION.md.
extends RefCounted
class_name ConfiguraWardrobeRuntime

var _host: Node3D
var _current_character: Node3D
var _variants: Dictionary = {}
var _current_variant_id: String = ""
var _base_transform: Transform3D = Transform3D.IDENTITY


func _init(host: Node3D, initial_character: Node3D = null) -> void:
	_host = host
	_current_character = initial_character
	if is_instance_valid(_current_character):
		_base_transform = _current_character.transform


func register_variant(variant_id: String, scene_path: String) -> void:
	if variant_id.is_empty() or scene_path.is_empty():
		return
	_variants[variant_id] = scene_path


func has_variant(variant_id: String) -> bool:
	return _variants.has(variant_id) and ResourceLoader.exists(str(_variants[variant_id]))


func get_current_character() -> Node3D:
	return _current_character


func get_current_variant_id() -> String:
	return _current_variant_id


## MVP fallback: swaps a complete rigged 3D look.
## Only one character variant remains in the scene tree at a time, which keeps
## draw/animation work bounded on Windows and Android.
func equip_variant(variant_id: String) -> Node3D:
	if _host == null or not is_instance_valid(_host):
		push_error("[WardrobeRuntime] Character host is not available.")
		return null

	if not _variants.has(variant_id):
		push_warning("[WardrobeRuntime] Unknown variant: %s" % variant_id)
		return _current_character

	var scene_path := str(_variants[variant_id])
	if not ResourceLoader.exists(scene_path):
		push_warning("[WardrobeRuntime] Missing scene: %s" % scene_path)
		return _current_character

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_warning("[WardrobeRuntime] Could not load PackedScene: %s" % scene_path)
		return _current_character

	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		push_warning("[WardrobeRuntime] Variant root must inherit Node3D: %s" % scene_path)
		return _current_character

	var new_character := instance as Node3D
	new_character.name = "WardrobeCharacter"
	new_character.transform = _base_transform
	_host.add_child(new_character)

	var old_character := _current_character
	_current_character = new_character
	_current_variant_id = variant_id

	if is_instance_valid(old_character) and old_character != new_character:
		old_character.queue_free()

	return new_character


## Future modular path for clothes exported as independent skinned MeshInstance3D
## scenes that share Juli's skeleton. This mirrors Configura's intended workflow:
## one active mesh per logical slot instead of replacing the full character.
func equip_modular_mesh(slot: String, packed_scene_path: String, skeleton: Skeleton3D, active_slots: Dictionary) -> MeshInstance3D:
	if skeleton == null or slot.is_empty():
		return null

	if active_slots.has(slot):
		var previous = active_slots[slot]
		if is_instance_valid(previous):
			previous.queue_free()
		active_slots.erase(slot)

	if packed_scene_path.is_empty():
		return null
	if not ResourceLoader.exists(packed_scene_path):
		push_warning("[WardrobeRuntime] Missing modular garment: %s" % packed_scene_path)
		return null

	var packed := load(packed_scene_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	if not instance is MeshInstance3D:
		instance.queue_free()
		push_warning("[WardrobeRuntime] Modular garment must be a MeshInstance3D scene.")
		return null

	var mesh := instance as MeshInstance3D
	skeleton.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	active_slots[slot] = mesh
	return mesh
