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
	var required = ["Body", "Eyes", "Hair", "OriginalOutfit"]
	for part_name in required:
		if not parts.has(part_name):
			push_error("MODULAR TEST: falta pieza " + part_name)
			quit(1)
			return
		var part = parts[part_name]
		if not (part is MeshInstance3D):
			push_error("MODULAR TEST: pieza no es MeshInstance3D: " + part_name)
			quit(1)
			return
		if part.mesh == null or part.mesh.get_surface_count() != 1:
			push_error("MODULAR TEST: mesh inválido: " + part_name)
			quit(1)
			return

	var source = _find(character, "Body_AnimeSchoolGirl")
	if source == null or source.visible:
		push_error("MODULAR TEST: el mesh combinado no quedó oculto")
		quit(1)
		return

	print("MODULAR TEST OK | parts=", parts.keys())
	character.queue_free()
	quit(0)

func _find(node: Node, target: String):
	if str(node.name) == target:
		return node
	for child in node.get_children():
		var found = _find(child, target)
		if found:
			return found
	return null
