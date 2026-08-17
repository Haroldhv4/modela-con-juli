extends Node

const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")

var lobby = null
var character = null
var parts = {}

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
