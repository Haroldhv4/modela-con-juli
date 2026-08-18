extends SceneTree

const MODELS := {
	"JULI": "res://assets/characters/juli/anime_school_girl_rigged.glb",
	"CHIYO_BASE": "res://assets/characters/chiyo/Chiyo Base.glb",
	"CHIYO_NORMAL": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"CHIYO_SCHOOL": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"CHIYO_YUKATA": "res://assets/characters/chiyo/Chiyo Yukata.glb"
}

var lines: Array[String] = []
var bone_sets: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_add("MODELA CON JULI - GLB REPORT")
	for key_variant in MODELS.keys():
		await _inspect_model(str(key_variant), str(MODELS[key_variant]))
	_compare_skeletons()
	var file := FileAccess.open("res://inspect_report.txt", FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
	print("\n".join(lines))
	quit()

func _inspect_model(label: String, path: String) -> void:
	_add("\n=== " + label + " ===")
	_add("path=" + path)
	if not ResourceLoader.exists(path):
		_add("MISSING")
		return
	var packed := load(path) as PackedScene
	if packed == null:
		_add("LOAD_FAILED")
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame

	var meshes: Array = []
	var skeleton := _find_skeleton(root)
	var animation_player := _find_animation_player(root)
	_collect_meshes(root, meshes)
	_add("root=" + root.name + " class=" + root.get_class())
	_add("mesh_count=" + str(meshes.size()))
	for mesh_variant in meshes:
		var mesh_node := mesh_variant as MeshInstance3D
		var mesh_name := str(mesh_node.name)
		var resource_name := ""
		var surface_count := 0
		if mesh_node.mesh != null:
			resource_name = str(mesh_node.mesh.resource_name)
			surface_count = mesh_node.mesh.get_surface_count()
		_add("mesh=" + mesh_name + " resource=" + resource_name + " surfaces=" + str(surface_count))
		for surface in range(surface_count):
			var material := mesh_node.get_active_material(surface)
			_add("  material[" + str(surface) + "]=" + (str(material.resource_name) if material != null else "<null>"))

	var bones: Array[String] = []
	if skeleton != null:
		for index in range(skeleton.get_bone_count()):
			bones.append(str(skeleton.get_bone_name(index)))
		_add("skeleton=" + skeleton.name + " bone_count=" + str(bones.size()))
		_add("bones=" + ",".join(bones))
	else:
		_add("skeleton=NONE")
	bone_sets[label] = bones

	if animation_player != null:
		_add("animations=" + ",".join(Array(animation_player.get_animation_list())))
	else:
		_add("animations=NONE")
	root.queue_free()
	await process_frame

func _compare_skeletons() -> void:
	_add("\n=== SKELETON COMPATIBILITY ===")
	var juli_bones: Array = bone_sets.get("JULI", [])
	if juli_bones.is_empty():
		_add("JULI has no skeleton; modular skinned wardrobe cannot use this base as-is.")
		return
	for key_variant in ["CHIYO_BASE", "CHIYO_NORMAL", "CHIYO_SCHOOL", "CHIYO_YUKATA"]:
		var key := str(key_variant)
		var other: Array = bone_sets.get(key, [])
		var exact := juli_bones == other
		var common := 0
		for bone_variant in juli_bones:
			if other.has(bone_variant):
				common += 1
		var ratio := float(common) / float(maxi(1, juli_bones.size()))
		_add(key + " exact=" + str(exact) + " common=" + str(common) + "/" + str(juli_bones.size()) + " ratio=" + str(snappedf(ratio, 0.001)))

func _collect_meshes(node: Node, output: Array) -> void:
	if node is MeshInstance3D:
		output.append(node)
	for child in node.get_children():
		_collect_meshes(child, output)

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _add(text: String) -> void:
	lines.append(text)
