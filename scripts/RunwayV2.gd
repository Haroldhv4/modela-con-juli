extends Node3D

# Pasarela jugable para Modela con Juli.
# Funciona sin animaciones importadas: mueve el personaje por la pasarela y,
# cuando reconoce huesos humanoides, añade balanceo de piernas/brazos.

const OutfitRuntime = preload("res://scripts/OutfitRuntime.gd")
const OUTFIT_SAVE_PATH = "user://modela_con_juli_outfit.json"

const C_RUNWAY = Color8(35, 30, 35)
const C_GOLD = Color8(232, 190, 99)
const C_GOLD_BRIGHT = Color8(248, 216, 143)
const C_TEXT = Color8(245, 237, 220)
const C_PURPLE = Color8(183, 93, 215)

var ui_font = null
var character = null
var skeleton = null
var camera = null
var status_label = null
var progress_label = null
var score_panel = null
var score_label = null
var stars_label = null

var phase = "intro"
var phase_time = 0.0
var walk_clock = 0.0
var active_variant = OutfitRuntime.DEFAULT_VARIANT
var bone_indices = {}
var bone_base = {}

func _ready():
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray([
		"Bahnschrift SemiCondensed",
		"Bahnschrift Condensed",
		"Bahnschrift",
		"Arial Narrow",
		"Arial"
	])
	_build_stage()
	_build_lights()
	_build_camera()
	_spawn_character()
	_build_ui()

func _process(delta):
	phase_time += delta
	if phase == "intro":
		_process_intro()
	elif phase == "walk":
		_process_walk(delta)
	elif phase == "pose":
		_process_pose()
	elif phase == "return":
		_process_return(delta)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_return_to_lobby()

func _build_stage():
	_make_box(Vector3(12.0, 0.08, 18.0), Vector3(0.0, -0.09, -1.5), Color8(12, 12, 19), "StageFloor")
	_make_box(Vector3(3.2, 0.10, 13.5), Vector3(0.0, 0.0, -1.45), C_RUNWAY, "Runway")
	_make_box(Vector3(0.07, 0.03, 13.6), Vector3(-1.62, 0.065, -1.45), C_GOLD, "EdgeLeft")
	_make_box(Vector3(0.07, 0.03, 13.6), Vector3(1.62, 0.065, -1.45), C_GOLD, "EdgeRight")
	_make_box(Vector3(4.2, 0.14, 2.0), Vector3(0.0, 0.02, 1.15), Color8(47, 34, 42), "PosePlatform")
	_make_box(Vector3(11.0, 5.1, 0.16), Vector3(0.0, 2.35, -8.15), Color8(9, 10, 20), "BackWall")
	_make_box(Vector3(4.9, 3.5, 0.11), Vector3(0.0, 2.05, -7.95), Color8(27, 19, 31), "BackPanel")
	_make_box(Vector3(0.11, 4.45, 0.12), Vector3(-4.75, 2.15, -8.02), C_GOLD, "GoldLeft")
	_make_box(Vector3(0.11, 4.45, 0.12), Vector3(4.75, 2.15, -8.02), C_GOLD, "GoldRight")

	# Pequeños focos laterales visibles.
	for i in range(6):
		var z = -6.7 + float(i) * 1.75
		_make_box(Vector3(0.18, 0.08, 0.18), Vector3(-2.05, 0.12, z), C_GOLD_BRIGHT, "LampL%d" % i)
		_make_box(Vector3(0.18, 0.08, 0.18), Vector3(2.05, 0.12, z), C_GOLD_BRIGHT, "LampR%d" % i)

