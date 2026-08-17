extends Node

const GameSession = preload("res://scripts/GameSession.gd")

var lobby = null
var last_mode = ""
var modal = null
var modal_title = null
var modal_body = null
var ui_font = null

func _ready():
	call_deferred("_initialize")

func _initialize():
	lobby = get_parent()
	if lobby == null:
		return
	ui_font = lobby.get("ui_font")
	if ui_font == null:
		ui_font = SystemFont.new()
		ui_font.font_names = PackedStringArray(["Bahnschrift SemiCondensed", "Bahnschrift", "Arial"])

	last_mode = str(lobby.get("selected_mode"))
	GameSession.save_mode(last_mode)
	_build_modal()
	_wire_feature_buttons(lobby)
	set_process(true)

func _process(_delta):
	if lobby == null:
		return
	var mode = str(lobby.get("selected_mode"))
	if mode != "" and mode != last_mode:
		last_mode = mode
		GameSession.save_mode(last_mode)

func _wire_feature_buttons(node: Node):
	if node is Button:
		var semantic = _button_semantic_text(node as Button).to_upper()
		if semantic.find("EVENTOS") != -1:
			(node as Button).pressed.connect(_show_events)
		elif semantic.find("CLASIFIC") != -1:
			(node as Button).pressed.connect(_show_ranking)
		elif semantic.find("EQUIPO") != -1:
			(node as Button).pressed.connect(_show_team)

	for child in node.get_children():
		_wire_feature_buttons(child)

func _button_semantic_text(button: Button) -> String:
	if button.text.strip_edges() != "":
		return button.text
	return _find_label_text(button)

func _find_label_text(node: Node) -> String:
	for child in node.get_children():
		if child is Label and (child as Label).text.strip_edges() != "":
			return (child as Label).text
		var nested = _find_label_text(child)
		if nested != "":
			return nested
	return ""

func _build_modal():
	modal = Panel.new()
	modal.position = Vector2(398, 152)
	modal.size = Vector2(484, 410)
	modal.z_index = 250
	modal.visible = false
	modal.add_theme_stylebox_override("panel", _style(Color8(10, 11, 20, 250), Color8(232, 190, 99), 2, 7))
	lobby.add_child(modal)

	modal_title = _label("", Rect2(24, 18, 436, 48), 24, Color8(232, 190, 99))
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal.add_child(modal_title)

	var divider = ColorRect.new()
	divider.position = Vector2(35, 72)
	divider.size = Vector2(414, 1)
	divider.color = Color8(116, 82, 38)
	modal.add_child(divider)

	modal_body = _label("", Rect2(38, 90, 408, 235), 16, Color8(241, 232, 215))
	modal_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	modal_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_body.add_theme_constant_override("line_spacing", 5)
	modal.add_child(modal_body)

	var close = Button.new()
	close.text = "CERRAR"
	close.position = Vector2(164, 344)
	close.size = Vector2(156, 46)
	close.add_theme_font_override("font", ui_font)
	close.add_theme_font_size_override("font_size", 16)
	close.add_theme_color_override("font_color", Color8(45, 33, 22))
	close.add_theme_stylebox_override("normal", _style(Color8(232, 190, 99), Color8(248, 216, 143), 1, 3))
	close.add_theme_stylebox_override("hover", _style(Color8(248, 216, 143), Color8(255, 230, 170), 1, 3))
	close.pressed.connect(func(): modal.visible = false)
	modal.add_child(close)

func _show_events():
	var scores = GameSession.load_scores()
	modal_title.text = "EVENTO ACTIVO"
	modal_body.text = (
		"FASHION NIGHT\n\n"
		+ "Objetivo: supera 90 puntos en la pasarela.\n"
		+ "Modo recomendado: Desafío Diario.\n"
		+ "Tu mejor puntuación local: %d / 100.\n\n" % int(scores.get("best", 0))
		+ "El evento se juega con el mismo outfit que equipes en el lobby. "
		+ "Tus resultados quedan guardados en este dispositivo."
	)
	modal.visible = true

func _show_ranking():
	var scores = GameSession.load_scores()
	var history = scores.get("history", [])
	var lines = "MEJOR: %d / 100\nÚLTIMA: %d / 100\nPASARELAS: %d\n\nÚLTIMOS RESULTADOS:\n" % [
		int(scores.get("best", 0)),
		int(scores.get("last", 0)),
		int(scores.get("runs", 0))
	]
	if history is Array and history.size() > 0:
		var limit = min(5, history.size())
		for i in range(limit):
			var row = history[i]
			if row is Dictionary:
				lines += "%d.  %d pts · %s\n" % [i + 1, int(row.get("score", 0)), _mode_name(str(row.get("mode", "classic")))]
	else:
		lines += "Completa tu primera pasarela para aparecer aquí."
	modal_title.text = "CLASIFICACIÓN LOCAL"
	modal_body.text = lines
	modal.visible = true

func _show_team():
	var equipped = lobby.get("equipped")
	var mode = str(lobby.get("selected_mode"))
	var outfit_text = ""
	if equipped is Dictionary:
		outfit_text = (
			"Cabello: %s\n" % str(equipped.get("hair", "-"))
			+ "Ropa superior: %s\n" % str(equipped.get("tops", "-"))
			+ "Pantalón/Falda: %s\n" % str(equipped.get("bottoms", "-"))
			+ "Calzado: %s\n" % str(equipped.get("shoes", "-"))
			+ "Accesorios: %s\n" % str(equipped.get("accessories", "-"))
		)
	modal_title.text = "EQUIPO ACTUAL"
	modal_body.text = "Modo: %s\n\n%s\nGuarda tu outfit antes de iniciar la pasarela." % [_mode_name(mode), outfit_text]
	modal.visible = true

func _mode_name(mode: String) -> String:
	if mode == "duel":
		return "Duelo de Estilo"
	if mode == "daily":
		return "Desafío Diario"
	return "Clásico"

func _label(text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_override("font", ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _style(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
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
	style.shadow_color = Color(0, 0, 0, 0.55)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 4)
	return style
