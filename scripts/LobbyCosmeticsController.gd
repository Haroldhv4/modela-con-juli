extends Node

# Complementa al pack Chiyo actual: el cabello sí viene como Mesh separado, así que
# las tarjetas de CABELLO cambian su tono en tiempo real sin necesitar otro GLB.

const HAIR_COLORS = {
	"hair_1": Color("#17171C"),
	"hair_2": Color("#28232A"),
	"hair_3": Color("#54382F"),
	"hair_4": Color("#A75F7C"),
	"hair_5": Color("#C6A96F"),
	"hair_6": Color("#C8CAD3")
}

var lobby = null
var world = null
var last_character = null
var last_hair_id = ""

func _ready():
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	world = lobby.get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld")
	set_process(true)

func _process(_delta):
	if lobby == null or world == null:
		return
	var character = world.get_node_or_null("Juli")
	if character == null:
		return
	var equipped = lobby.get("equipped")
	if not (equipped is Dictionary):
		return
	var hair_id = str(equipped.get("hair", "hair_1"))
	if character != last_character or hair_id != last_hair_id:
		last_character = character
		last_hair_id = hair_id
		_apply_hair(character, hair_id)

func _apply_hair(character: Node, hair_id: String):
	var hair_mesh = _find_mesh(character, "hair")
	if hair_mesh == null or hair_mesh.mesh == null:
		return
	var color = HAIR_COLORS.get(hair_id, Color.WHITE)
	for surface in range(hair_mesh.mesh.get_surface_count()):
		var source = hair_mesh.get_active_material(surface)
		if source == null:
			source = hair_mesh.mesh.surface_get_material(surface)
		if source:
			var material = source.duplicate()
			if material is BaseMaterial3D:
				material.albedo_color = color
			hair_mesh.set_surface_override_material(surface, material)

func _find_mesh(node: Node, target: String):
	if node is MeshInstance3D and str(node.name).to_lower() == target.to_lower():
		return node as MeshInstance3D
	for child in node.get_children():
		var found = _find_mesh(child, target)
		if found:
			return found
	return null
