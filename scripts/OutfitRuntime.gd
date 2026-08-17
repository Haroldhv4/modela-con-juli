extends RefCounted
class_name OutfitRuntime

# Utilidades compartidas por Lobby y Pasarela para cargar el personaje Chiyo.
# El pack actual contiene outfits completos (no prendas independientes), por eso
# el primer sistema funcional cambia entre GLB completos manteniendo el mismo flujo
# de armario que ya existe en la interfaz.

const VARIANT_SAVE_PATH = "user://modela_con_juli_variant.json"
const DEFAULT_VARIANT = "normal"

const CHARACTER_PATHS = {
	"base": "res://assets/characters/chiyo/Chiyo Base.glb",
	"normal": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"school": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"yukata": "res://assets/characters/chiyo/Chiyo Yukata.glb"
}

static func is_valid_variant(variant: String) -> bool:
	return CHARACTER_PATHS.has(variant)

static func character_path(variant: String) -> String:
	var resolved = variant
	if not CHARACTER_PATHS.has(resolved):
		resolved = DEFAULT_VARIANT
	return str(CHARACTER_PATHS[resolved])

static func instantiate_variant(variant: String) -> Node3D:
	var path = character_path(variant)
	if not ResourceLoader.exists(path):
		push_error("ModelaConJuli: no existe el personaje: " + path)
		return null

	var resource = load(path)
	if not (resource is PackedScene):
		push_error("ModelaConJuli: el recurso no es una escena importada: " + path)
		return null

	var instance = resource.instantiate()
	if instance is Node3D:
		return instance as Node3D

	if instance:
		instance.queue_free()
	push_error("ModelaConJuli: el GLB no produjo un Node3D: " + path)
	return null

static func variant_from_item(category: String, item_id: String) -> String:
	# Mientras los outfits sean modelos completos, las tarjetas de torso/pantalón/
	# calzado alternan entre los tres conjuntos vestidos del pack.
	if category != "tops" and category != "bottoms" and category != "shoes":
		return ""

	var parts = item_id.split("_", false)
	if parts.size() < 2:
		return DEFAULT_VARIANT

	var number = int(parts[parts.size() - 1])
	var cycle = number % 3
	if cycle == 1:
		return "normal"
	if cycle == 2:
		return "school"
	return "yukata"

static func variant_from_equipped(equipped: Dictionary) -> String:
	for category in ["tops", "bottoms", "shoes"]:
		var item_id = str(equipped.get(category, ""))
		if item_id != "":
			var variant = variant_from_item(category, item_id)
			if variant != "":
				return variant
	return DEFAULT_VARIANT

static func save_variant(variant: String) -> void:
	var resolved = variant
	if not is_valid_variant(resolved):
		resolved = DEFAULT_VARIANT

	var file = FileAccess.open(VARIANT_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"variant": resolved}))

static func load_variant() -> String:
	if not FileAccess.file_exists(VARIANT_SAVE_PATH):
		return ""

	var file = FileAccess.open(VARIANT_SAVE_PATH, FileAccess.READ)
	if not file:
		return ""

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var variant = str(parsed.get("variant", ""))
		if is_valid_variant(variant):
			return variant
	return ""

static func find_first_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found = find_first_skeleton(child)
		if found:
			return found
	return null
