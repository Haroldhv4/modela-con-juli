extends RefCounted
class_name JuliWardrobeRuntime

# Runtime seguro: una sola Juli, cero modificaciones manuales de huesos.
# Las prendas 3D modulares se descubren por convencion:
# res://assets/wardrobe3d/<categoria>/<item_id>.glb o .tscn

const SLOT_FOLDERS := {
	"hair": "hair",
	"tops": "tops",
	"bottoms": "bottoms",
	"shoes": "shoes",
	"accessories": "accessories",
	"makeup": "makeup"
}

const STYLE_COLORS := {
	"hair": [Color("#17141B"), Color("#2A2022"), Color("#6A4135"), Color("#B76478"), Color("#C69B55"), Color("#B9BEC9")],
	"tops": [Color("#F3F0EA"), Color("#171821"), Color("#D76E9D"), Color("#202027"), Color("#F5F3EF"), Color("#E67AAA"), Color("#C9B8A7"), Color("#743848"), Color("#22242C")],
	"bottoms": [Color("#1A1B22"), Color("#31506F"), Color("#76757B"), Color("#EFEDE8"), Color("#C85584"), Color("#B48A3E")],
	"shoes": [Color("#F1EFEA"), Color("#15161B"), Color("#B84E73"), Color("#242329"), Color("#B98A36"), Color("#AEB4C0")],
	"accessories": [Color("#2A2530"), Color("#111217"), Color("#B45D79"), Color("#C39B4B"), Color("#AAB0BB"), Color("#7A4F8A")],
	"makeup": [Color("#D99A9F"), Color("#E28AA7"), Color("#BE667E"), Color("#8D465B"), Color("#C88A62"), Color("#B85B7E")]
}

var _host: Node3D
var _character: Node3D
var _skeleton: Skeleton3D = null
var _animation_player: AnimationPlayer = null
var _surface_entries: Array = []
var _active_slots: Dictionary = {}
var _prepared: bool = false
var _base_scale: Vector3 = Vector3.ONE

func _init(host: Node3D, character: Node3D) -> void:
	_host = host
	_character = character
	if is_instance_valid(_character):
		_base_scale = _character.scale

func prepare_character() -> bool:
	if not is_instance_valid(_character):
		push_error("[WardrobeV2] Juli no esta disponible")
		return false
	_skeleton = _find_skeleton(_character)
	_animation_player = _find_animation_player(_character)
	_surface_entries = _collect_surfaces(_character)
	_prepared = true
	# Nunca rotamos brazos/manos por heuristica. Solo usamos animaciones reales.
	_try_play(["idle", "stand", "breath", "breathing"])
	_print_diagnostics()
	return true

func update_idle(_delta: float) -> void:
	# El Lobby V11 ya aplica un movimiento sutil al nodo raiz.
	# No modificamos huesos para evitar deformaciones de manos/brazos.
	pass

func restore_idle() -> void:
	if not _prepared:
		prepare_character()
	_try_play(["idle", "stand", "breath", "breathing"])

func play_animation(keywords: Array) -> bool:
	if not _prepared:
		prepare_character()
	return _try_play(keywords)

func apply_outfit(equipped: Dictionary) -> int:
	if not _prepared and not prepare_character():
		return 0
	var changed: int = 0
	for category_variant in ["hair", "tops", "bottoms", "shoes", "accessories", "makeup"]:
		var category: String = str(category_variant)
		var item_id: String = str(equipped.get(category, ""))
		if item_id.is_empty():
			continue
		if equip_item_3d(category, item_id):
			changed += 1
		elif apply_style(category, item_id):
			changed += 1
	return changed

func equip_item_3d(category: String, item_id: String) -> bool:
	if not _prepared and not prepare_character():
		return false
	var scene_path: String = _find_modular_asset(category, item_id)
	if scene_path.is_empty():
		return false
	return _equip_scene(category, scene_path)

func _find_modular_asset(category: String, item_id: String) -> String:
	if not SLOT_FOLDERS.has(category):
		return ""
	var folder: String = str(SLOT_FOLDERS[category])
	var base: String = "res://assets/wardrobe3d/" + folder + "/" + item_id
	for extension_variant in [".tscn", ".glb", ".gltf"]:
		var candidate: String = base + str(extension_variant)
		if ResourceLoader.exists(candidate):
			return candidate
	return ""

func _equip_scene(slot: String, scene_path: String) -> bool:
	if _skeleton == null:
		push_warning("[WardrobeV2] No hay Skeleton3D para equipar " + scene_path)
		return false
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		return false
	var instance: Node = packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return false
	var garment: Node3D = instance as Node3D
	garment.name = "Wardrobe_" + slot
	_character.add_child(garment)

	var meshes: Array = []
	_collect_mesh_nodes(garment, meshes)
	if meshes.is_empty():
		garment.queue_free()
		return false

	for mesh_variant in meshes:
		var mesh_node: MeshInstance3D = mesh_variant as MeshInstance3D
		# Reutiliza el Skin/bind del asset, pero apunta al Skeleton3D persistente de Juli.
		mesh_node.skeleton = mesh_node.get_path_to(_skeleton)

	if _active_slots.has(slot):
		var old = _active_slots[slot]
		if is_instance_valid(old):
			old.queue_free()
	_active_slots[slot] = garment
	pulse_selection()
	print("[WardrobeV2] 3D equipado: ", slot, " -> ", scene_path, " | meshes=", meshes.size())
	return true

