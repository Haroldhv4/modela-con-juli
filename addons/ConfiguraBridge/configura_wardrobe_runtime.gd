## Runtime de vestuario para Modela con Juli.
## Mantiene UNA sola Juli en escena. Nunca sustituye al personaje completo.
## La arquitectura de slots/mallas esta inspirada por Configura (MIT).
## Ver third_party/Configura/LICENSE.txt.
extends RefCounted
class_name ConfiguraWardrobeRuntime

const STYLE_COLORS := {
	"hair": [
		Color("#17141B"), Color("#2A2022"), Color("#6A4135"),
		Color("#B76478"), Color("#C69B55"), Color("#B9BEC9")
	],
	"tops": [
		Color("#F3F0EA"), Color("#171821"), Color("#D76E9D"),
		Color("#202027"), Color("#F5F3EF"), Color("#E67AAA"),
		Color("#C9B8A7"), Color("#743848"), Color("#22242C")
	],
	"bottoms": [
		Color("#1A1B22"), Color("#31506F"), Color("#76757B"),
		Color("#EFEDE8"), Color("#C85584"), Color("#B48A3E")
	],
	"shoes": [
		Color("#F1EFEA"), Color("#15161B"), Color("#B84E73"),
		Color("#242329"), Color("#B98A36"), Color("#AEB4C0")
	],
	"accessories": [
		Color("#2A2530"), Color("#111217"), Color("#B45D79"),
		Color("#C39B4B"), Color("#AAB0BB"), Color("#7A4F8A")
	],
	"makeup": [
		Color("#D99A9F"), Color("#E28AA7"), Color("#BE667E"),
		Color("#8D465B"), Color("#C88A62"), Color("#B85B7E")
	]
}

var _host: Node3D = null
var _character: Node3D = null
var _skeleton: Skeleton3D = null
var _animation_player: AnimationPlayer = null
var _surface_entries: Array = []
var _base_bone_rotations: Dictionary = {}
var _idle_bones: Dictionary = {}
var _active_slots: Dictionary = {}
var _prepared := false
var _using_animation := false
var _idle_phase := 0.0
var _base_scale := Vector3.ONE
var _character_min_y := 0.0
var _character_max_y := 1.0


func _init(host: Node3D, initial_character: Node3D = null) -> void:
	_host = host
	set_character(initial_character)


func set_character(character: Node3D) -> void:
	_character = character
	_prepared = false
	_surface_entries.clear()
	_base_bone_rotations.clear()
	_idle_bones.clear()
	_active_slots.clear()
	_skeleton = null
	_animation_player = null
	_using_animation = false
	_idle_phase = 0.0
	if is_instance_valid(_character):
		_base_scale = _character.scale


func get_character() -> Node3D:
	return _character


func prepare_character() -> bool:
	if not is_instance_valid(_character):
		push_error("[WardrobeRuntime] Juli no esta disponible.")
		return false

	_skeleton = _find_first_skeleton(_character)
	_animation_player = _find_first_animation_player(_character)
	_surface_entries = _build_surface_registry()
	_using_animation = _try_play_animation(["idle", "stand", "breath", "breathing"])

	if not _using_animation and _skeleton != null:
		_apply_relaxed_pose()

	_prepared = true
	_print_diagnostics()
	return true


func apply_outfit(equipped: Dictionary) -> int:
	if not _prepared and not prepare_character():
		return 0

	var changed := 0
	for category in ["hair", "tops", "bottoms", "shoes", "accessories", "makeup"]:
		var item_id := str(equipped.get(category, ""))
		if not item_id.is_empty() and apply_style(category, item_id):
			changed += 1
	return changed


