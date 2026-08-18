extends Node

const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")
const JuliWardrobeRuntime = preload("res://scripts/JuliWardrobeRuntime.gd")

var lobby = null
var character = null
var parts = {}
var last_report = {}

func _ready():
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	character = lobby.get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld/Juli")
	if character == null:
		push_error("ModelaConJuli: no se encontró Juli para preparar avatar modular")
		return

	parts = ModularAvatarRuntime.prepare(character)
	if parts.has("Body") and parts.has("Eyes") and parts.has("Hair") and parts.has("OriginalOutfit"):
		print("ModelaConJuli: avatar modular listo [Body, Eyes, Hair, OriginalOutfit]")
	else:
		push_warning("ModelaConJuli: avatar modular incompleto: " + str(parts.keys()))
		return

	var current = lobby.get("equipped")
	if current is Dictionary:
		apply_equipped(current)

# Punto único usado por la UI. No reemplaza a Juli: solo modifica sus piezas
# modulares/materiales o, cuando exista, conecta la prenda 3D al mismo rig.
func apply_equipped(equipped: Dictionary) -> Dictionary:
	if character == null:
		return {}
	last_report = JuliWardrobeRuntime.apply_equipped(character, equipped)
	return last_report

func get_last_report() -> Dictionary:
	return last_report.duplicate(true)