func _build_lights():
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, 24.0, 0.0)
	key.light_color = Color("#FFE5C4")
	key.light_energy = 0.92
	key.shadow_enabled = false
	add_child(key)

	var fill_left = OmniLight3D.new()
	fill_left.position = Vector3(-3.4, 3.3, 1.9)
	fill_left.light_color = Color("#E5C5FF")
	fill_left.light_energy = 2.0
	fill_left.omni_range = 9.0
	fill_left.shadow_enabled = false
	add_child(fill_left)

	var fill_right = OmniLight3D.new()
	fill_right.position = Vector3(3.4, 3.2, 1.6)
	fill_right.light_color = Color("#FFDAB8")
	fill_right.light_energy = 1.9
	fill_right.omni_range = 9.0
	fill_right.shadow_enabled = false
	add_child(fill_right)

	for i in range(5):
		var z = -6.2 + float(i) * 1.9
		var left = OmniLight3D.new()
		left.position = Vector3(-2.2, 0.45, z)
		left.light_color = C_GOLD
		left.light_energy = 0.6
		left.omni_range = 2.7
		left.shadow_enabled = false
		add_child(left)

		var right = OmniLight3D.new()
		right.position = Vector3(2.2, 0.45, z)
		right.light_color = C_GOLD
		right.light_energy = 0.6
		right.omni_range = 2.7
		right.shadow_enabled = false
		add_child(right)

func _build_camera():
	camera = Camera3D.new()
	camera.position = Vector3(0.0, 2.12, 6.65)
	camera.fov = 42.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.0, -1.8), Vector3.UP)

func _spawn_character():
	var saved = OutfitRuntime.load_variant()
	if OutfitRuntime.is_valid_variant(saved):
		active_variant = saved

	character = OutfitRuntime.instantiate_variant(active_variant)
	if character == null:
		return
	character.name = "RunwayJuli"
	character.position = Vector3(0.0, 0.05, -6.4)
	character.rotation_degrees = Vector3.ZERO
	character.scale = Vector3.ONE
	add_child(character)

	skeleton = OutfitRuntime.find_first_skeleton(character)
	if skeleton:
		_prepare_bones()

func _prepare_bones():
	bone_indices.clear()
	bone_base.clear()
	var defs = {
		"left_leg": ["leftupleg", "leftupperleg", "lthigh", "upperlegl", "thighl"],
		"right_leg": ["rightupleg", "rightupperleg", "rthigh", "upperlegr", "thighr"],
		"left_arm": ["leftupperarm", "lupperarm", "upperarml", "leftarm"],
		"right_arm": ["rightupperarm", "rupperarm", "upperarmr", "rightarm"],
		"spine": ["spine", "chest", "upperchest"]
	}
	for key_variant in defs.keys():
		var key = str(key_variant)
		var index = _find_bone(defs[key_variant])
		if index >= 0:
			bone_indices[key] = index
			bone_base[key] = skeleton.get_bone_pose_rotation(index)

func _find_bone(tokens: Array) -> int:
	if skeleton == null:
		return -1
	for i in range(skeleton.get_bone_count()):
		var name = _normalize(str(skeleton.get_bone_name(i)))
		for token_variant in tokens:
			if name.find(_normalize(str(token_variant))) != -1:
				return i
	return -1

func _normalize(value: String) -> String:
	return value.to_lower().replace("_", "").replace("-", "").replace(".", "").replace(" ", "")

func _process_intro():
	if status_label:
		status_label.text = "PREPÁRATE PARA LA PASARELA"
	if progress_label:
		progress_label.text = "RECORRIDO  0%"
	if character:
		character.rotation_degrees.y = sin(phase_time * 1.8) * 2.0
	if phase_time >= 1.0:
		_change_phase("walk")

func _process_walk(delta):
	if character == null:
		return
	var duration = 5.4
	var t = clamp(phase_time / duration, 0.0, 1.0)
	var eased = _smooth(t)
	walk_clock += delta * 4.5
	character.position.z = lerp(-6.4, 0.45, eased)
	character.position.y = 0.05 + abs(sin(walk_clock * 2.0)) * 0.018
	character.rotation_degrees.z = sin(walk_clock) * 0.35
	_walk_bones(walk_clock)
	if status_label:
		status_label.text = "PASARELA · CAMINA CON CONFIANZA"
	if progress_label:
		progress_label.text = "RECORRIDO  %d%%" % int(t * 72.0)
	if t >= 1.0:
		_reset_bones()
		character.rotation_degrees.z = 0.0
		_change_phase("pose")

