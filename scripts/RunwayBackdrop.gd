extends Node3D

# Fondo 2D de alta calidad colocado como panel 3D detrás de la pasarela. Esto
# mantiene el escenario ligero para Android y aprovecha el arte del lobby.

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

	var title = Label3D.new()
	title.name = "RunwayTitle"
	title.text = "MODELA CON JULI"
	title.position = Vector3(0.0, 4.15, -7.58)
	title.font_size = 56
	title.modulate = Color("#E8C16A")
	title.outline_size = 8
	title.outline_modulate = Color(0.05, 0.03, 0.06, 0.85)
	title.pixel_size = 0.0034
	add_child(title)

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
