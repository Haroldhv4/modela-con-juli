extends RefCounted
class_name ModularAvatarRuntime

# Adaptador del GLB ligero de Juli.
# La auditoría real del archivo confirma esta estructura:
#   GeneralSkeleton (Skeleton3D)
#   ├── Body_AnimeSchoolGirl   -> superficies Skin / Eyes / Hair
#   ├── Outfit_AnimeSchoolGirl -> superficie Outfit
#   └── Glasses                -> superficie Glasses
# No duplicamos ni reconstruimos geometría: reutilizamos los MeshInstance3D
# importados y su Skeleton3D, preservando sus pesos de huesos originales.

const BODY_NODE_NAME = "Body_AnimeSchoolGirl"
const OUTFIT_NODE_NAME = "Outfit_AnimeSchoolGirl"
const GLASSES_NODE_NAME = "Glasses"

static func prepare(character: Node) -> Dictionary:
	var result = {}
	if character == null:
		return result

	var body = _find_node_recursive(character, BODY_NODE_NAME)
	var outfit = _find_node_recursive(character, OUTFIT_NODE_NAME)
	var glasses = _find_node_recursive(character, GLASSES_NODE_NAME)
	var skeleton = _find_first_skeleton(character)

	if body is MeshInstance3D:
		result["Body"] = body
	if outfit is MeshInstance3D:
		result["OriginalOutfit"] = outfit
	if glasses is MeshInstance3D:
		result["Glasses"] = glasses
	if skeleton is Skeleton3D:
		result["Skeleton"] = skeleton

	return result

static func get_part(character: Node, part_name: String):
	var parts = prepare(character)
	return parts.get(part_name)

static func get_surface_index_by_material(mesh_instance: MeshInstance3D, material_name: String) -> int:
	if mesh_instance == null or mesh_instance.mesh == null:
		return -1
	var target = material_name.to_lower().strip_edges()
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var material = mesh_instance.get_active_material(surface_index)
		if material == null:
			material = mesh_instance.mesh.surface_get_material(surface_index)
		if material == null:
			continue
		if str(material.resource_name).to_lower().strip_edges() == target:
			return surface_index
	return -1

static func has_bone_weights(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance == null or not (mesh_instance.mesh is ArrayMesh):
		return false
	var array_mesh = mesh_instance.mesh as ArrayMesh
	for surface_index in range(array_mesh.get_surface_count()):
		var arrays = array_mesh.surface_get_arrays(surface_index)
		if arrays.size() <= Mesh.ARRAY_WEIGHTS:
			continue
		var bones = arrays[Mesh.ARRAY_BONES]
		var weights = arrays[Mesh.ARRAY_WEIGHTS]
		if bones != null and weights != null and bones.size() > 0 and weights.size() > 0:
			return true
	return false

static func set_original_outfit_visible(character: Node, visible: bool) -> void:
	var outfit = get_part(character, "OriginalOutfit")
	if outfit is MeshInstance3D:
		outfit.visible = visible

static func _find_first_skeleton(node: Node):
	if node == null:
		return null
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var found = _find_first_skeleton(child)
		if found:
			return found
	return null

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