func apply_style(category: String, item_id: String) -> bool:
	if not _prepared and not prepare_character():
		return false
	if not STYLE_COLORS.has(category):
		return false
	var palette: Array = STYLE_COLORS[category]
	var index: int = clampi(_item_number(item_id) - 1, 0, palette.size() - 1)
	var tint: Color = palette[index]
	var applied: bool = false
	for entry_variant in _surface_entries:
		var entry: Dictionary = entry_variant
		if str(entry.get("category", "body")) != category:
			continue
		var mesh_node: MeshInstance3D = entry.get("mesh") as MeshInstance3D
		var surface: int = int(entry.get("surface", -1))
		var original: Material = entry.get("material") as Material
		if mesh_node == null or original == null or surface < 0:
			continue
		var styled: Material = original.duplicate(true) as Material
		if styled is BaseMaterial3D:
			var material3d: BaseMaterial3D = styled as BaseMaterial3D
			var base: Color = material3d.albedo_color
			var strength: float = 0.24 if category == "makeup" else 0.78
			material3d.albedo_color = Color(
				lerpf(base.r, tint.r, strength),
				lerpf(base.g, tint.g, strength),
				lerpf(base.b, tint.b, strength),
				base.a
			)
			mesh_node.set_surface_override_material(surface, material3d)
			applied = true
	if applied:
		pulse_selection()
	return applied

func pulse_selection() -> void:
	if not is_instance_valid(_character) or not is_instance_valid(_host):
		return
	_character.scale = _base_scale * 0.992
	var tween: Tween = _host.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_character, "scale", _base_scale, 0.14)

func _collect_surfaces(root: Node) -> Array:
	var meshes: Array = []
	_collect_mesh_nodes(root, meshes)
	var result: Array = []
	for mesh_variant in meshes:
		var mesh_node: MeshInstance3D = mesh_variant as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for surface in range(mesh_node.mesh.get_surface_count()):
			var material: Material = mesh_node.get_active_material(surface)
			if material == null:
				continue
			var label: String = (str(mesh_node.name) + " " + str(mesh_node.mesh.resource_name) + " " + str(material.resource_name)).to_lower()
			result.append({"mesh": mesh_node, "surface": surface, "material": material, "category": _classify(label), "label": label})
	return result

func _classify(label: String) -> String:
	if _has_any(label, ["hair", "cabello"]): return "hair"
	if _has_any(label, ["shirt", "blouse", "top", "jacket", "coat", "sweater", "uniform"]): return "tops"
	if _has_any(label, ["skirt", "pants", "trouser", "jeans", "shorts", "bottom"]): return "bottoms"
	if _has_any(label, ["shoe", "boot", "sneaker", "heel", "footwear", "sock"]): return "shoes"
	if _has_any(label, ["glass", "spectacle", "frame", "earring", "necklace", "accessor"]): return "accessories"
	if _has_any(label, ["makeup", "lip", "blush", "eyeliner", "eyeshadow"]): return "makeup"
	return "body"

func _collect_mesh_nodes(node: Node, output: Array) -> void:
	if node is MeshInstance3D:
		output.append(node)
	for child in node.get_children():
		_collect_mesh_nodes(child, output)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null

func _try_play(keywords: Array) -> bool:
	if _animation_player == null:
		return false
	for animation_name in _animation_player.get_animation_list():
		var lower: String = str(animation_name).to_lower()
		if lower == "reset" or lower.ends_with("/reset"):
			continue
		for keyword_variant in keywords:
			if lower.contains(str(keyword_variant).to_lower()):
				_animation_player.play(animation_name)
				return true
	return false

func _has_any(value: String, tokens: Array) -> bool:
	for token_variant in tokens:
		if value.contains(str(token_variant)):
			return true
	return false

func _item_number(item_id: String) -> int:
	var parts: PackedStringArray = item_id.split("_", false)
	if parts.is_empty():
		return 1
	var tail: String = str(parts[parts.size() - 1])
	return int(tail) if tail.is_valid_int() else 1

func _print_diagnostics() -> void:
	var counts: Dictionary = {"hair": 0, "tops": 0, "bottoms": 0, "shoes": 0, "accessories": 0, "makeup": 0, "body": 0}
	for entry_variant in _surface_entries:
		var entry: Dictionary = entry_variant
		var category: String = str(entry.get("category", "body"))
		counts[category] = int(counts.get(category, 0)) + 1
	print("[WardrobeV2] Juli segura. Superficies: ", counts)
	print("[WardrobeV2] Skeleton: ", _skeleton.name if _skeleton != null else "NO", " | animaciones: ", _animation_player.get_animation_list() if _animation_player != null else [])
