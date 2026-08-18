extends Control

# MODELA CON JULI - PASARELA FUNCIONAL
# Usa siempre el mismo personaje de Juli y el outfit guardado en el Lobby.

const SAVE_PATH := "user://modela_con_juli_outfit.json"
const JULI_PATH := "res://assets/characters/juli/anime_school_girl_rigged.glb"
const WardrobeRuntime = preload("res://addons/ConfiguraBridge/configura_wardrobe_runtime.gd")
const GameSessionRuntime = preload("res://scripts/GameSession.gd")

var equipped: Dictionary = {}
var selected_mode := "classic"
var actor: Node3D = null
var character: Node3D = null
var wardrobe_runtime = null
var character_base_y := -0.15
var walking := false
var walk_phase := 0.0
var runway_tween: Tween = null

var ui_font: SystemFont = null
var status_label: Label = null
var countdown_label: Label = null
var score_label: Label = null
var best_label: Label = null
var judge_labels: Array = []
var replay_button: Button = null
var back_button: Button = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Bahnschrift", "Arial"])
	_load_outfit()
	selected_mode = GameSessionRuntime.load_mode()
	_build_background()
	_build_runway_viewport()
	_build_hud()
	set_process(true)
	call_deferred("_begin_round")


func _process(delta: float) -> void:
	if wardrobe_runtime != null:
		wardrobe_runtime.update_idle(delta)
	if walking and is_instance_valid(character):
		walk_phase += delta
		var local_position := character.position
		local_position.y = character_base_y + abs(sin(walk_phase * 8.0)) * 0.012
		character.position = local_position
	elif is_instance_valid(character):
		var local_position := character.position
		local_position.y = character_base_y
		character.position = local_position


func _load_outfit() -> void:
	equipped = {
		"hair": "hair_1",
		"tops": "top_1",
		"bottoms": "skirt_1",
		"shoes": "shoes_1",
		"accessories": "glasses_1",
		"makeup": "makeup_1"
	}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key_variant in parsed.keys():
			var key := str(key_variant)
			if equipped.has(key):
				equipped[key] = str(parsed[key_variant])


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
	shade.color = Color(0.012, 0.009, 0.022, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var stage := Panel.new()
	stage.position = Vector2(322, 76)
	stage.size = Vector2(636, 590)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.048, 0.072, 0.82), Color("#9D7536"), 2, 8))
	add_child(stage)

	var runway_floor := ColorRect.new()
	runway_floor.position = Vector2(485, 101)
	runway_floor.size = Vector2(310, 540)
	runway_floor.color = Color(0.16, 0.13, 0.17, 0.72)
	runway_floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(runway_floor)

	for x_value in [497.0, 779.0]:
		var light_strip := ColorRect.new()
		light_strip.position = Vector2(float(x_value), 104.0)
		light_strip.size = Vector2(3, 532)
		light_strip.color = Color(0.95, 0.76, 0.38, 0.42)
		light_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(light_strip)


func _build_runway_viewport() -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(330, 82)
	container.size = Vector2(620, 570)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(620, 570)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var world := Node3D.new()
	world.name = "RunwayWorld"
	viewport.add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.08, 4.45)
	camera.fov = 34.0
	camera.current = true
	world.add_child(camera)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	key.light_color = Color("#FFE7C9")
	key.light_energy = 0.76
	key.shadow_enabled = false
	world.add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 1.45, 2.5)
	fill.light_color = Color("#FFF0DA")
	fill.light_energy = 0.50
	fill.omni_range = 7.0
	fill.shadow_enabled = false
	world.add_child(fill)

	actor = Node3D.new()
	actor.name = "RunwayActor"
	actor.position = Vector3(0.0, 0.0, -1.65)
	world.add_child(actor)

	if not ResourceLoader.exists(JULI_PATH):
		push_error("[Runway] No existe el modelo de Juli: " + JULI_PATH)
		return
	var packed := load(JULI_PATH) as PackedScene
	if packed == null:
		push_error("[Runway] No se pudo cargar a Juli.")
		return
	var instance := packed.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		push_error("[Runway] El modelo de Juli no tiene raiz Node3D.")
		return

	character = instance as Node3D
	character.name = "Juli"
	character.position = Vector3(0.0, character_base_y, 0.0)
	character.rotation_degrees = Vector3.ZERO
	character.scale = Vector3.ONE
	actor.add_child(character)

	wardrobe_runtime = WardrobeRuntime.new(actor, character)
	if wardrobe_runtime.prepare_character():
		wardrobe_runtime.apply_outfit(equipped)


