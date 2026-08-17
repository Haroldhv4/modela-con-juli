extends Node

const GameSession = preload("res://scripts/GameSession.gd")

var runway = null
var recorded = false
var mode = GameSession.DEFAULT_MODE
var badge = null
var ui_font = null

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
			recorded = true

func _build_mode_badge():
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Bahnschrift SemiCondensed", "Bahnschrift", "Arial"])

	var canvas = CanvasLayer.new()
	canvas.layer = 11
	runway.add_child(canvas)

	badge = Panel.new()
	badge.position = Vector2(145, 78)
	badge.size = Vector2(205, 36)
	badge.add_theme_stylebox_override("panel", _style())
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

func _mode_name(value: String) -> String:
	if value == "duel":
		return "Duelo de Estilo"
	if value == "daily":
		return "Desafío Diario"
	return "Clásico"

func _style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color8(11, 12, 21, 230)
	style.border_color = Color8(122, 88, 39)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
