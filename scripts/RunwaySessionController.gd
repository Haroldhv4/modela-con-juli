extends Node

const GameSession = preload("res://scripts/GameSession.gd")

var runway = null
var recorded = false
var mode = GameSession.DEFAULT_MODE
var badge = null
var ui_font = null
var canvas = null

func _ready():
	call_deferred("_initialize")

func _initialize():
	runway = get_parent()
	mode = GameSession.load_mode()
	_build_mode_badge()
	set_process(true)

func _process(_delta):
	if runway == null or recorded:
		return
	if str(runway.get("phase")) == "score":
		var score_callable = Callable(runway, "_calculate_score")
		if score_callable.is_valid():
			var score = int(score_callable.call())
			var variant = str(runway.get("active_variant"))
			GameSession.record_score(score, mode, variant)
			_show_mode_result(score)
			recorded = true

func _build_mode_badge():
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Bahnschrift SemiCondensed", "Bahnschrift", "Arial"])

	canvas = CanvasLayer.new()
	canvas.layer = 11
	runway.add_child(canvas)

	badge = Panel.new()
	badge.position = Vector2(145, 78)
	badge.size = Vector2(205, 36)
	badge.add_theme_stylebox_override("panel", _style(Color8(11, 12, 21, 230), Color8(122, 88, 39)))
	canvas.add_child(badge)

	var label = Label.new()
	label.text = "MODO · " + _mode_name(mode).to_upper()
	label.position = Vector2(10, 0)
	label.size = Vector2(185, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color8(238, 220, 181))
	badge.add_child(label)

func _show_mode_result(score: int):
	if canvas == null or mode == "classic":
		return

	var result = Panel.new()
	result.position = Vector2(470, 540)
	result.size = Vector2(340, 54)
	var bg = Color8(43, 27, 45, 242)
	var border = Color8(217, 172, 88)
	result.add_theme_stylebox_override("panel", _style(bg, border))
	canvas.add_child(result)

	var text = ""
	if mode == "duel":
		var rival_score = 86
		if score >= rival_score:
			text = "DUELO GANADO · %d vs %d" % [score, rival_score]
		else:
			text = "DUELO · %d vs %d · REVANCHA" % [score, rival_score]
	elif mode == "daily":
		var target = 90
		if score >= target:
			text = "DESAFÍO DIARIO COMPLETADO · %d" % score
		else:
			text = "DESAFÍO DIARIO · META %d · TÚ %d" % [target, score]

	var label = Label.new()
	label.text = text
	label.position = Vector2(10, 0)
	label.size = Vector2(320, 54)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color8(245, 232, 204))
	result.add_child(label)

func _mode_name(value: String) -> String:
	if value == "duel":
		return "Duelo de Estilo"
	if value == "daily":
		return "Desafío Diario"
	return "Clásico"

func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style
