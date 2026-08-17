extends SceneTree

const CHARACTER_PATH = "res://assets/characters/juli/anime_school_girl_rigged.glb"

func _init():
	print("=== MODELA CON JULI · CHARACTER AUDIT ===")
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
	_print_node(character, 0)
	print("=== END CHARACTER AUDIT ===")
	character.queue_free()
	quit(0)

func _print_node(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print(indent + "NODE | " + str(node.name) + " | " + node.get_class())

	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh:
			print(indent + "  MESH surfaces=" + str(mesh_instance.mesh.get_surface_count()))
			for surface in range(mesh_instance.mesh.get_surface_count()):
				var surface_name = mesh_instance.mesh.surface_get_name(surface)
				var material = mesh_instance.get_active_material(surface)
				var material_name = ""
				if material:
					material_name = str(material.resource_name)
				print(indent + "    SURFACE " + str(surface) + " | name=" + str(surface_name) + " | material=" + material_name)

	if node is Skeleton3D:
		var skeleton = node as Skeleton3D
		print(indent + "  SKELETON bones=" + str(skeleton.get_bone_count()))
		var names = PackedStringArray()
		for i in range(skeleton.get_bone_count()):
			names.append(str(skeleton.get_bone_name(i)))
		print(indent + "  BONES | " + ", ".join(names))

	if node is AnimationPlayer:
		var player = node as AnimationPlayer
		var animations = player.get_animation_list()
		print(indent + "  ANIMATIONS | " + ", ".join(animations))

	for child in node.get_children():
		_print_node(child, depth + 1)
