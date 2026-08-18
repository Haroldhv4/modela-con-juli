extends RefCounted
class_name ModularAvatarRuntime

# Separa el GLB ligero de Juli en partes skinned reutilizando exactamente el
# mismo Skeleton3D/Skin. Esto nos permite conservar un solo personaje y cambiar
# únicamente ropa/materiales en runtime.

const SOURCE_MESH_NAME = "Body_AnimeSchoolGirl"
const PART_NAMES = {
	"skin": "Body",
	"body": "Body",
	"eyes": "Eyes",
	"eye": "Eyes",
	"hair": "Hair",
	"outfit": "OriginalOutfit",
	"clothes": "OriginalOutfit",
	"clothing": "OriginalOutfit"
}
const REQUIRED_PARTS = ["Body", "Eyes", "Hair", "OriginalOutfit"]
const FALLBACK_BY_INDEX = ["Body", "Eyes", "Hair", "OriginalOutfit"]

static func prepare(character: Node) -> Dictionary:
	var result = {}
	if character == null:
		return result

	# Si ya fue preparado, no duplicamos meshes.
	for part_name in REQUIRED_PARTS:
		var existing = _find_node_recursive(character, part_name)
		if existing is MeshInstance3D:
			result[part_name] = existing
	if result.size() == REQUIRED_PARTS.size():
		return result

	var source = _find_node_recursive(character, SOURCE_MESH_NAME)
	if not (source is MeshInstance3D):
		push_error("ModelaConJuli: no se encontró " + SOURCE_MESH_NAME)
		return result

	var source_mesh = source.mesh
	if not (source_mesh is ArrayMesh):
		push_error("ModelaConJuli: el mesh base no es ArrayMesh")
		return result

	var array_mesh = source_mesh as ArrayMesh
	var parent = source.get_parent()
	if parent == null:
		return result

	# Limpiamos cualquier intento parcial anterior antes de reconstruir.
	for part_name in REQUIRED_PARTS:
		var old_part = _find_node_recursive(character, part_name)
		if old_part is MeshInstance3D and old_part != source:
			old_part.queue_free()
	result.clear()

	for surface_index in range(array_mesh.get_surface_count()):
		var surface_name = str(array_mesh.surface_get_name(surface_index))
		var material = source.get_active_material(surface_index)
		if material == null:
			material = array_mesh.surface_get_material(surface_index)
		var material_name = str(material.resource_name) if material else ""
		var node_name = _resolve_part_name(surface_name, material_name, surface_index, array_mesh.get_surface_count())
		if node_name == "" or result.has(node_name):
			continue

		# surface_get_arrays conserva vértices, normales, UV, ARRAY_BONES y
		# ARRAY_WEIGHTS. Como el Skin y Skeleton NodePath también se reutilizan,
		# la pieza continúa deformándose con el mismo rig.
		var arrays = array_mesh.surface_get_arrays(surface_index)
		if arrays.is_empty():
			push_warning("ModelaConJuli: superficie vacía: " + surface_name)
			continue

		var part_mesh = ArrayMesh.new()
		part_mesh.resource_name = node_name + "Mesh"
		var primitive = array_mesh.surface_get_primitive_type(surface_index)
		part_mesh.add_surface_from_arrays(primitive, arrays)
		part_mesh.surface_set_name(0, surface_name if surface_name != "" else node_name)
		if material:
			part_mesh.surface_set_material(0, material)

		var part = MeshInstance3D.new()
		part.name = node_name
		part.mesh = part_mesh
		part.skin = source.skin
		part.skeleton = source.skeleton
		part.transform = source.transform
		part.cast_shadow = source.cast_shadow
		part.layers = source.layers
		parent.add_child(part)
		result[node_name] = part

	if _has_required_parts(result):
		# Ocultamos el combinado solo cuando las cuatro piezas se construyeron bien.
		source.visible = false
		source.set_meta("modela_con_juli_modular_source", true)
	else:
		# Si algo falla conservamos el original visible para no dejar al personaje vacío.
		for value in result.values():
			if value is MeshInstance3D:
				value.queue_free()
		result.clear()
		push_error("ModelaConJuli: no se pudieron crear todas las piezas modulares")

	return result

static func _resolve_part_name(surface_name: String, material_name: String, index: int, surface_count: int) -> String:
	var candidates = [surface_name, material_name]
	for raw_name in candidates:
		var normalized = raw_name.to_lower().strip_edges()
		for token_variant in PART_NAMES.keys():
			var token = str(token_variant)
			if normalized == token or normalized.begins_with(token + ".") or normalized.find(token) != -1:
				return str(PART_NAMES[token_variant])

	# El GLB auditado tiene cuatro superficies en orden Skin/Eyes/Hair/Outfit.
	# Solo usamos este fallback cuando el modelo conserva exactamente esas cuatro.
	if surface_count == FALLBACK_BY_INDEX.size() and index >= 0 and index < FALLBACK_BY_INDEX.size():
		return str(FALLBACK_BY_INDEX[index])
	return ""

static func _has_required_parts(parts: Dictionary) -> bool:
	for part_name in REQUIRED_PARTS:
		if not parts.has(part_name):
			return false
	return true

static func set_original_outfit_visible(character: Node, visible: bool) -> void:
	var outfit = _find_node_recursive(character, "OriginalOutfit")
	if outfit is MeshInstance3D:
		outfit.visible = visible

static func get_part(character: Node, part_name: String):
	return _find_node_recursive(character, part_name)

static func _find_node_recursive(node: Node, target_name: String):
	if node == null:
		return null
	if str(node.name) == target_name:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, target_name)
		if found:
			return found
	return null