func _build_hud() -> void:
	var title := _make_label("PASARELA", Vector2(27, 17), Vector2(280, 45), 30, Color("#F8D88F"))
	add_child(title)
	var subtitle := _make_label(_mode_title(), Vector2(30, 55), Vector2(290, 30), 15, Color("#F4EBD9"))
	add_child(subtitle)

	var left_card := Panel.new()
	left_card.position = Vector2(25, 112)
	left_card.size = Vector2(270, 250)
	left_card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.032, 0.048, 0.94), Color(0.30, 0.27, 0.34), 1, 7))
	add_child(left_card)

	var look_title := _make_label("LOOK EN COMPETENCIA", Vector2(16, 12), Vector2(235, 28), 14, Color("#E8BE63"))
	left_card.add_child(look_title)
	var look_text := _make_label(_outfit_summary(), Vector2(16, 48), Vector2(235, 178), 13, Color("#EEE5D6"))
	look_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_card.add_child(look_text)

	status_label = _make_label("Preparando ronda...", Vector2(390, 658), Vector2(500, 40), 18, Color("#F4EBD9"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	countdown_label = _make_label("", Vector2(515, 258), Vector2(250, 110), 72, Color("#F8D88F"))
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.z_index = 100
	add_child(countdown_label)

	var score_card := Panel.new()
	score_card.position = Vector2(982, 106)
	score_card.size = Vector2(270, 394)
	score_card.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.032, 0.048, 0.95), Color("#705026"), 1, 7))
	add_child(score_card)

	var judges_title := _make_label("JURADO", Vector2(20, 12), Vector2(230, 28), 15, Color("#E8BE63"))
	judges_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_card.add_child(judges_title)

	for i in range(3):
		var judge := _make_label("Jurado %d   —" % (i + 1), Vector2(22, 55 + i * 48), Vector2(226, 38), 15, Color("#EEE5D6"))
		judge.visible = false
		score_card.add_child(judge)
		judge_labels.append(judge)

	score_label = _make_label("", Vector2(24, 211), Vector2(222, 88), 29, Color("#F8D88F"))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.visible = false
	score_card.add_child(score_label)

	var scores := GameSessionRuntime.load_scores()
	best_label = _make_label("MEJOR: %d" % int(scores.get("best", 0)), Vector2(24, 308), Vector2(222, 34), 13, Color("#CFC1A7"))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_card.add_child(best_label)

	replay_button = _make_button("REPETIR PASARELA", Vector2(1014, 526), Vector2(207, 46), false)
	replay_button.pressed.connect(_begin_round)
	replay_button.visible = false
	add_child(replay_button)

	back_button = _make_button("VOLVER AL LOBBY", Vector2(1014, 584), Vector2(207, 46), true)
	back_button.pressed.connect(_back_to_lobby)
	back_button.visible = false
	add_child(back_button)

	var exit_button := _make_button("← LOBBY", Vector2(27, 652), Vector2(135, 42), false)
	exit_button.pressed.connect(_back_to_lobby)
	add_child(exit_button)


func _begin_round() -> void:
	if actor == null or character == null:
		return
	if runway_tween != null and runway_tween.is_valid():
		runway_tween.kill()

	walking = false
	walk_phase = 0.0
	actor.position = Vector3(0.0, 0.0, -1.65)
	actor.rotation_degrees = Vector3.ZERO
	character.position = Vector3(0.0, character_base_y, 0.0)
	character.rotation_degrees = Vector3.ZERO
	if wardrobe_runtime != null:
		wardrobe_runtime.restore_idle()

	for judge_variant in judge_labels:
		(judge_variant as Label).visible = false
	score_label.visible = false
	replay_button.visible = false
	back_button.visible = false
	status_label.text = "Prepárate"
	countdown_label.visible = true
	countdown_label.text = "3"

	runway_tween = create_tween()
	runway_tween.tween_interval(0.55)
	runway_tween.tween_callback(func(): countdown_label.text = "2")
	runway_tween.tween_interval(0.55)
	runway_tween.tween_callback(func(): countdown_label.text = "1")
	runway_tween.tween_interval(0.55)
	runway_tween.tween_callback(func(): countdown_label.text = "¡YA!")
	runway_tween.tween_interval(0.35)
	runway_tween.tween_callback(_start_catwalk)


func _start_catwalk() -> void:
	countdown_label.visible = false
	status_label.text = "Camina hacia el jurado"
	walking = true
	if wardrobe_runtime != null:
		wardrobe_runtime.play_animation(["walk", "walking", "catwalk"])

	runway_tween = create_tween()
	runway_tween.set_trans(Tween.TRANS_CUBIC)
	runway_tween.set_ease(Tween.EASE_OUT)
	runway_tween.tween_property(actor, "position", Vector3(0.0, 0.0, 0.0), 2.35)
	runway_tween.tween_callback(_start_pose)


