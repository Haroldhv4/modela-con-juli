extends RefCounted
class_name JuliWardrobeRuntime

# Guardarropa runtime para el GLB ligero de Juli.
#
# Etapa 1 (ya funcional): los items actuales del lobby cambian materiales por
# categoría y el mismo estado viaja a la pasarela.
# Etapa 2 (automática): cuando exista una prenda 3D en wardrobe/<categoria>/,
# se carga esa geometría y se conecta al Skeleton3D vivo de Juli, sin reemplazar
# el personaje completo.

const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")
const WARDROBE_ROOT = "res://assets/characters/juli/wardrobe"
const GEOMETRY_PREFIX = "WardrobeGeometry_"
const OUTFIT_SHADER_META = "modela_con_juli_outfit_shader"
const COLOR_SHADER_META = "modela_con_juli_color_shader"

const OUTFIT_SHADER_CODE = """
shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 top_tint : source_color = vec4(1.0);
uniform vec4 bottom_tint : source_color = vec4(1.0);
uniform vec4 shoes_tint : source_color = vec4(1.0);
uniform float top_mix = 0.0;
uniform float bottom_mix = 0.0;
uniform float shoes_mix = 0.0;
uniform float top_visible = 1.0;
uniform float bottom_visible = 1.0;
uniform float shoes_visible = 1.0;
uniform float y_min = 0.0;
uniform float y_max = 1.0;
uniform float shoes_cut = 0.22;
uniform float bottom_cut = 0.56;

varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	vec4 texel = texture(albedo_tex, UV) * base_color;
	if (texel.a < 0.08) {
		discard;
	}
	float h = clamp((local_y - y_min) / max(y_max - y_min, 0.0001), 0.0, 1.0);
	vec3 tint = top_tint.rgb;
	float amount = top_mix;
	float visible_region = top_visible;
	if (h < shoes_cut) {
		tint = shoes_tint.rgb;
		amount = shoes_mix;
		visible_region = shoes_visible;
	} else if (h < bottom_cut) {
		tint = bottom_tint.rgb;
		amount = bottom_mix;
		visible_region = bottom_visible;
	}
	if (visible_region < 0.5) {
		discard;
	}
	float shade = clamp(dot(texel.rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
	vec3 recolored = tint * (0.32 + shade * 0.78);
	ALBEDO = mix(texel.rgb, recolored, amount);
	ROUGHNESS = 0.78;
	METALLIC = 0.0;
}
"""

const COLOR_SHADER_CODE = """
shader_type spatial;
render_mode cull_back;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 tint : source_color = vec4(1.0);
uniform float tint_mix = 0.0;

void fragment() {
	vec4 texel = texture(albedo_tex, UV) * base_color;
	if (texel.a < 0.08) {
		discard;
	}
	float shade = clamp(dot(texel.rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
	vec3 recolored = tint.rgb * (0.28 + shade * 0.82);
	ALBEDO = mix(texel.rgb, recolored, tint_mix);
	ROUGHNESS = 0.78;
	METALLIC = 0.0;
}
"""

static func apply_equipped(character: Node, equipped: Dictionary) -> Dictionary:
	var report = {}
	if character == null:
		return report

	var parts = ModularAvatarRuntime.prepare(character)
	if not parts.has("Body") or not parts.has("OriginalOutfit") or not parts.has("Skeleton"):
		push_error("ModelaConJuli: avatar incompleto para aplicar guardarropa")
		return report

	var body = parts["Body"] as MeshInstance3D
	var outfit = parts["OriginalOutfit"] as MeshInstance3D
	var outfit_material = _ensure_outfit_shader(outfit)
	if outfit_material == null:
		push_error("ModelaConJuli: no se pudo preparar el shader del guardarropa")
		return report

	for category in ["tops", "bottoms", "shoes"]:
		var item_id = str(equipped.get(category, ""))
		var geometry_loaded = _equip_geometry_if_available(character, category, item_id)
		_set_region_visible(outfit_material, category, not geometry_loaded)
		_apply_prototype_tint(outfit_material, category, item_id)
		report[category] = "geometry" if geometry_loaded else "prototype"

	var hair_index = ModularAvatarRuntime.get_surface_index_by_material(body, "Hair")
	if hair_index >= 0:
		_apply_surface_tint(body, hair_index, _hair_tint(str(equipped.get("hair", "hair_1"))))
		report["hair"] = "material"

	_apply_glasses(parts, str(equipped.get("accessories", "glasses_1")))
	report["accessories"] = "material"

	return report

