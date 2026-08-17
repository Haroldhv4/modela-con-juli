extends Control

# MODELA CON JULI - LOBBY V11
# V11 mantiene la UI de V10 y añade interacción 3D del personaje.
# Solo necesitas:
#   1) Tener tu fondo lobby_boutique.jpg dentro del proyecto.
#   2) Asignar este script al nodo raíz Lobby.
#
# Rutas de fondo que V10 prueba automáticamente:
#   res://art/lobby_boutique.jpg
#   res://art/backgrounds/lobby_boutique.jpg
#   res://lobby_boutique.jpg
#   res://art/backgrounds/lobby_boutique_fallback.png
#
# NO usa := sobre Dictionary/Variant, para evitar el error de inferencia de V6.

const SAVE_PATH = "user://modela_con_juli_outfit.json"

const C_PANEL = Color8(8, 9, 17, 225)
const C_PANEL_2 = Color8(14, 15, 25, 235)
const C_CARD = Color8(18, 19, 29, 246)
const C_CARD_SELECTED = Color8(42, 34, 31, 249)
const C_GOLD = Color8(232, 190, 99)
const C_GOLD_BRIGHT = Color8(248, 216, 143)
const C_GOLD_DARK = Color8(112, 78, 34)
const C_TEXT = Color8(244, 235, 217)
const C_TEXT_SOFT = Color8(206, 193, 169)
const C_MUTED = Color8(165, 159, 161)
const C_PINK = Color8(166, 38, 101)
const C_BLUE = Color8(69, 199, 237)
const C_PURPLE = Color8(166, 57, 194)
const C_GREEN = Color8(75, 226, 130)

var ui_font = null
var current_category = "tops"
var selected_mode = "classic"

var equipped = {
	"hair":"hair_1",
	"tops":"top_1",
	"bottoms":"skirt_1",
	"shoes":"shoes_1",
	"accessories":"glasses_1",
	"makeup":"makeup_1"
}

var wardrobe = {
	"hair":[
		{"id":"hair_1","name":"Negro Largo","lv":1,"tex":"hair_1.png"},
		{"id":"hair_2","name":"Noir Wave","lv":1,"tex":"hair_2.png"},
		{"id":"hair_3","name":"Cocoa Chic","lv":2,"tex":"hair_3.png"},
		{"id":"hair_4","name":"Rose Glam","lv":2,"tex":"hair_4.png"},
		{"id":"hair_5","name":"Golden Runway","lv":2,"tex":"hair_5.png"},
		{"id":"hair_6","name":"Silver Star","lv":3,"tex":"hair_6.png"}
	],
	"tops":[
		{"id":"top_1","name":"Blusa Blanca","lv":1,"tex":"top_1.png"},
		{"id":"top_2","name":"Chaqueta Noir","lv":1,"tex":"top_2.png"},
		{"id":"top_3","name":"Blazer Rosa","lv":2,"tex":"top_3.png"},
		{"id":"top_4","name":"Cuero Night","lv":2,"tex":"top_4.png"},
		{"id":"top_5","name":"Toodis White","lv":2,"tex":"top_5.png"},
		{"id":"top_6","name":"Top Pink","lv":2,"tex":"top_6.png"},
		{"id":"top_7","name":"Soft Jacket","lv":2,"tex":"top_7.png"},
		{"id":"top_8","name":"Wine Knit","lv":2,"tex":"top_8.png"},
		{"id":"top_9","name":"Onix Jacket","lv":2,"tex":"top_9.png"}
	],
	"bottoms":[
		{"id":"skirt_1","name":"Falda Negra","lv":1,"tex":"skirt_1.png"},
		{"id":"skirt_2","name":"Jeans Chic","lv":1,"tex":"skirt_2.png"},
		{"id":"skirt_3","name":"Falda Gris","lv":2,"tex":"skirt_3.png"},
		{"id":"skirt_4","name":"Pantalón White","lv":2,"tex":"skirt_4.png"},
		{"id":"skirt_5","name":"Falda Pink","lv":2,"tex":"skirt_5.png"},
		{"id":"skirt_6","name":"Runway Gold","lv":3,"tex":"skirt_6.png"}
	],
	"shoes":[
		{"id":"shoes_1","name":"Zapatos White","lv":1,"tex":"shoes_1.png"},
		{"id":"shoes_2","name":"Tacones Noir","lv":1,"tex":"shoes_2.png"},
		{"id":"shoes_3","name":"Tacones Rose","lv":2,"tex":"shoes_3.png"},
		{"id":"shoes_4","name":"Botines Noir","lv":2,"tex":"shoes_4.png"},
		{"id":"shoes_5","name":"Runway Gold","lv":2,"tex":"shoes_5.png"},
		{"id":"shoes_6","name":"Silver Chic","lv":3,"tex":"shoes_6.png"}
	],
	"accessories":[
		{"id":"glasses_1","name":"Gafas Juli","lv":1,"tex":"glasses_1.png"},
		{"id":"glasses_2","name":"Noir Frame","lv":1,"tex":"glasses_2.png"},
		{"id":"glasses_3","name":"Rose Frame","lv":2,"tex":"glasses_3.png"},
		{"id":"glasses_4","name":"Gold Frame","lv":2,"tex":"glasses_4.png"},
		{"id":"glasses_5","name":"Silver Frame","lv":2,"tex":"glasses_5.png"},
		{"id":"glasses_6","name":"Queen Glass","lv":3,"tex":"glasses_6.png"}
	],
	"makeup":[
		{"id":"makeup_1","name":"Soft Glam","lv":1,"tex":"makeup.svg"},
		{"id":"makeup_2","name":"Rose Light","lv":1,"tex":"makeup.svg"},
		{"id":"makeup_3","name":"Runway","lv":2,"tex":"makeup.svg"},
		{"id":"makeup_4","name":"Night Glam","lv":2,"tex":"makeup.svg"},
		{"id":"makeup_5","name":"Golden Hour","lv":2,"tex":"makeup.svg"},
		{"id":"makeup_6","name":"Queen Look","lv":3,"tex":"makeup.svg"}
	]
}

