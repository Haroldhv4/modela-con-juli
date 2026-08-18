extends Node

const ModularAvatarRuntime = preload("res://scripts/ModularAvatarRuntime.gd")
const JuliWardrobeRuntime = preload("res://scripts/JuliWardrobeRuntime.gd")

var lobby = null
var character = null
var parts = {}
var last_report = {}
var last_equipped = {}

func _ready():
	set_process(false)
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	character = lobby.get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld/Juli")
	if character == null:
		push_error("ModelaConJuli: no se encontró Juli para preparar avatar modular")
		return

	parts = ModularAvatarRuntime.prepare(character)
	if parts.has("Body") and parts.has("OriginalOutfit") and parts.has("Skeleton"):
		print("ModelaConJuli: avatar modular listo [Body, OriginalOutfit, Skeleton, Glasses]")
	else:
		push_warning("ModelaConJuli: avatar modular incompleto: " + str(parts.keys()))
		return

	var current = lobby.get("equipped")
	if current is Dictionary:
		last_equipped = current.duplicate(true)
		apply_equipped(current)
	set_process(true)

# Detecta el cambio que ya hace LobbyUI_v11._equip_item(). Así no duplicamos
# lógica de botones ni necesitamos reemplazar la UI aceptada por el usuario.
func _process(_delta):
	if lobby == null or character == null:
		return
	var current = lobby.get("equipped")
	if not (current is Dictionary):
		return
	if current != last_equipped:
		last_equipped = current.duplicate(true)
		apply_equipped(current)

# Punto único usado por lobby/pasarela. No reemplaza a Juli: solo modifica sus
# piezas modulares/materiales o conecta una prenda 3D al mismo rig.
func apply_equipped(equipped: Dictionary) -> Dictionary:
	if character == null:
		return {}
	last_report = JuliWardrobeRuntime.apply_equipped(character, equipped)
	return last_report

func get_last_report() -> Dictionary:
	return last_report.duplicate(true)
