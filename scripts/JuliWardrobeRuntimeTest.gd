extends SceneTree

const CHARACTER_PATH = "res://assets/characters/juli/anime_school_girl_rigged.glb"
const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")
const JuliWardrobeRuntime = preload("res://scripts/JuliWardrobeRuntime.gd")

func _init():
	var resource = load(CHARACTER_PATH)
	if not (resource is PackedScene):
		push_error("WARDROBE TEST: personaje no cargado")
		quit(1)
		return

	var character = resource.instantiate()
	get_root().add_child(character)
	var parts = ModularAvatarRuntime.prepare(character)
	if not parts.has("Body") or not parts.has("OriginalOutfit"):
		push_error("WARDROBE TEST: faltan Body/OriginalOutfit")
		quit(1)
		return

	var equipped = {
		"hair": "hair_4",
		"tops": "top_3",
		"bottoms": "skirt_4",
		"shoes": "shoes_2",
		"accessories": "glasses_3"
	}
	var report = JuliWardrobeRuntime.apply_equipped(character, equipped)
	for category in ["tops", "bottoms", "shoes", "hair", "accessories"]:
		if not report.has(category):
			push_error("WARDROBE TEST: categoría no aplicada: " + category)
			quit(1)
			return

	var outfit = parts["OriginalOutfit"] as MeshInstance3D
	var material = outfit.get_surface_override_material(0)
	if not (material is ShaderMaterial):
		push_error("WARDROBE TEST: outfit no recibió ShaderMaterial")
		quit(1)
		return
	if float(material.get_shader_parameter("top_mix")) <= 0.0:
		push_error("WARDROBE TEST: top no cambió visualmente")
		quit(1)
		return
	if float(material.get_shader_parameter("bottom_mix")) <= 0.0:
		push_error("WARDROBE TEST: bottom no cambió visualmente")
		quit(1)
		return
	if float(material.get_shader_parameter("shoes_mix")) <= 0.0:
		push_error("WARDROBE TEST: shoes no cambió visualmente")
		quit(1)
		return

	var body = parts["Body"] as MeshInstance3D
	var hair_index = ModularAvatarRuntime.get_surface_index_by_material(body, "Hair")
	if hair_index < 0:
		push_error("WARDROBE TEST: no se encontró superficie Hair")
		quit(1)
		return
	var hair_material = body.get_surface_override_material(hair_index)
	if not (hair_material is ShaderMaterial):
		push_error("WARDROBE TEST: Hair no recibió ShaderMaterial")
		quit(1)
		return
	if float(hair_material.get_shader_parameter("tint_mix")) <= 0.0:
		push_error("WARDROBE TEST: Hair no cambió visualmente")
		quit(1)
		return

	var glasses = parts.get("Glasses")
	if not (glasses is MeshInstance3D):
		push_error("WARDROBE TEST: no se encontró Glasses")
		quit(1)
		return
	if not (glasses.get_surface_override_material(0) is ShaderMaterial):
		push_error("WARDROBE TEST: Glasses no recibió ShaderMaterial")
		quit(1)
		return

	print("WARDROBE TEST OK | ", report)
	character.queue_free()
	quit(0)
