extends RefCounted
class_name OutfitRuntime

# Utilidades compartidas por Lobby y Pasarela para cargar el personaje Chiyo.
# El pack actual contiene outfits completos (no prendas independientes), por eso
# el sistema cambia entre GLB completos. Para evitar congelamientos, el Lobby usa
# carga asíncrona y mantiene visible el outfit actual hasta que el siguiente esté listo.

const VARIANT_SAVE_PATH = "user://modela_con_juli_variant.json"
const DEFAULT_VARIANT = "normal"

const CHARACTER_PATHS = {
	"base": "res://assets/characters/chiyo/Chiyo Base.glb",
	"normal": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"school": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"yukata": "res://assets/characters/chiyo/Chiyo Yukata.glb"
}

# Registro mínimo de solicitudes. No retenemos todos los PackedScene en una caché
# propia para no multiplicar el uso de memoria en Android; Godot conserva su caché
# interna mientras los recursos sigan referenciados por la escena activa.
static var _thread_requests = {}

static func is_valid_variant(variant: String) -> bool:
	return CHARACTER_PATHS.has(variant)

static func character_path(variant: String) -> String:
	var resolved = variant
	if not CHARACTER_PATHS.has(resolved):
		resolved = DEFAULT_VARIANT
	return str(CHARACTER_PATHS[resolved])

static func request_variant(variant: String) -> int:
	var resolved = variant if is_valid_variant(variant) else DEFAULT_VARIANT
	if _thread_requests.has(resolved):
		return OK

	var path = character_path(resolved)
	if not ResourceLoader.exists(path):
		push_error("ModelaConJuli: no existe el personaje: " + path)
		return ERR_FILE_NOT_FOUND

	var error = ResourceLoader.load_threaded_request(path, "PackedScene", true)
	if error == OK:
		_thread_requests[resolved] = true
	return error

static func variant_load_status(variant: String) -> int:
	var resolved = variant if is_valid_variant(variant) else DEFAULT_VARIANT
	if not _thread_requests.has(resolved):
		return ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
	return ResourceLoader.load_threaded_get_status(character_path(resolved))

static func instantiate_requested_variant(variant: String) -> Node3D:
	var resolved = variant if is_valid_variant(variant) else DEFAULT_VARIANT
	if not _thread_requests.has(resolved):
		return null

	var path = character_path(resolved)
	var status = ResourceLoader.load_threaded_get_status(path)
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		return null

	var resource = ResourceLoader.load_threaded_get(path)
	_thread_requests.erase(resolved)
	return _instantiate_packed_scene(resource, path)

static func cancel_request_marker(variant: String) -> void:
	# ResourceLoader no cancela una carga en curso. Solo olvidamos el marcador para
	# que una selección posterior pueda gestionar su propia petición sin bloquear UI.
	var resolved = variant if is_valid_variant(variant) else DEFAULT_VARIANT
	_thread_requests.erase(resolved)

static func instantiate_variant(variant: String) -> Node3D:
	# Ruta síncrona de respaldo. En el lobby no se usa durante un cambio de ropa;
	# sirve para escenas donde el recurso normalmente ya está en caché, como Pasarela.
	var path = character_path(variant)
	if not ResourceLoader.exists(path):
		push_error("ModelaConJuli: no existe el personaje: " + path)
		return null

	var resource = load(path)
	return _instantiate_packed_scene(resource, path)

static func _instantiate_packed_scene(resource, path: String) -> Node3D:
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
