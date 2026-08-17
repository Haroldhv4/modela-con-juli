extends RefCounted
class_name ModularAvatarRuntime

# Divide las superficies del mesh combinado del avatar ligero en piezas skinned
# independientes, todas ligadas al mismo Skeleton3D/Skin. De este modo podremos
# sustituir únicamente la ropa sin volver a cargar otro personaje completo.

const SOURCE_MESH_NAME = "Body_AnimeSchoolGirl"
const PART_NAMES = {
	"skin": "Body",
	"eyes": "Eyes",
	"hair": "Hair",
	"outfit": "OriginalOutfit"
}

static func prepare(character: Node) -> Dictionary:
	var result = {}
	if character == null:
		return result

	# Si ya fue preparado, no duplicamos meshes.
	for part_name_variant in PART_NAMES.values():
		var existing = _find_node_recursive(character, str(part_name_variant))
		if existing is MeshInstance3D:
			result[str(part_name_variant)] = existing
	if result.size() == PART_NAMES.size():
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

	for surface_index in range(array_mesh.get_surface_count()):
		var surface_name = str(array_mesh.surface_get_name(surface_index))
		var normalized = surface_name.to_lower()
		var node_name = str(PART_NAMES.get(normalized, surface_name))

		# surface_get_arrays conserva vértices, normales, UV, ARRAY_BONES y
		# ARRAY_WEIGHTS. No copiamos blend-shapes aquí porque no son necesarios para
		# separar estas cuatro superficies y podían invalidar el nuevo ArrayMesh.
		var arrays = array_mesh.surface_get_arrays(surface_index)
		if arrays.is_empty():
			push_warning("ModelaConJuli: superficie vacía: " + surface_name)
			continue

		var part_mesh = ArrayMesh.new()
		part_mesh.resource_name = node_name + "Mesh"
		var primitive = array_mesh.surface_get_primitive_type(surface_index)
		part_mesh.add_surface_from_arrays(primitive, arrays)
		part_mesh.surface_set_name(0, surface_name)

		var material = source.get_active_material(surface_index)
		if material == null:
			material = array_mesh.surface_get_material(surface_index)
		if material:
			part_mesh.surface_set_material(0, material)

		var part = MeshInstance3D.new()
		part.name = node_name
		part.mesh = part_mesh
		part.skin = source.skin
		part.skeleton = source.skeleton
		part.transform = source.transform
		parent.add_child(part)
		result[node_name] = part

	if result.size() == PART_NAMES.size():
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
