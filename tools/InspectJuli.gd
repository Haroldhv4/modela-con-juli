extends SceneTree

const JULI_PATH := "res://assets/characters/juli/anime_school_girl_rigged.glb"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== INSPECT JULI START ===")
	if not ResourceLoader.exists(JULI_PATH):
		push_error("No existe: " + JULI_PATH)
		quit(2)
		return

	var packed := load(JULI_PATH) as PackedScene
	if packed == null:
		push_error("No se pudo cargar PackedScene de Juli")
		quit(3)
		return

	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	_walk(root, "")
	print("=== INSPECT JULI END ===")
	root.queue_free()
	quit()

func _walk(node: Node, indent: String) -> void:
	print(indent + node.name + " <" + node.get_class() + ">")

	if node is MeshInstance3D:
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh != null:
			print(indent + "  mesh=" + str(mesh_node.mesh.resource_name) + " surfaces=" + str(mesh_node.mesh.get_surface_count()))
			for surface in range(mesh_node.mesh.get_surface_count()):
				var material := mesh_node.get_active_material(surface)
				var material_name := "<null>"
				if material != null:
					material_name = str(material.resource_name)
				print(indent + "  surface[" + str(surface) + "] material=" + material_name)

	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		print(indent + "  bones=" + str(skeleton.get_bone_count()))
		for bone_index in range(skeleton.get_bone_count()):
			print(indent + "  bone[" + str(bone_index) + "]=" + str(skeleton.get_bone_name(bone_index)))

	if node is AnimationPlayer:
		var animation_player := node as AnimationPlayer
		print(indent + "  animations=" + str(animation_player.get_animation_list()))

	for child in node.get_children():
		_walk(child, indent + "  ")