static func _ensure_outfit_shader(outfit: MeshInstance3D):
	if outfit == null or outfit.mesh == null or outfit.mesh.get_surface_count() == 0:
		return null

	var override = outfit.get_surface_override_material(0)
	if override is ShaderMaterial and override.has_meta(OUTFIT_SHADER_META):
		return override

	var source_material = outfit.get_active_material(0)
	var texture = _material_texture(source_material)
	var base_color = _material_color(source_material)

	var shader = Shader.new()
	shader.code = OUTFIT_SHADER_CODE
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_meta(OUTFIT_SHADER_META, true)
	material.set_shader_parameter("albedo_tex", texture)
	material.set_shader_parameter("base_color", base_color)

	var bounds = outfit.mesh.get_aabb()
	var y_min_value = bounds.position.y
	var y_max_value = bounds.position.y + bounds.size.y
	if abs(y_max_value - y_min_value) < 0.001:
		y_min_value = 0.0
		y_max_value = 1.0
	material.set_shader_parameter("y_min", y_min_value)
	material.set_shader_parameter("y_max", y_max_value)
	material.set_shader_parameter("shoes_cut", 0.22)
	material.set_shader_parameter("bottom_cut", 0.56)
	outfit.set_surface_override_material(0, material)
	return material

static func _apply_prototype_tint(material: ShaderMaterial, category: String, item_id: String) -> void:
	var color = Color.WHITE
	var amount = 0.0
	if category == "tops":
		color = _top_tint(item_id)
		amount = 0.0 if item_id == "" or item_id == "top_1" else 0.78
		material.set_shader_parameter("top_tint", color)
		material.set_shader_parameter("top_mix", amount)
	elif category == "bottoms":
		color = _bottom_tint(item_id)
		amount = 0.0 if item_id == "" or item_id == "skirt_1" else 0.76
		material.set_shader_parameter("bottom_tint", color)
		material.set_shader_parameter("bottom_mix", amount)
	elif category == "shoes":
		color = _shoes_tint(item_id)
		amount = 0.0 if item_id == "" or item_id == "shoes_1" else 0.82
		material.set_shader_parameter("shoes_tint", color)
		material.set_shader_parameter("shoes_mix", amount)

static func _set_region_visible(material: ShaderMaterial, category: String, visible: bool) -> void:
	var value = 1.0 if visible else 0.0
	if category == "tops":
		material.set_shader_parameter("top_visible", value)
	elif category == "bottoms":
		material.set_shader_parameter("bottom_visible", value)
	elif category == "shoes":
		material.set_shader_parameter("shoes_visible", value)

# Si existe una prenda 3D con el item_id actual se usa en lugar del prototipo.
# La prenda debe estar riggeada con el mismo orden/rest pose de huesos de Juli.
static func _equip_geometry_if_available(character: Node, category: String, item_id: String) -> bool:
	_clear_geometry(character, category)
	if item_id == "":
		return false

	var path = _find_garment_path(category, item_id)
	if path == "":
		return false

	var resource = load(path)
	if not (resource is PackedScene):
		push_warning("ModelaConJuli: prenda no es PackedScene: " + path)
		return false

	var staging = resource.instantiate()
	if not (staging is Node3D):
		if staging:
			staging.queue_free()
		return false

	var parts = ModularAvatarRuntime.prepare(character)
	var skeleton = parts.get("Skeleton")
	if not (skeleton is Skeleton3D):
		staging.queue_free()
		return false

	staging.name = GEOMETRY_PREFIX + category
	character.add_child(staging)
	var meshes = _find_meshes(staging)
	if meshes.is_empty():
		staging.queue_free()
		return false

	var skinned_count = 0
	for mesh_variant in meshes:
		var mesh = mesh_variant as MeshInstance3D
		if mesh == null:
			continue
		# Algunos GLB, incluido Juli, importan skin=null aunque sus ArrayMesh sí
		# contienen ARRAY_BONES/ARRAY_WEIGHTS. Esos datos son la prueba fiable.
		if ModularAvatarRuntime.has_bone_weights(mesh):
			mesh.skeleton = mesh.get_path_to(skeleton)
			skinned_count += 1

	if skinned_count == 0:
		push_warning("ModelaConJuli: prenda sin pesos de huesos: " + path)
		staging.queue_free()
		return false

	staging.set_meta("wardrobe_item_id", item_id)
	return true

