extends Node3D

# Fondo 2D ligero colocado detrás de la geometría de pasarela.
# El título vive en CanvasLayer dentro de RunwayV3 para que nunca se superponga
# con mensajes como POSE FINAL.

func _ready():
	var texture = _load_background()
	if texture:
		var backdrop = Sprite3D.new()
		backdrop.name = "BoutiqueBackdrop"
		backdrop.texture = texture
		backdrop.position = Vector3(0.0, 2.55, -7.72)
		backdrop.pixel_size = 0.0082
		backdrop.modulate = Color(0.72, 0.68, 0.70, 1.0)
		backdrop.shaded = false
		add_child(backdrop)

func _load_background():
	var candidates = [
		"res://art/backgrounds/lobby_boutique.jpg",
		"res://art/lobby_boutique.jpg",
		"res://lobby_boutique.jpg",
		"res://art/backgrounds/lobby_boutique_fallback.png"
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			return load(path)
	return null