func _start_pose() -> void:
	walking = false
	character.position = Vector3(0.0, character_base_y, 0.0)
	status_label.text = "Pose frente al jurado"
	if wardrobe_runtime != null:
		if not wardrobe_runtime.play_animation(["pose", "model", "fashion"]):
			wardrobe_runtime.restore_idle()

	runway_tween = create_tween()
	runway_tween.set_trans(Tween.TRANS_QUAD)
	runway_tween.set_ease(Tween.EASE_IN_OUT)
	runway_tween.tween_property(actor, "rotation_degrees", Vector3(0.0, 14.0, 0.0), 0.42)
	runway_tween.tween_interval(0.24)
	runway_tween.tween_property(actor, "rotation_degrees", Vector3(0.0, -14.0, 0.0), 0.55)
	runway_tween.tween_interval(0.24)
	runway_tween.tween_property(actor, "rotation_degrees", Vector3.ZERO, 0.42)
	runway_tween.tween_interval(0.40)
	runway_tween.tween_callback(_judge_outfit)


func _judge_outfit() -> void:
	status_label.text = "El jurado esta puntuando..."
	var base_score := _calculate_base_score()
	var seed := _outfit_seed()
	var offsets := [
		(seed % 5) - 2,
		(int(seed / 5.0) % 5) - 2,
		(int(seed / 25.0) % 5) - 2
	]
	var scores: Array = []
	for offset_variant in offsets:
		scores.append(clampi(base_score + int(offset_variant), 60, 99))
	var final_score := int(round((int(scores[0]) + int(scores[1]) + int(scores[2])) / 3.0))

	GameSessionRuntime.record_score(final_score, selected_mode, equipped)
	var saved_scores := GameSessionRuntime.load_scores()
	best_label.text = "MEJOR: %d" % int(saved_scores.get("best", final_score))

	for i in range(judge_labels.size()):
		var judge := judge_labels[i] as Label
		judge.text = "Jurado %d   ★ %d" % [i + 1, int(scores[i])]
		judge.visible = true

	score_label.text = "%d / 100\n★" % final_score
	score_label.visible = true
	status_label.text = _score_message(final_score)
	replay_button.visible = true
	back_button.visible = true


func _calculate_base_score() -> int:
	var score := 68
	for category in ["hair", "tops", "bottoms", "shoes", "accessories", "makeup"]:
		var number := _item_number(str(equipped.get(category, "")))
		score += clampi(number, 1, 3)

	var top_number := _item_number(str(equipped.get("tops", "top_1")))
	var bottom_number := _item_number(str(equipped.get("bottoms", "skirt_1")))
	var shoe_number := _item_number(str(equipped.get("shoes", "shoes_1")))
	if (top_number + bottom_number + shoe_number) % 2 == 0:
		score += 5
	else:
		score += 3

	match selected_mode:
		"daily":
			score += 4 if (top_number == 3 or bottom_number == 5 or shoe_number == 5) else 1
		"duel":
			score -= 2
		_:
			score += 2
	return clampi(score, 65, 96)


func _outfit_seed() -> int:
	var joined := "%s|%s|%s|%s|%s|%s|%s" % [
		selected_mode,
		equipped.get("hair", ""), equipped.get("tops", ""),
		equipped.get("bottoms", ""), equipped.get("shoes", ""),
		equipped.get("accessories", ""), equipped.get("makeup", "")
	]
	return absi(joined.hash())


func _item_number(item_id: String) -> int:
	var parts := item_id.split("_", false)
	if parts.is_empty():
		return 1
	var tail := str(parts[parts.size() - 1])
	return int(tail) if tail.is_valid_int() else 1


func _mode_title() -> String:
	match selected_mode:
		"duel":
			return "DUELO DE ESTILO"
		"daily":
			return "RETO DEL DIA"
		_:
			return "PASARELA CLASICA"


func _outfit_summary() -> String:
	return "Cabello: %s\nSuperior: %s\nInferior: %s\nZapatos: %s\nLentes: %s\nMaquillaje: %s" % [
		_pretty_id(str(equipped.get("hair", "hair_1"))),
		_pretty_id(str(equipped.get("tops", "top_1"))),
		_pretty_id(str(equipped.get("bottoms", "skirt_1"))),
		_pretty_id(str(equipped.get("shoes", "shoes_1"))),
		_pretty_id(str(equipped.get("accessories", "glasses_1"))),
		_pretty_id(str(equipped.get("makeup", "makeup_1")))
	]


func _pretty_id(item_id: String) -> String:
	return item_id.replace("_", " ").capitalize()


func _score_message(score: int) -> String:
	if score >= 92:
		return "¡Look de estrella!"
	if score >= 84:
		return "¡Gran pasarela!"
	if score >= 76:
		return "Buen look. Sigue combinando."
	return "Prueba otra combinacion y vuelve a competir."


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
	button.add_theme_stylebox_override("normal", _panel_style(Color("#E8BE63") if gold else Color(0.07, 0.065, 0.09, 0.96), Color("#705026") if gold else Color(0.34, 0.30, 0.40), 1, 5))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#F2CC78") if gold else Color(0.11, 0.10, 0.14, 0.98), Color("#F8D88F"), 1, 5))
	return button


func _panel_style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style