var category_buttons = {}
var mode_rows = {}
var quick_slots = {}
var item_scroll = null
var item_grid = null
var toast = null

# Interacción del personaje 3D
var character_container = null
var character_node = null
var character_camera = null
var character_dragging = false
var character_yaw = 0.0
var character_base_y = -0.15
var character_camera_z = 4.04
var idle_time = 0.0

func _ready():
	ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray([
		"Bahnschrift SemiCondensed",
		"Bahnschrift Condensed",
		"Bahnschrift",
		"Arial Narrow",
        "Arial"
	])

	set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_outfit()
	_build_background()
	_configure_character()
	_build_topbar()
	_build_left_panel()
	_build_right_panel()
	_build_bottom_bar()
	_build_toast()
	_refresh_categories()
	_refresh_items()
	_refresh_modes()
	_refresh_quick_slots()
	set_process(true)

func _process(delta):
	idle_time += delta
	if character_node:
		# Idle muy sutil mientras aún no tenemos una animación esquelética real.
		var p = character_node.position
		p.y = character_base_y + sin(idle_time * 1.35) * 0.008
		character_node.position = p
		character_node.rotation_degrees = Vector3(0.0, character_yaw, sin(idle_time * 0.75) * 0.25)

func _build_background():
	var bg = TextureRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(1280,720)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -100

	var candidates = [
		"res://art/lobby_boutique.jpg",
		"res://art/backgrounds/lobby_boutique.jpg",
		"res://lobby_boutique.jpg",
        "res://art/backgrounds/lobby_boutique_fallback.png"
	]
	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			bg.texture = load(candidate)
			break

	add_child(bg)
	move_child(bg,0)

	# Muy sutil: no apagamos el fondo.
	var tint = ColorRect.new()
	tint.position = Vector2.ZERO
	tint.size = Vector2(1280,720)
	tint.color = Color(0.015,0.012,0.025,0.035)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.z_index = -99
	add_child(tint)