func apply_style(category: String, item_id: String) -> bool:
	if not _prepared and not prepare_character():
		return false
	if not STYLE_COLORS.has(category):
		return false

	var palette: Array = STYLE_COLORS[category]
	if palette.is_empty():
		return false
	var index := clampi(_item_number(item_id) - 1, 0, palette.size() - 1)
	var tint: Color = palette[index]
	var applied := false

	for entry_variant in _surface_entries:
		var entry: Dictionary = entry_variant
		if str(entry.get("category", "")) != category:
			continue
		var mesh_instance = entry.get("mesh")
		if not is_instance_valid(mesh_instance):
			continue
		var surface := int(entry.get("surface", -1))
		var original = entry.get("original")
		if surface < 0 or original == null:
			continue

		var styled = original.duplicate(true)
		if styled is BaseMaterial3D:
			var base_material := styled as BaseMaterial3D
			var base := base_material.albedo_color
			var strength := 0.78
			if category == "makeup":
				strength = 0.24
			base_material.albedo_color = Color(
				lerpf(base.r, tint.r, strength),
				lerpf(base.g, tint.g, strength),
				lerpf(base.b, tint.b, strength),
				base.a
			)
			mesh_instance.set_surface_override_material(surface, base_material)
			applied = true

	if applied:
		pulse_selection()
	return applied


func update_idle(delta: float) -> void:
	if not _prepared or _using_animation or _skeleton == null:
		return

	_idle_phase += delta
	var breath := sin(_idle_phase * 1.35)
	var sway := sin(_idle_phase * 0.72)

	var spine_idx := int(_idle_bones.get("spine", -1))
	if spine_idx >= 0 and _base_bone_rotations.has(spine_idx):
		var spine_base: Quaternion = _base_bone_rotations[spine_idx]
		var spine_delta := Quaternion(Vector3.FORWARD, deg_to_rad(sway * 0.55))
		_skeleton.set_bone_pose_rotation(spine_idx, spine_base * spine_delta)

	var neck_idx := int(_idle_bones.get("neck", -1))
	if neck_idx >= 0 and _base_bone_rotations.has(neck_idx):
		var neck_base: Quaternion = _base_bone_rotations[neck_idx]
		var neck_delta := Quaternion(Vector3.RIGHT, deg_to_rad(breath * 0.45))
		_skeleton.set_bone_pose_rotation(neck_idx, neck_base * neck_delta)


func play_animation(keywords: Array) -> bool:
	if not _prepared:
		prepare_character()
	_using_animation = _try_play_animation(keywords)
	return _using_animation


func restore_idle() -> void:
	if not _prepared:
		return
	_using_animation = _try_play_animation(["idle", "stand", "breath", "breathing"])
	if not _using_animation and _skeleton != null:
		_apply_relaxed_pose()


func pulse_selection() -> void:
	if not is_instance_valid(_character) or not is_instance_valid(_host):
		return
	_character.scale = _base_scale * 0.988
	var tween := _host.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_character, "scale", _base_scale * 1.008, 0.08)
	tween.tween_property(_character, "scale", _base_scale, 0.10)


