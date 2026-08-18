extends SceneTree

const CHARACTER_PATH = "res://assets/characters/juli/anime_school_girl_rigged.glb"
const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")

func _init():
	var resource = load(CHARACTER_PATH)
	if not (resource is PackedScene):
		push_error("MODULAR TEST: personaje no cargado")
		quit(1)
		return

	var character = resource.instantiate()
	get_root().add_child(character)
	var parts = ModularAvatarRuntime.prepare(character)

	for key in ["Body", "OriginalOutfit", "Glasses"]:
		if not parts.has(key) or not (parts[key] is MeshInstance3D):
			push_error("MODULAR TEST: falta MeshInstance3D " + key)
			quit(1)
			return
	if not parts.has("Skeleton") or not (parts["Skeleton"] is Skeleton3D):
		push_error("MODULAR TEST: falta Skeleton3D")
		quit(1)
		return

	var body = parts["Body"] as MeshInstance3D
	var outfit = parts["OriginalOutfit"] as MeshInstance3D
	if body.mesh == null or body.mesh.get_surface_count() != 3:
		push_error("MODULAR TEST: Body debe conservar 3 superficies")
		quit(1)
		return
	if outfit.mesh == null or outfit.mesh.get_surface_count() != 1:
		push_error("MODULAR TEST: Outfit debe conservar 1 superficie")
		quit(1)
		return

	for material_name in ["Skin", "Eyes", "Hair"]:
		var surface_index = ModularAvatarRuntime.get_surface_index_by_material(body, material_name)
		if surface_index < 0:
			push_error("MODULAR TEST: Body no contiene superficie/material " + material_name)
			quit(1)
			return
		if not _surface_has_weights(body, surface_index):
			push_error("MODULAR TEST: " + material_name + " no conserva pesos de huesos")
			quit(1)
			return

	var outfit_index = ModularAvatarRuntime.get_surface_index_by_material(outfit, "Outfit")
	if outfit_index < 0 or not _surface_has_weights(outfit, outfit_index):
		push_error("MODULAR TEST: Outfit no conserva superficie/pesos")
		quit(1)
		return

	if body.skeleton.is_empty() or outfit.skeleton.is_empty():
		push_error("MODULAR TEST: meshes no apuntan al Skeleton3D")
		quit(1)
		return

	print("MODULAR TEST OK | parts=", parts.keys(), " | body_surfaces=3 | weighted=true")
	character.queue_free()
	quit(0)

func _surface_has_weights(mesh_instance: MeshInstance3D, surface_index: int) -> bool:
	if not (mesh_instance.mesh is ArrayMesh):
		return false
	var arrays = (mesh_instance.mesh as ArrayMesh).surface_get_arrays(surface_index)
	if arrays.size() <= Mesh.ARRAY_WEIGHTS:
		return false
	var bones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	return bones != null and weights != null and bones.size() > 0 and weights.size() > 0