func _process_pose():
	if character == null:
		return
	var t = clamp(phase_time / 3.0, 0.0, 1.0)
	character.position = Vector3(0.0, 0.05, 0.45)
	character.rotation_degrees.y = sin(t * PI * 2.0) * 12.0
	character.rotation_degrees.z = sin(t * PI) * 1.0
	if status_label:
		status_label.text = "POSE FINAL"
	if progress_label:
		progress_label.text = "RECORRIDO  %d%%" % int(72.0 + t * 13.0)
	if t >= 1.0:
		character.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		_change_phase("return")

func _process_return(delta):
	if character == null:
		return
	var duration = 4.2
	var t = clamp(phase_time / duration, 0.0, 1.0)
	var eased = _smooth(t)
	walk_clock += delta * 4.5
	character.position.z = lerp(0.45, -5.3, eased)
	character.position.y = 0.05 + abs(sin(walk_clock * 2.0)) * 0.016
	character.rotation_degrees.z = -sin(walk_clock) * 0.3
	_walk_bones(walk_clock)
	if status_label:
		status_label.text = "REGRESO A BACKSTAGE"
	if progress_label:
		progress_label.text = "RECORRIDO  %d%%" % int(85.0 + t * 15.0)
	if t >= 1.0:
		_reset_bones()
		character.rotation_degrees = Vector3.ZERO
		phase = "score"
		_show_score()

func _walk_bones(clock: float):
	if skeleton == null:
		return
	var leg = sin(clock) * 0.27
	var arm = sin(clock) * 0.15
	_rotate_bone("left_leg", Vector3.RIGHT, leg)
	_rotate_bone("right_leg", Vector3.RIGHT, -leg)
	_rotate_bone("left_arm", Vector3.RIGHT, -arm)
	_rotate_bone("right_arm", Vector3.RIGHT, arm)
	_rotate_bone("spine", Vector3.FORWARD, sin(clock * 0.5) * 0.022)

func _rotate_bone(key: String, axis: Vector3, angle: float):
	if not bone_indices.has(key) or not bone_base.has(key):
		return
	var index = int(bone_indices[key])
	var base_rotation = bone_base[key]
	skeleton.set_bone_pose_rotation(index, base_rotation * Quaternion(axis, angle))

func _reset_bones():
	if skeleton == null:
		return
	for key_variant in bone_indices.keys():
		var key = str(key_variant)
		if bone_base.has(key):
			skeleton.set_bone_pose_rotation(int(bone_indices[key]), bone_base[key])

func _change_phase(next_phase: String):
	phase = next_phase
	phase_time = 0.0

func _smooth(value: float) -> float:
	return value * value * (3.0 - 2.0 * value)