## Ruta real para cuando las prendas de Juli esten exportadas como MeshInstance3D
## independientes y compartan exactamente el mismo Skeleton3D/bind pose.
func equip_modular_mesh(slot: String, packed_scene_path: String) -> MeshInstance3D:
	if not _prepared:
		prepare_character()
	if _skeleton == null or slot.is_empty():
		return null

	if _active_slots.has(slot):
		var previous = _active_slots[slot]
		if is_instance_valid(previous):
			previous.queue_free()
		_active_slots.erase(slot)

	if packed_scene_path.is_empty() or not ResourceLoader.exists(packed_scene_path):
		return null
	var packed := load(packed_scene_path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	if not instance is MeshInstance3D:
		instance.queue_free()
		push_warning("[WardrobeRuntime] La prenda modular debe tener raiz MeshInstance3D.")
		return null

	var mesh := instance as MeshInstance3D
	_skeleton.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(_skeleton)
	_active_slots[slot] = mesh
	return mesh


func _build_surface_registry() -> Array:
	var meshes: Array = []
	_collect_meshes(_character, meshes)
	if meshes.is_empty():
		return []

	var bounds_by_id: Dictionary = {}
	_character_min_y = INF
	_character_max_y = -INF
	for mesh_variant in meshes:
		var mesh_instance := mesh_variant as MeshInstance3D
		var bounds := _mesh_vertical_bounds(mesh_instance)
		bounds_by_id[mesh_instance.get_instance_id()] = bounds
		_character_min_y = minf(_character_min_y, bounds.x)
		_character_max_y = maxf(_character_max_y, bounds.y)

	if not is_finite(_character_min_y) or not is_finite(_character_max_y) or is_equal_approx(_character_min_y, _character_max_y):
		_character_min_y = 0.0
		_character_max_y = 1.0

	var registry: Array = []
	for mesh_variant in meshes:
		var mesh_instance := mesh_variant as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var bounds: Vector2 = bounds_by_id.get(mesh_instance.get_instance_id(), Vector2.ZERO)
		for surface in range(mesh_instance.mesh.get_surface_count()):
			var material := mesh_instance.get_active_material(surface)
			if material == null:
				continue
			var category := _classify_surface(mesh_instance, material, bounds)
			registry.append({
				"mesh": mesh_instance,
				"surface": surface,
				"original": material,
				"category": category,
				"label": _surface_label(mesh_instance, material)
			})
	return registry


func _classify_surface(mesh_instance: MeshInstance3D, material: Material, bounds: Vector2) -> String:
	var label := _surface_label(mesh_instance, material)

	if _contains_any(label, ["hair", "cabello", "hairstyle"]):
		return "hair"
	if _contains_any(label, ["shirt", "blouse", "top", "jacket", "coat", "sweater", "uppercloth", "upper_cloth", "torso_cloth", "uniform"]):
		return "tops"
	if _contains_any(label, ["skirt", "pants", "trouser", "jeans", "shorts", "bottom", "lowercloth", "lower_cloth"]):
		return "bottoms"
	if _contains_any(label, ["shoe", "boot", "sneaker", "heel", "footwear"]):
		return "shoes"
	if _contains_any(label, ["glass", "spectacle", "frame", "earring", "necklace", "accessor"]):
		return "accessories"
	if _contains_any(label, ["makeup", "lipstick", "blush", "eyeliner", "eyeshadow", "eye_shadow"]):
		return "makeup"

	# Nunca recoloreamos una malla identificada como piel/cara/cuerpo por heuristica.
	if _contains_any(label, ["skin", "body", "face", "head", "eye", "brow", "lash", "mouth", "teeth", "tongue", "hand", "arm", "leg"]):
		return "body"

	# Fallback geometrico seguro para GLB con nombres genericos. Una malla que ocupa
	# casi todo el cuerpo se considera cuerpo y no se toca.
	var total_height := maxf(0.001, _character_max_y - _character_min_y)
	var span := maxf(0.0, bounds.y - bounds.x)
	var span_ratio := span / total_height
	if span_ratio > 0.62:
		return "body"

	var center_y := (bounds.x + bounds.y) * 0.5
	var normalized := clampf((center_y - _character_min_y) / total_height, 0.0, 1.0)
	if normalized < 0.17:
		return "shoes"
	if normalized < 0.48:
		return "bottoms"
	if normalized < 0.79:
		return "tops"
	if span_ratio < 0.13:
		return "accessories"
	return "hair"


func _surface_label(mesh_instance: MeshInstance3D, material: Material) -> String:
	var label := str(mesh_instance.name)
	if mesh_instance.mesh != null:
		label += " " + str(mesh_instance.mesh.resource_name)
	label += " " + str(material.resource_name)
	return label.to_lower().replace(" ", "_").replace("-", "_")


func _mesh_vertical_bounds(mesh_instance: MeshInstance3D) -> Vector2:
	if mesh_instance == null or mesh_instance.mesh == null:
		return Vector2.ZERO
	var aabb := mesh_instance.mesh.get_aabb()
	var min_y := INF
	var max_y := -INF
	for x_value in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y_value in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z_value in [aabb.position.z, aabb.position.z + aabb.size.z]:
				var world_point := mesh_instance.global_transform * Vector3(float(x_value), float(y_value), float(z_value))
				var local_point := _character.to_local(world_point)
				min_y = minf(min_y, local_point.y)
				max_y = maxf(max_y, local_point.y)
	if not is_finite(min_y) or not is_finite(max_y):
		return Vector2.ZERO
	return Vector2(min_y, max_y)


func _collect_meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_meshes(child, result)


func _find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_first_skeleton(child)
		if found != null:
			return found
	return null


func _find_first_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_first_animation_player(child)
		if found != null:
			return found
	return null


func _try_play_animation(keywords: Array) -> bool:
	if _animation_player == null:
		return false
	var names := _animation_player.get_animation_list()
	for animation_name in names:
		var lower := str(animation_name).to_lower()
		if lower == "reset" or lower.ends_with("/reset"):
			continue
		for keyword_variant in keywords:
			if lower.contains(str(keyword_variant).to_lower()):
				_animation_player.play(animation_name)
				return true
	return false


func _apply_relaxed_pose() -> void:
	if _skeleton == null:
		return

	var left_arm := _find_upper_arm_bone("left")
	var right_arm := _find_upper_arm_bone("right")
	var spine := _find_named_bone(["spine", "chest"])
	var neck := _find_named_bone(["neck"])

	if left_arm >= 0:
		_remember_bone(left_arm)
		var left_base: Quaternion = _base_bone_rotations[left_arm]
		_skeleton.set_bone_pose_rotation(left_arm, left_base * Quaternion(Vector3.FORWARD, deg_to_rad(62.0)))
	if right_arm >= 0:
		_remember_bone(right_arm)
		var right_base: Quaternion = _base_bone_rotations[right_arm]
		_skeleton.set_bone_pose_rotation(right_arm, right_base * Quaternion(Vector3.FORWARD, deg_to_rad(-62.0)))
	if spine >= 0:
		_remember_bone(spine)
		_idle_bones["spine"] = spine
	if neck >= 0:
		_remember_bone(neck)
		_idle_bones["neck"] = neck


func _remember_bone(index: int) -> void:
	if index >= 0 and not _base_bone_rotations.has(index):
		_base_bone_rotations[index] = _skeleton.get_bone_pose_rotation(index)


func _find_upper_arm_bone(side: String) -> int:
	if _skeleton == null:
		return -1
	var best_index := -1
	var best_score := -999
	for index in range(_skeleton.get_bone_count()):
		var name := str(_skeleton.get_bone_name(index)).to_lower().replace(" ", "").replace("_", "").replace(":", "")
		var score := 0
		if name.contains("upperarm"):
			score += 12
		elif name.contains("arm"):
			score += 4
		else:
			continue
		if name.contains("forearm") or name.contains("lowerarm") or name.contains("hand"):
			score -= 20
		if side == "left":
			if name.contains("left") or name.ends_with("l"):
				score += 8
			if name.contains("right") or name.ends_with("r"):
				score -= 10
		else:
			if name.contains("right") or name.ends_with("r"):
				score += 8
			if name.contains("left") or name.ends_with("l"):
				score -= 10
		if score > best_score:
			best_score = score
			best_index = index
	return best_index if best_score > 4 else -1


func _find_named_bone(tokens: Array) -> int:
	if _skeleton == null:
		return -1
	for index in range(_skeleton.get_bone_count()):
		var name := str(_skeleton.get_bone_name(index)).to_lower()
		for token_variant in tokens:
			if name.contains(str(token_variant).to_lower()):
				return index
	return -1


func _contains_any(value: String, needles: Array) -> bool:
	for needle_variant in needles:
		if value.contains(str(needle_variant)):
			return true
	return false


func _item_number(item_id: String) -> int:
	var parts := item_id.split("_", false)
	if parts.size() == 0:
		return 1
	var tail := str(parts[parts.size() - 1])
	return int(tail) if tail.is_valid_int() else 1


func _print_diagnostics() -> void:
	var counts := {"hair": 0, "tops": 0, "bottoms": 0, "shoes": 0, "accessories": 0, "makeup": 0, "body": 0}
	for entry_variant in _surface_entries:
		var entry: Dictionary = entry_variant
		var category := str(entry.get("category", "body"))
		counts[category] = int(counts.get(category, 0)) + 1
	print("[WardrobeRuntime] Juli persistente. Superficies detectadas: ", counts)
	if _skeleton != null:
		print("[WardrobeRuntime] Skeleton3D: ", _skeleton.name, " | huesos: ", _skeleton.get_bone_count())
	else:
		print("[WardrobeRuntime] ADVERTENCIA: no se encontro Skeleton3D en Juli.")