func _configure_character():
	var container = get_node_or_null("CharacterViewportContainer")
	if container:
		character_container = container
		container.position = Vector2(393,63)
		container.size = Vector2(614,574)
		container.stretch = true
		# V11: el área central recibe mouse para poder girar/zoom.
		container.mouse_filter = Control.MOUSE_FILTER_STOP
		container.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		container.z_index = 8
		container.modulate = Color.WHITE
		container.gui_input.connect(_on_character_gui_input)

	var viewport = get_node_or_null("CharacterViewportContainer/CharacterViewport")
	if viewport:
		viewport.size = Vector2i(614,574)
		viewport.transparent_bg = true

	var cam = get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld/Camera_Juli")
	if cam:
		character_camera = cam
		character_camera_z = 4.04
		cam.current = true
		cam.position = Vector3(0.0,1.08,character_camera_z)
		cam.fov = 35.0

	# No reemplazamos materiales del GLB.
	# Solo corregimos iluminación.
	var light = get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld/Light_Juli")
	if light:
		light.light_energy = 0.55
		light.light_color = Color("#FFE7C9")
		light.rotation_degrees = Vector3(-38.0,28.0,0.0)
		light.shadow_enabled = false

	var world = get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld")
	if world:
		var old_fill = world.get_node_or_null("Fill_Light")
		if old_fill:
			old_fill.queue_free()

		var fill = OmniLight3D.new()
		fill.name = "Fill_Light"
		fill.position = Vector3(0.0,1.35,2.25)
		fill.light_color = Color("#FFF0DA")
		fill.light_energy = 0.40
		fill.omni_range = 6.0
		fill.shadow_enabled = false
		world.add_child(fill)

	var juli = get_node_or_null("CharacterViewportContainer/CharacterViewport/CharacterWorld/Juli")
	if juli:
		character_node = juli
		character_base_y = -0.15
		character_yaw = juli.rotation_degrees.y
		juli.position = Vector3(0.0,character_base_y,0.0)
		juli.scale = Vector3.ONE

func _on_character_gui_input(event):
	if character_node == null:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			character_dragging = event.pressed
			if character_container:
				character_container.mouse_default_cursor_shape = Control.CURSOR_DRAG if character_dragging else Control.CURSOR_POINTING_HAND
			if event.double_click:
				character_yaw = 0.0
				character_camera_z = 4.04
				_apply_character_zoom()
				_show_toast("Vista restablecida")
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			character_camera_z = clamp(character_camera_z - 0.18, 3.25, 4.75)
			_apply_character_zoom()
			accept_event()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			character_camera_z = clamp(character_camera_z + 0.18, 3.25, 4.75)
			_apply_character_zoom()
			accept_event()

	elif event is InputEventMouseMotion and character_dragging:
		character_yaw += event.relative.x * 0.32
		accept_event()

func _apply_character_zoom():
	if character_camera:
		var cp = character_camera.position
		cp.z = character_camera_z
		character_camera.position = cp

func _build_topbar():
	var bar = Panel.new()
	bar.position = Vector2(0,0)
	bar.size = Vector2(1280,55)
	bar.z_index = 40
	bar.add_theme_stylebox_override("panel",_style(C_PANEL,Color8(63,49,27),1,0,7))
	add_child(bar)

	var back = _button("↩",Rect2(13,7,65,39),23,C_PANEL_2,C_GOLD_DARK,1)
	bar.add_child(back)

	var badge = Panel.new()
	badge.position = Vector2(742,7)
	badge.size = Vector2(42,34)
	badge.add_theme_stylebox_override("panel",_style(Color8(42,43,55),C_GOLD_DARK,1,5,3))
	bar.add_child(badge)
	var lv = _label("18",Rect2(742,7,42,34),16,C_TEXT)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(lv)

	var user = _label("MODELA CON JULI\n★ Estrella de Plata",Rect2(791,0,218,51),15,C_TEXT)
	user.add_theme_constant_override("line_spacing",-4)
	bar.add_child(user)

	bar.add_child(_label("● 1250",Rect2(1017,7,88,34),16,C_GOLD))
	bar.add_child(_label("◆ 250",Rect2(1110,7,78,34),16,C_BLUE))

	_top_icon(bar,"res://art/ui/icons/bell.svg",1197)
	_top_icon(bar,"res://art/ui/icons/mail.svg",1224)
	_top_icon(bar,"res://art/ui/icons/gear.svg",1251)

