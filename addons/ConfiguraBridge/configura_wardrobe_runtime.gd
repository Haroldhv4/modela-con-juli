## Compatibilidad para scripts antiguos de Modela con Juli.
## El runtime real y seguro vive en wardrobe_runtime_v2.gd.
## Esta clase NO modifica huesos ni sustituye el personaje completo.
extends "res://addons/ConfiguraBridge/wardrobe_runtime_v2.gd"
class_name ConfiguraWardrobeRuntime

func _init(host: Node3D, character: Node3D = null) -> void:
	super(host, character)