func _build_ui():
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var top = Panel.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(1280, 64)
	top.add_theme_stylebox_override("panel", _ui_style(Color8(7, 8, 16, 238), C_GOLD, 0, 0))
	canvas.add_child(top)

	var back = _ui_button("← LOBBY", Rect2(18, 12, 108, 38), false)
	back.pressed.connect(_return_to_lobby)
	top.add_child(back)

	var title = _ui_label("MODELA CON JULI · PASARELA", Rect2(395, 8, 490, 48), 22, C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)

	status_label = _ui_label("", Rect2(405, 82, 470, 38), 17, C_TEXT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(status_label)

	progress_label = _ui_label("RECORRIDO  0%", Rect2(1035, 80, 205, 34), 15, C_GOLD)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(progress_label)

	var hint = _ui_label("Pasarela automática · ESC para volver", Rect2(420, 674, 440, 30), 13, Color8(205, 195, 180))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	canvas.add_child(hint)

	_build_score_panel(canvas)

func _build_score_panel(canvas: CanvasLayer):
	score_panel = Panel.new()
	score_panel.position = Vector2(405, 175)
	score_panel.size = Vector2(470, 350)
	score_panel.visible = false
	score_panel.add_theme_stylebox_override("panel", _ui_style(Color8(12, 12, 22, 248), C_GOLD, 2, 8))
	canvas.add_child(score_panel)

	var header = _ui_label("RESULTADO DE PASARELA", Rect2(20, 18, 430, 44), 24, C_GOLD)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_panel.add_child(header)

	score_label = _ui_label("00 / 100", Rect2(20, 78, 430, 78), 44, C_TEXT)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_panel.add_child(score_label)

	stars_label = _ui_label("★★★★★", Rect2(20, 154, 430, 52), 32, C_GOLD)
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_panel.add_child(stars_label)

	var subtitle = _ui_label("Estilo · presencia · combinación", Rect2(20, 207, 430, 34), 16, Color8(211, 200, 183))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_panel.add_child(subtitle)

	var replay = _ui_button("REPETIR", Rect2(70, 270, 145, 48), false)
	replay.pressed.connect(func(): get_tree().reload_current_scene())
	score_panel.add_child(replay)

	var lobby_button = _ui_button("VOLVER AL LOBBY", Rect2(235, 270, 165, 48), true)
	lobby_button.pressed.connect(_return_to_lobby)
	score_panel.add_child(lobby_button)

func _show_score():
	var score = _calculate_score()
	var star_count = clamp(int(round(float(score) / 20.0)), 1, 5)
	if score_label:
		score_label.text = "%d / 100" % score
	if stars_label:
		stars_label.text = _make_stars(star_count)
	if status_label:
		status_label.text = "¡PASARELA COMPLETADA!"
	if progress_label:
		progress_label.text = "RECORRIDO  100%"
	if score_panel:
		score_panel.visible = true
		score_panel.modulate = Color(1, 1, 1, 0)
		score_panel.scale = Vector2(0.94, 0.94)
		score_panel.pivot_offset = score_panel.size / 2.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(score_panel, "modulate", Color.WHITE, 0.28)
		var scale_tween = tween.tween_property(score_panel, "scale", Vector2.ONE, 0.34)
		scale_tween.set_trans(Tween.TRANS_BACK)
		scale_tween.set_ease(Tween.EASE_OUT)

func _make_stars(count: int) -> String:
	var text = ""
	for i in range(5):
		text += "★" if i < count else "☆"
	return text

func _calculate_score() -> int:
	var data = _load_equipped()
	var selected_count = 0
	for category in ["hair", "tops", "bottoms", "shoes", "accessories", "makeup"]:
		if str(data.get(category, "")) != "":
			selected_count += 1
	var bonus = 3
	if active_variant == "school":
		bonus = 2
	elif active_variant == "yukata":
		bonus = 4
	return clamp(76 + selected_count * 3 + bonus, 76, 98)

func _load_equipped() -> Dictionary:
	if not FileAccess.file_exists(OUTFIT_SAVE_PATH):
		return {}
	var file = FileAccess.open(OUTFIT_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}

func _return_to_lobby():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _make_box(size: Vector3, pos: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.16
	material.roughness = 0.53
	mesh.material = material
	var node = MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.position = pos
	add_child(node)
	return node

func _ui_label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _ui_button(text: String, rect: Rect2, gold: bool) -> Button:
	var button = Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", ui_font)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color8(42, 31, 22) if gold else C_TEXT)
	button.add_theme_stylebox_override("normal", _ui_style(C_GOLD if gold else Color8(19, 20, 32, 245), C_GOLD, 1, 3))
	button.add_theme_stylebox_override("hover", _ui_style(C_GOLD_BRIGHT if gold else Color8(42, 35, 46, 250), C_GOLD_BRIGHT, 1, 3))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _ui_style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style