func _top_icon(parent,path,x):
	var tex = TextureRect.new()
	tex.position = Vector2(x,12)
	tex.size = Vector2(21,21)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		tex.texture = load(path)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex)

func _build_left_panel():
	var panel = Panel.new()
	panel.position = Vector2(18,72)
	panel.size = Vector2(385,552)
	panel.z_index = 30
	panel.add_theme_stylebox_override("panel",_style(C_PANEL,C_GOLD_DARK,1,2,10))
	add_child(panel)

	var avatar_tab = _label("AVATAR",Rect2(0,6,125,34),17,C_MUTED)
	avatar_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(avatar_tab)

	var arm_tab = _label("ARMARIO",Rect2(125,6,260,34),18,C_GOLD)
	arm_tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(arm_tab)

	var line = ColorRect.new()
	line.position = Vector2(125,47)
	line.size = Vector2(260,2)
	line.color = C_GOLD
	panel.add_child(line)

	var top_defs = [
		["hair","CABELLO","hair.svg"],
		["faces","RASGOS\nFACIALES","faces.svg"],
		["tags","TAGOS","tags.svg"]
	]
	for i in range(top_defs.size()):
		var entry = top_defs[i]
		var key = str(entry[0])
		var b = _category_tile(str(entry[1]),"res://art/wardrobe/icons/"+str(entry[2]),Rect2(8+i*121,58,113,79),false)
		if wardrobe.has(key):
			b.pressed.connect(_select_category.bind(key))
		else:
			b.pressed.connect(func(): _show_toast("Próximamente"))
		panel.add_child(b)
		category_buttons[key] = b

	var side_defs = [
		["tops","ROPA\nSUPERIOR","tops.svg"],
		["bottoms","PANTALONES","bottoms.svg"],
		["shoes","CALZADO","shoes.svg"],
		["accessories","ACCESORIOS","accessories.svg"],
		["makeup","MAQUILLAJE","makeup.svg"]
	]
	for i in range(side_defs.size()):
		var entry = side_defs[i]
		var key = str(entry[0])
		var y = 145 + i*76
		var b = _category_tile(str(entry[1]),"res://art/wardrobe/icons/"+str(entry[2]),Rect2(8,y,87,69),true)
		b.pressed.connect(_select_category.bind(key))
		panel.add_child(b)
		category_buttons[key] = b

	item_scroll = ScrollContainer.new()
	item_scroll.position = Vector2(102,146)
	item_scroll.size = Vector2(275,384)
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	item_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(item_scroll)

	item_grid = GridContainer.new()
	item_grid.columns = 3
	item_grid.add_theme_constant_override("h_separation",5)
	item_grid.add_theme_constant_override("v_separation",5)
	item_scroll.add_child(item_grid)

