extends SceneTree

const CHARACTER_PATH = "res://assets/characters/juli/anime_school_girl_rigged.glb"

func _init():
	print("=== MODELA CON JULI · CHARACTER AUDIT V2 ===")
	var resource = load(CHARACTER_PATH)
	if not (resource is PackedScene):
		push_error("AUDIT: no se pudo cargar PackedScene: " + CHARACTER_PATH)
		quit(1)
		return

	var character = resource.instantiate()
	if character == null:
		push_error("AUDIT: no se pudo instanciar personaje")
		quit(1)
		return

	get_root().add_child(character)
	_print_node(character, 0, character)
	print("=== END CHARACTER AUDIT V2 ===")
	character.queue_free()
	quit(0)

func _print_node(node: Node, depth: int, root: Node):
	var indent = "  ".repeat(depth)
	var rel_path = str(root.get_path_to(node))
	print(indent + "GLBINFO NODE | path=" + rel_path + " | name=" + str(node.name) + " | class=" + node.get_class())

	if node is MeshInstance3D:
		_print_mesh(node as MeshInstance3D, indent)

	if node is Skeleton3D:
		var skeleton = node as Skeleton3D
		print(indent + "  GLBINFO SKELETON | bones=" + str(skeleton.get_bone_count()))
		var names = PackedStringArray()
		for i in range(skeleton.get_bone_count()):
			names.append(str(skeleton.get_bone_name(i)))
		print(indent + "  GLBINFO BONES | " + ", ".join(names))

	if node is AnimationPlayer:
		var player = node as AnimationPlayer
		var animations = player.get_animation_list()
		print(indent + "  GLBINFO ANIMATIONS | " + ", ".join(animations))

	for child in node.get_children():
		_print_node(child, depth + 1, root)

func _print_mesh(mesh_instance: MeshInstance3D, indent: String):
	var skin_text = "null"
	if mesh_instance.skin != null:
		skin_text = str(mesh_instance.skin.resource_name)
		if skin_text == "":
			skin_text = "Skin(resource)"

	print(indent + "  GLBINFO MESHINSTANCE | skeleton_path=" + str(mesh_instance.skeleton) + " | skin=" + skin_text + " | visible=" + str(mesh_instance.visible))
	if mesh_instance.mesh == null:
		print(indent + "  GLBINFO MESH | null")
		return

	var mesh = mesh_instance.mesh
	print(indent + "  GLBINFO MESH | class=" + mesh.get_class() + " | resource_name=" + str(mesh.resource_name) + " | surfaces=" + str(mesh.get_surface_count()) + " | aabb=" + str(mesh.get_aabb()))

	for surface in range(mesh.get_surface_count()):
		var surface_name = str(mesh.surface_get_name(surface))
		var material = mesh_instance.get_active_material(surface)
		if material == null:
			material = mesh.surface_get_material(surface)
		var material_name = "null"
		var material_class = "null"
		if material != null:
			material_name = str(material.resource_name)
			material_class = material.get_class()

		var arrays_info = "n/a"
		if mesh is ArrayMesh:
			var arrays = (mesh as ArrayMesh).surface_get_arrays(surface)
			if arrays.size() > Mesh.ARRAY_WEIGHTS:
				var vertices = arrays[Mesh.ARRAY_VERTEX]
				var bones = arrays[Mesh.ARRAY_BONES]
				var weights = arrays[Mesh.ARRAY_WEIGHTS]
				var vertex_count = vertices.size() if vertices != null else 0
				var bone_value_count = bones.size() if bones != null else 0
				var weight_value_count = weights.size() if weights != null else 0
				arrays_info = "vertices=" + str(vertex_count) + ",bone_values=" + str(bone_value_count) + ",weight_values=" + str(weight_value_count)

		print(indent + "    GLBINFO SURFACE | index=" + str(surface) + " | name=" + surface_name + " | material=" + material_name + " | material_class=" + material_class + " | " + arrays_info)