static func _find_garment_path(category: String, item_id: String) -> String:
	var base = WARDROBE_ROOT + "/" + category + "/" + item_id
	for extension in [".glb", ".tscn"]:
		var candidate = base + extension
		if ResourceLoader.exists(candidate):
			return candidate
	return ""

static func _clear_geometry(character: Node, category: String) -> void:
	var old = _find_node_recursive(character, GEOMETRY_PREFIX + category)
	if old:
		old.queue_free()

static func _apply_surface_tint(mesh: MeshInstance3D, surface_index: int, tint_data: Dictionary) -> void:
	if mesh == null or mesh.mesh == null:
		return
	if surface_index < 0 or surface_index >= mesh.mesh.get_surface_count():
		return

	var current = mesh.get_surface_override_material(surface_index)
	var material = current
	if not (material is ShaderMaterial and material.has_meta(COLOR_SHADER_META)):
		var source_material = mesh.get_active_material(surface_index)
		var shader = Shader.new()
		shader.code = COLOR_SHADER_CODE
		material = ShaderMaterial.new()
		material.shader = shader
		material.set_meta(COLOR_SHADER_META, true)
		material.set_shader_parameter("albedo_tex", _material_texture(source_material))
		material.set_shader_parameter("base_color", _material_color(source_material))
		mesh.set_surface_override_material(surface_index, material)

	material.set_shader_parameter("tint", tint_data.get("color", Color.WHITE))
	material.set_shader_parameter("tint_mix", float(tint_data.get("mix", 0.0)))

static func _apply_glasses(parts: Dictionary, item_id: String) -> void:
	var glasses = parts.get("Glasses")
	if not (glasses is MeshInstance3D):
		return
	glasses.visible = item_id != "none"
	if not glasses.visible:
		return
	_apply_surface_tint(glasses, 0, _glasses_tint(item_id))

static func _material_texture(material):
	if material is BaseMaterial3D and material.albedo_texture != null:
		return material.albedo_texture
	var image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

static func _material_color(material) -> Color:
	if material is BaseMaterial3D:
		return material.albedo_color
	return Color.WHITE

static func _top_tint(item_id: String) -> Color:
	match item_id:
		"top_2": return Color8(34, 35, 42)
		"top_3": return Color8(230, 117, 164)
		"top_4": return Color8(38, 31, 35)
		"top_5": return Color8(244, 241, 232)
		"top_6": return Color8(238, 71, 156)
		"top_7": return Color8(191, 169, 193)
		"top_8": return Color8(116, 34, 55)
		"top_9": return Color8(47, 48, 57)
		_: return Color.WHITE

static func _bottom_tint(item_id: String) -> Color:
	match item_id:
		"skirt_2": return Color8(61, 92, 132)
		"skirt_3": return Color8(134, 135, 143)
		"skirt_4": return Color8(238, 235, 226)
		"skirt_5": return Color8(222, 86, 145)
		"skirt_6": return Color8(196, 150, 64)
		_: return Color.WHITE

static func _shoes_tint(item_id: String) -> Color:
	match item_id:
		"shoes_2": return Color8(25, 24, 28)
		"shoes_3": return Color8(224, 101, 149)
		"shoes_4": return Color8(42, 37, 41)
		"shoes_5": return Color8(208, 164, 73)
		"shoes_6": return Color8(180, 187, 198)
		_: return Color.WHITE

static func _hair_tint(item_id: String) -> Dictionary:
	match item_id:
		"hair_2": return {"color": Color8(31, 26, 35), "mix": 0.35}
		"hair_3": return {"color": Color8(96, 57, 41), "mix": 0.72}
		"hair_4": return {"color": Color8(166, 69, 116), "mix": 0.72}
		"hair_5": return {"color": Color8(208, 169, 99), "mix": 0.74}
		"hair_6": return {"color": Color8(177, 183, 199), "mix": 0.78}
		_: return {"color": Color.WHITE, "mix": 0.0}

static func _glasses_tint(item_id: String) -> Dictionary:
	match item_id:
		"glasses_2": return {"color": Color8(25, 25, 30), "mix": 0.78}
		"glasses_3": return {"color": Color8(217, 89, 142), "mix": 0.72}
		"glasses_4": return {"color": Color8(210, 165, 68), "mix": 0.74}
		"glasses_5": return {"color": Color8(174, 181, 193), "mix": 0.74}
		"glasses_6": return {"color": Color8(155, 92, 188), "mix": 0.74}
		_: return {"color": Color.WHITE, "mix": 0.0}

static func _find_meshes(node: Node) -> Array:
	var out = []
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		out.append_array(_find_meshes(child))
	return out

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