func _category_tile(text,icon_path,rect,compact):
	var b = _button("",rect,10,C_PANEL_2,Color8(65,61,68),1)
	b.clip_contents = true

	var icon = TextureRect.new()
	var icon_size = Vector2(33,27) if compact else Vector2(35,30)
	icon.position = Vector2((rect.size.x-icon_size.x)/2.0,7)
	icon.size = icon_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.modulate = C_TEXT
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var label_y = 31.0 if compact else 36.0
	var lbl = _label(text,Rect2(4,label_y,rect.size.x-8,rect.size.y-label_y-2),9 if compact else 10,C_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_constant_override("line_spacing",1)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(lbl)
	return b

func _build_right_panel():
	# Botón de pasarela ornamental, con la silueta del mockup.
	var start = TextureButton.new()
	start.position = Vector2(1030,84)
	start.size = Vector2(230,92)
	start.ignore_texture_size = true
	start.stretch_mode = TextureButton.STRETCH_SCALE
	if ResourceLoader.exists("res://art/ui/buttons/start_normal.svg"):
		start.texture_normal = load("res://art/ui/buttons/start_normal.svg")
	if ResourceLoader.exists("res://art/ui/buttons/start_hover.svg"):
		start.texture_hover = load("res://art/ui/buttons/start_hover.svg")
		start.texture_pressed = load("res://art/ui/buttons/start_hover.svg")
	start.z_index = 35
	start.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	start.pressed.connect(_start_runway)
	add_child(start)

	var start_label = _label("EMPEZAR\nPASARELA",Rect2(0,4,230,84),22,C_TEXT)
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.add_theme_constant_override("line_spacing",-5)
	start_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start.add_child(start_label)

	var modes = Panel.new()
	modes.position = Vector2(1033,198)
	modes.size = Vector2(224,247)
	modes.z_index = 30
	modes.add_theme_stylebox_override("panel",_style(C_PANEL,C_GOLD_DARK,1,2,7))
	add_child(modes)

	var title = _label("MODOS DE JUEGO",Rect2(0,5,224,38),16,C_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modes.add_child(title)

	var defs = [
		["classic","Clásico","classic.svg",true],
		["duel","Duelo de Estilo","duel.svg",false],
		["daily","Desafío Diario","daily.svg",false]
	]
	for i in range(defs.size()):
		var entry = defs[i]
		var key = str(entry[0])
		var row = _right_row(str(entry[1]),"res://art/ui/icons/"+str(entry[2]),Rect2(7,45+i*61,210,55),key=="classic",key=="classic")
		row.pressed.connect(_select_mode.bind(key))
		modes.add_child(row)
		mode_rows[key] = row

	_lower_right("EVENTOS","res://art/ui/icons/calendar.svg",468)
	_lower_right("CLASIFICACIÓN","res://art/ui/icons/trophy.svg",531)
	_lower_right("EQUIPO","res://art/ui/icons/shirt.svg",594)

func _right_row(text,icon_path,rect,selected,arrow):
	var b = _button("",rect,15,Color8(81,61,34) if selected else C_PANEL_2,C_GOLD if selected else Color8(67,63,70),1)
	b.clip_contents = true

	var icon = TextureRect.new()
	icon.position = Vector2(13,17)
	icon.size = Vector2(21,21)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var lbl = _label(text,Rect2(40,0,145 if arrow else 160,55),15,C_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(lbl)

	if arrow:
		var ar = _label("›",Rect2(184,0,20,55),22,C_TEXT)
		ar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ar)

	return b

func _lower_right(text,icon_path,y):
	var b = _button("",Rect2(1033,y,224,54),16,C_PANEL,C_GOLD_DARK,1)
	b.z_index = 30
	b.clip_contents = true
	b.pressed.connect(func(): _show_toast("Próximamente"))
	add_child(b)

	var icon = TextureRect.new()
	icon.position = Vector2(15,17)
	icon.size = Vector2(20,20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var lbl = _label(text,Rect2(39,0,174,54),16,C_TEXT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(lbl)

func _build_bottom_bar():
	var save = _bottom_button("GUARDAR",Rect2(18,653,106,42),false)
	save.pressed.connect(_save_outfit)
	add_child(save)

	var equip = _bottom_button("EQUIPAR",Rect2(130,653,106,42),false)
	equip.pressed.connect(func(): _show_toast("Outfit equipado"))
	add_child(equip)

	var shop = _bottom_button("TIENDA",Rect2(242,653,108,42),true)
	shop.pressed.connect(func(): _show_toast("Tienda próximamente"))
	add_child(shop)

	add_child(_button("‹",Rect2(530,658,24,30),23,Color(0,0,0,0),Color(0,0,0,0),0))

	var quick_defs = [
		["tops","top_1.png"],
		["bottoms","skirt_1.png"],
		["shoes","shoes_1.png"],
		["hair","hair_1.png"]
	]
	for i in range(quick_defs.size()):
		var entry = quick_defs[i]
		var key = str(entry[0])
		var slot = _quick_slot(key,"res://art/wardrobe/items/"+str(entry[1]),Rect2(562+i*78,644,70,52))
		add_child(slot)
		quick_slots[key] = slot

	add_child(_button("›",Rect2(878,658,24,30),23,Color(0,0,0,0),Color(0,0,0,0),0))

func _bottom_button(text,rect,gold):
	var bg = C_GOLD if gold else Color8(234,229,219)
	var b = _button(text,rect,15,bg,Color8(92,73,42) if gold else Color8(198,191,180),1)
	b.add_theme_color_override("font_color",Color8(37,31,24))
	b.add_theme_stylebox_override("hover",_style(Color8(247,211,127) if gold else Color8(248,245,238),C_GOLD_DARK,1,2,4))
	return b

func _quick_slot(category,texture_path,rect):
	var p = Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel",_style(C_PANEL_2,Color8(76,67,84),1,2,4))

	var tex = TextureRect.new()
	tex.position = Vector2(5,2)
	tex.size = Vector2(rect.size.x-10,rect.size.y-7)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(texture_path):
		tex.texture = load(texture_path)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(tex)

	var stripe = ColorRect.new()
	stripe.position = Vector2(4,rect.size.y-4)
	stripe.size = Vector2(rect.size.x-8,2)
	stripe.color = C_PURPLE
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(stripe)

	var click = Button.new()
	click.position = Vector2.ZERO
	click.size = rect.size
	click.flat = true
	click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click.pressed.connect(_select_category.bind(category))
	p.add_child(click)
	return p

func _refresh_categories():
	for key_variant in category_buttons.keys():
		var key = str(key_variant)
		var b = category_buttons[key_variant]
		var active = key == current_category
		if active:
			b.add_theme_stylebox_override("normal",_style(Color8(77,58,32),C_GOLD,1,2,6))
		else:
			b.add_theme_stylebox_override("normal",_style(C_PANEL_2,Color8(65,61,68),1,2,4))

func _refresh_items():
	if item_grid == null:
		return
	for child in item_grid.get_children():
		child.queue_free()

	_refresh_categories()

	var items = wardrobe.get(current_category,[])
	for item_variant in items:
		var item = item_variant
		var selected = str(equipped.get(current_category,"")) == str(item.get("id",""))
		item_grid.add_child(_item_card(item,selected))

func _item_card(item,selected):
	var root = Control.new()
	root.custom_minimum_size = Vector2(84,119)

	var frame = Panel.new()
	frame.position = Vector2.ZERO
	frame.size = Vector2(84,119)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel",_style(C_CARD_SELECTED if selected else C_CARD,C_GOLD if selected else Color8(58,56,63),2 if selected else 1,2,4))
	root.add_child(frame)

	var lv = _label("Lv.%d" % int(item.get("lv",1)),Rect2(4,2,31,14),9,C_TEXT)
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(lv)

	if selected:
		var check = _label("✓",Rect2(63,1,17,15),13,C_GREEN)
		check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(check)

	var preview_bg = ColorRect.new()
	preview_bg.position = Vector2(7,18)
	preview_bg.size = Vector2(70,64)
	preview_bg.color = Color8(11,12,19)
	preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(preview_bg)

	var preview = TextureRect.new()
	preview.position = Vector2(9,20)
	preview.size = Vector2(66,60)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path = "res://art/wardrobe/items/" + str(item.get("tex",""))
	if ResourceLoader.exists(path):
		preview.texture = load(path)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(preview)

	# V11: nombres largos siempre debajo de la miniatura y centrados.
	var display_name = _wrap_item_name(str(item.get("name","")))
	var name = _label(display_name,Rect2(4,82,76,28),8,C_TEXT)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.add_theme_constant_override("line_spacing",0)
	name.clip_text = false
	root.add_child(name)

	var stripe = ColorRect.new()
	stripe.position = Vector2(4,114)
	stripe.size = Vector2(76,3)
	stripe.color = _rarity_color(int(item.get("lv",1)))
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(stripe)

	var click = Button.new()
	click.position = Vector2.ZERO
	click.size = Vector2(84,119)
	click.flat = true
	click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click.mouse_entered.connect(func():
		root.scale = Vector2(1.025,1.025)
		root.pivot_offset = root.size/2.0
	)
	click.mouse_exited.connect(func():
		root.scale = Vector2.ONE
	)
	click.pressed.connect(_equip_item.bind(current_category,item))
	root.add_child(click)

	return root

func _wrap_item_name(value):
	var clean = value.strip_edges()
	var words = clean.split(" ", false)

	if words.size() <= 1:
		return clean

	# Para nombres de dos palabras: siempre una palabra por línea.
	if words.size() == 2:
		return str(words[0]) + "\n" + str(words[1])

	# Para 3 o más palabras, armamos 2 líneas balanceadas.
	var first = str(words[0])
	var second = ""
	for i in range(1, words.size()):
		var word = str(words[i])
		if second == "" and (first + " " + word).length() <= 13:
			first += " " + word
		else:
			second = word if second == "" else second + " " + word

	return first if second == "" else first + "\n" + second

func _refresh_modes():
	for key_variant in mode_rows.keys():
		var key = str(key_variant)
		var row = mode_rows[key_variant]
		var active = key == selected_mode
		row.add_theme_stylebox_override("normal",_style(Color8(83,63,35) if active else C_PANEL_2,C_GOLD if active else Color8(67,63,70),1,3,4))

func _refresh_quick_slots():
	for key_variant in quick_slots.keys():
		var key = str(key_variant)
		var p = quick_slots[key_variant]
		var active = key == current_category
		p.add_theme_stylebox_override("panel",_style(C_PANEL_2,C_GOLD if active else Color8(76,67,84),2 if active else 1,2,4))

func _select_category(category):
	if not wardrobe.has(category):
		return
	current_category = category
	if item_scroll:
		item_scroll.scroll_vertical = 0
	_refresh_items()
	_refresh_quick_slots()

func _select_mode(mode):
	selected_mode = mode
	_refresh_modes()

func _equip_item(category,item):
	equipped[category] = str(item.get("id",""))
	_refresh_items()
	_show_toast("Equipado: " + str(item.get("name","")))

func _rarity_color(level):
	if level <= 1:
		return C_GOLD
	if level == 2:
		return C_PURPLE
	return C_BLUE

func _build_toast():
	toast = _label("",Rect2(466,604,350,31),13,C_TEXT)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.visible = false
	toast.z_index = 100
	toast.add_theme_stylebox_override("normal",_style(Color8(8,9,16,235),C_GOLD_DARK,1,4,6))
	add_child(toast)

func _start_runway():
	_save_outfit()
	if ResourceLoader.exists("res://scenes/Runway.tscn"):
		get_tree().change_scene_to_file("res://scenes/Runway.tscn")
	else:
		_show_toast("Pasarela: falta Runway.tscn")

func _save_outfit():
	var file = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(equipped))
	_show_toast("Outfit guardado")

func _load_outfit():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key_variant in parsed.keys():
			var key = str(key_variant)
			if equipped.has(key):
				equipped[key] = str(parsed[key_variant])

func _show_toast(message):
	if toast == null:
		return
	toast.text = message
	toast.visible = true
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		if is_instance_valid(toast):
			toast.visible = false
	)

func _button(text,rect,font_size,bg,border,width):
	var b = Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_override("font",ui_font)
	b.add_theme_font_size_override("font_size",font_size)
	b.add_theme_color_override("font_color",C_TEXT)
	b.add_theme_stylebox_override("normal",_style(bg,border,width,3,4))
	b.add_theme_stylebox_override("hover",_style(bg.lightened(0.065),C_GOLD,max(1,width),3,7))
	b.add_theme_stylebox_override("pressed",_style(bg.darkened(0.06),C_GOLD,max(1,width),3,5))
	b.add_theme_constant_override("line_spacing",-4)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _label(text,rect,font_size,color):
	var l = Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_override("font",ui_font)
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _style(bg,border,width,radius,shadow_size):
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.shadow_color = Color(0,0,0,0.42)
	s.shadow_size = shadow_size
	s.shadow_offset = Vector2(0,2)
	return s
