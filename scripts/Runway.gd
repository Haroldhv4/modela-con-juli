extends Control

# Functional vertical slice for Modela con Juli:
# saved wardrobe -> real 3D look -> runway sequence -> score -> return/replay.

const SAVE_PATH := "user://modela_con_juli_outfit.json"
const LOOK_VARIANTS := {
	"top_1": "res://assets/characters/juli/anime_school_girl_rigged.glb",
	"top_2": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_3": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"top_4": "res://assets/characters/chiyo/Chiyo Yukata.glb",
	"top_5": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_6": "res://assets/characters/chiyo/Chiyo School Dress.glb",
	"top_7": "res://assets/characters/chiyo/Chiyo Normal Cloth.glb",
	"top_8": "res://assets/characters/chiyo/Chiyo Yukata.glb",
	"top_9": "res://assets/characters/chiyo/Chiyo School Dress.glb"
}

var equipped: Dictionary = {}
var character: Node3D = null
var character_base_y := -0.15
var status_label: Label = null
var score_label: Label = null
var replay_button: Button = null
var back_button: Button = null
var ui_font: SystemFont = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Bahnschrift", "Arial"])
	_load_outfit()
	_build_background()
	_build_runway_viewport()
	_build_hud()
	call_deferred("_play_runway")


func _load_outfit() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		equipped = {"tops": "top_1"}
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		equipped = {"tops": "top_1"}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		equipped = parsed
	else:
		equipped = {"tops": "top_1"}


func _build_background() -> void:
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://art/backgrounds/lobby_boutique.jpg"):
		bg.texture = load("res://art/backgrounds/lobby_boutique.jpg")
	add_child(bg)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.01, 0.025, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var runway := ColorRect.new()
	runway.position = Vector2(390, 68)
	runway.size = Vector2(500, 652)
	runway.color = Color(0.08, 0.065, 0.09, 0.78)
	runway.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(runway)

	var center_line := ColorRect.new()
	center_line.position = Vector2(638, 82)
	center_line.size = Vector2(4, 620)
	center_line.color = Color(0.91, 0.72, 0.34, 0.35)
	center_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_line)


func _build_runway_viewport() -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(255, 72)
	container.size = Vector2(770, 585)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	var viewport := SubViewport.new()
	viewport.name = "RunwayViewport"
	viewport.size = Vector2i(770, 585)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var world := Node3D.new()
	world.name = "RunwayWorld"
	viewport.add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.05, 4.45)
	camera.fov = 35.0
	camera.current = true
	world.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	key.light_color = Color("#FFE7C9")
	key.light_energy = 0.72
	key.shadow_enabled = false
	world.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 1.35, 2.4)
	fill.light_color = Color("#FFF0DA")
	fill.light_energy = 0.52
	fill.omni_range = 7.0
	fill.shadow_enabled = false
	world.add_child(fill)

	var top_id := str(equipped.get("tops", "top_1"))
	var model_path := str(LOOK_VARIANTS.get(top_id, LOOK_VARIANTS["top_1"]))
	var packed := load(model_path) as PackedScene
	if packed == null:
		push_error("[Runway] Could not load look: %s" % model_path)
		return
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return
	character = instance as Node3D
	character.name = "RunwayCharacter"
	character.position = Vector3(0.0, character_base_y, -1.55)
	world.add_child(character)


func _build_hud() -> void:
	var title := _make_label("PASARELA", Vector2(28, 18), Vector2(260, 48), 30, Color("#F8D88F"))
	add_child(title)

	var subtitle := _make_label("Tu look ya está en competencia", Vector2(31, 57), Vector2(330, 30), 15, Color("#F4EBD9"))
	add_child(subtitle)

	status_label = _make_label("Preparando pasarela...", Vector2(390, 658), Vector2(500, 38), 18, Color("#F4EBD9"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	score_label = _make_label("", Vector2(1018, 190), Vector2(230, 120), 31, Color("#F8D88F"))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.visible = false
	add_child(score_label)

	replay_button = _make_button("REPETIR", Vector2(1045, 330), Vector2(180, 46), false)
	replay_button.pressed.connect(_play_runway)
	replay_button.visible = false
	add_child(replay_button)

	back_button = _make_button("VOLVER AL LOBBY", Vector2(1045, 388), Vector2(180, 46), true)
	back_button.pressed.connect(_back_to_lobby)
	back_button.visible = false
	add_child(back_button)

	var exit_button := _make_button("← LOBBY", Vector2(30, 652), Vector2(140, 42), false)
	exit_button.pressed.connect(_back_to_lobby)
	add_child(exit_button)


func _play_runway() -> void:
	if character == null or not is_instance_valid(character):
		return

	replay_button.visible = false
	back_button.visible = false
	score_label.visible = false
	status_label.text = "Entrada a pasarela"
	character.position = Vector3(0.0, character_base_y, -1.55)
	character.rotation_degrees = Vector3.ZERO

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(character, "position", Vector3(0.0, character_base_y, 0.0), 2.0)
	tween.tween_callback(func(): status_label.text = "Pose frente al jurado")
	tween.tween_property(character, "rotation_degrees", Vector3(0.0, 18.0, 0.0), 0.35)
	tween.tween_property(character, "rotation_degrees", Vector3(0.0, -18.0, 0.0), 0.55)
	tween.tween_property(character, "rotation_degrees", Vector3.ZERO, 0.35)
	tween.tween_interval(0.45)
	tween.tween_callback(_show_result)


func _show_result() -> void:
	var score := _calculate_score()
	status_label.text = "¡Pasarela completada!"
	score_label.text = "%d / 100\n★" % score
	score_label.visible = true
	replay_button.visible = true
	back_button.visible = true


func _calculate_score() -> int:
	var score := 70
	var categories := ["hair", "tops", "bottoms", "shoes", "accessories", "makeup"]
	for category in categories:
		var item_id := str(equipped.get(category, ""))
		if item_id.is_empty():
			continue
		var parts := item_id.split("_")
		var level_hint := 1
		if parts.size() > 1 and str(parts[parts.size() - 1]).is_valid_int():
			level_hint = int(parts[parts.size() - 1])
		score += clampi(level_hint, 1, 3)

	# Small coordination bonus when all core clothing slots are present.
	if equipped.has("tops") and equipped.has("bottoms") and equipped.has("shoes"):
		score += 7
	return clampi(score, 72, 98)


func _back_to_lobby() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")


func _make_label(text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_button(text: String, pos: Vector2, button_size: Vector2, gold: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = button_size
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#251F18") if gold else Color("#F4EBD9"))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#E8BE63") if gold else Color(0.07, 0.065, 0.09, 0.94)
	normal.border_color = Color("#705026") if gold else Color(0.34, 0.30, 0.40, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = Color("#F8D88F")
	button.add_theme_stylebox_override("hover", hover)
	return button
