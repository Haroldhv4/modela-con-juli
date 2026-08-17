extends RefCounted
class_name ModularAvatarRuntime

# Convierte el mesh combinado del avatar anime en piezas skinned independientes
# sin tocar el Skeleton3D. Esto nos permite ocultar el Outfit original y añadir
# prendas nuevas al MISMO esqueleto en lugar de reemplazar todo el personaje.

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

	# Si ya fue modularizado, reutilizamos las piezas existentes.
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

	# Las superficies importadas conservan ARRAY_BONES + ARRAY_WEIGHTS. Al copiar
	# esos arrays y reutilizar Skin/Skeleton, cada nueva pieza sigue animándose con
	# exactamente el mismo rig.
	for surface_index in range(array_mesh.get_surface_count()):
		var surface_name = array_mesh.surface_get_name(surface_index)
		var normalized = str(surface_name).to_lower()
		var node_name = str(PART_NAMES.get(normalized, surface_name))

		var part_mesh = ArrayMesh.new()
		part_mesh.resource_name = node_name + "Mesh"

		for blend_index in range(array_mesh.get_blend_shape_count()):
			part_mesh.add_blend_shape(array_mesh.get_blend_shape_name(blend_index))
		part_mesh.blend_shape_mode = array_mesh.blend_shape_mode

		var arrays = array_mesh.surface_get_arrays(surface_index)
		var blend_arrays = array_mesh.surface_get_blend_shape_arrays(surface_index)
		var primitive = array_mesh.surface_get_primitive_type(surface_index)
		part_mesh.add_surface_from_arrays(primitive, arrays, blend_arrays)
		part_mesh.surface_set_name(0, str(surface_name))

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
		part.cast_shadow = source.cast_shadow
		part.visibility_range_begin = source.visibility_range_begin
		part.visibility_range_end = source.visibility_range_end
		parent.add_child(part)
		result[node_name] = part

	# El combinado deja de renderizar; no lo destruimos para mantener una ruta de
	# recuperación y evitar modificar el recurso GLB importado.
	source.visible = false
	source.set_meta("modela_con_juli_modular_source", true)
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
