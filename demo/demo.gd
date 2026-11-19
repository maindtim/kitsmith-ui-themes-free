extends Control
## Kitsmith UI Themes - free sample (2 of the 24 themes of the pack).
##
## Everything on screen is a plain Godot control. The only thing that changes when you pick a
## theme is one line: `theme = load("res://themes/<name>/theme.tres")`. Read _apply() to see it,
## and _build_hud(), _build_menu() and _build_shop() for how each piece is used:
##   - type variations: AccentButton, Header + HeaderLabel, SpeechBubble + BubbleLabel,
##     PortraitFrame, KeyCap, Badge, TitleLabel, OutlineLabel
##   - inventory slots: a Panel with a StyleBoxTexture made from png/slot.png (see _slot_box())
##   - icons and glyphs: the PNG files in png/

const PACK_URL := "https://cesarlars.itch.io"
const TOOL_URL := "https://cesarlars.itch.io"
## The themes are exported at 3x: one kit pixel is three screen pixels.
const SCALE := 3

## [folder under themes/, display name] of each theme.
const THEMES := [
	["steel-blue", "Steel Blue"],
	["dungeon-1-bit", "Dungeon (1-bit)"],
]

var themes: Array = THEMES
var current := 0

var _list: ItemList
var _views: Array[Control] = []
var _tabs: TabBar
var _slots: Array[Panel] = []
var _icons: Array[Array] = []      # [TextureRect or Button, piece name]
var _tail: TextureRect
var _bubble: Control
var _caption: Label


func _ready() -> void:
	var backdrop := TextureRect.new()
	backdrop.texture = ImageTexture.create_from_image(make_backdrop(7))
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.offset_left = 10
	split.offset_top = 10
	split.offset_right = -10
	split.offset_bottom = -10
	split.add_theme_constant_override("separation", 12)
	add_child(split)
	split.add_child(_build_sidebar())
	split.add_child(_build_stage())
	show_theme(0)
	show_view(0)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_RIGHT or key.keycode == KEY_DOWN:
		show_theme(current + 1)
		accept_event()
	elif key.keycode == KEY_LEFT or key.keycode == KEY_UP:
		show_theme(current - 1)
		accept_event()


## Switches the whole screen to theme number index (wraps around).
func show_theme(index: int) -> void:
	current = posmod(index, themes.size())
	_apply("res://themes/%s" % themes[current][0])
	_list.select(current)
	_list.ensure_current_is_visible()
	_caption.text = "%d / %d   themes/%s/theme.tres" % [current + 1, themes.size(), themes[current][0]]


## Shows mock screen 0 (in-game HUD), 1 (main menu) or 2 (shop).
func show_view(index: int) -> void:
	for i in _views.size():
		_views[i].visible = i == index
	if _tabs.current_tab != index:
		_tabs.current_tab = index


func _apply(folder: String) -> void:
	# This is all it takes to skin a whole screen:
	theme = load(folder.path_join("theme.tres"))
	# Slots, icons and the bubble tail are loose PNG files of the same kit.
	var slot_box := _slot_box(load(folder.path_join("png/slot.png")))
	for slot in _slots:
		slot.add_theme_stylebox_override("panel", slot_box)
	for entry: Array in _icons:
		var texture: Texture2D = load(folder.path_join("png/%s.png" % entry[1]))
		if entry[0] is Button:
			(entry[0] as Button).icon = texture
		else:
			(entry[0] as TextureRect).texture = texture
	_tail.texture = load(folder.path_join("png/bubble_tail.png"))
	_place_tail()


## An inventory slot as a 9-slice box. The margin is in kit.json ("slot" > "slice"); for every
## theme of this pack it is (width - 10 kit pixels) / 2.
static func _slot_box(texture: Texture2D) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	var margin := (texture.get_width() - 10 * SCALE) / 2.0
	box.set_texture_margin_all(margin)
	return box


func _place_tail() -> void:
	if _tail.texture == null:
		return
	_tail.size = _tail.texture.get_size()
	# The tail overlaps the bubble's bottom edge by one kit pixel.
	_tail.position = _bubble.position + Vector2(8 * SCALE, _bubble.size.y - SCALE)


func _icon(piece: String, fill_parent: bool = false) -> TextureRect:
	var rect := TextureRect.new()
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fill_parent:
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	else:
		rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_icons.append([rect, piece])
	return rect


func _slot(piece: String, side: float, framed: bool = false) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(side, side)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_slots.append(slot)
	if piece != "":
		slot.add_child(_icon(piece, true))
	if framed:
		# The selected slot wears the hollow frame.
		var rim := Panel.new()
		rim.theme_type_variation = "PortraitFrame"
		rim.set_anchors_preset(Control.PRESET_FULL_RECT)
		rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(rim)
	return slot


func _row(text: String, input: Control, label_width: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = label_width
	row.add_child(label)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(input)
	return row


func _header(text: String, right_text: String = "", right_icon: String = "") -> PanelContainer:
	var strip := PanelContainer.new()
	strip.theme_type_variation = "Header"
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	strip.add_child(head)
	var title := Label.new()
	title.theme_type_variation = "HeaderLabel"
	title.text = text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if right_icon != "":
		head.add_child(_icon(right_icon))
	if right_text != "":
		var right := Label.new()
		right.theme_type_variation = "HeaderLabel"
		right.text = right_text
		head.add_child(right)
	return strip


# --- sidebar: the theme list -----------------------------------------------------------------

func _build_sidebar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 268
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.text = "UI THEMES"
	title.theme_type_variation = "TitleLabel"
	box.add_child(title)
	var sub := Label.new()
	sub.text = "free sample: %d of 24" % themes.size()
	sub.modulate.a = 0.75
	box.add_child(sub)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for entry: Array in themes:
		_list.add_item(entry[1])
	_list.item_selected.connect(show_theme)
	box.add_child(_list)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 6)
	box.add_child(steps)
	for step in [["Previous", -1], ["Next", 1]]:
		var b := Button.new()
		b.text = step[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: show_theme(current + int(step[1])))
		if step[1] == 1:
			b.theme_type_variation = "AccentButton"
		steps.add_child(b)
	if true:
		var get_pack := Button.new()
		get_pack.text = "Get all 24"
		get_pack.pressed.connect(func() -> void: OS.shell_open(PACK_URL))
		box.add_child(get_pack)
	var own := Button.new()
	own.text = "Make your own"
	own.tooltip_text = "Kitsmith, the generator these themes were made with"
	own.pressed.connect(func() -> void: OS.shell_open(TOOL_URL))
	box.add_child(own)
	return panel


# --- stage: three mock game screens ----------------------------------------------------------

func _build_stage() -> Control:
	var stage := Control.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_bottom = -28
	box.add_theme_constant_override("separation", 10)
	stage.add_child(box)
	_tabs = TabBar.new()
	for tab in ["In-game HUD", "Main menu", "Shop"]:
		_tabs.add_tab(tab)
	_tabs.tab_changed.connect(show_view)
	box.add_child(_tabs)
	_views = [_build_hud(), _build_menu(), _build_shop()]
	for view in _views:
		box.add_child(view)
	_caption = Label.new()
	_caption.theme_type_variation = "OutlineLabel"
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_top = -24
	_caption.clip_text = true
	stage.add_child(_caption)
	return stage


func _build_hud() -> Control:
	var game := VBoxContainer.new()
	game.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	game.add_child(top)

	# Status panel: portrait, hearts and three bars.
	var status := PanelContainer.new()
	status.custom_minimum_size.x = 330
	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 10)
	status.add_child(srow)
	var portrait := _slot("icon_shield", 72, true)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	srow.add_child(portrait)
	var sbox := VBoxContainer.new()
	sbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sbox.add_theme_constant_override("separation", 5)
	srow.add_child(sbox)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 3)
	sbox.add_child(name_row)
	var hero := Label.new()
	hero.text = "Aria  Lv 12"
	hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(hero)
	var breath := Control.new()
	breath.custom_minimum_size.x = 8
	name_row.add_child(breath)
	for i in 3:
		name_row.add_child(_icon("icon_heart" if i < 2 else "icon_heart_empty"))
	sbox.add_child(HSeparator.new())
	for item in [["HP", 72.0], ["MP", 40.0], ["XP", 86.0]]:
		var bar := ProgressBar.new()
		bar.value = item[1]
		bar.show_percentage = false
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sbox.add_child(_row(item[0], bar, 30))
	top.add_child(status)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)

	# Inventory: a header strip and ten slots.
	var inventory := PanelContainer.new()
	var ibox := VBoxContainer.new()
	ibox.add_theme_constant_override("separation", 5)
	inventory.add_child(ibox)
	ibox.add_child(_header("Inventory", "250 G"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	ibox.add_child(grid)
	var loot := ["icon_potion", "icon_sword", "icon_key", "icon_gem", "icon_coin", "icon_star", "icon_shield", "icon_bomb", "", ""]
	for i in loot.size():
		var slot := _slot(loot[i], 52, i == 1)
		grid.add_child(slot)
		if i == 0:
			# A stack count: a Label with the Badge variation.
			var count := Label.new()
			count.theme_type_variation = "Badge"
			count.text = "3"
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			count.grow_vertical = Control.GROW_DIRECTION_BEGIN
			slot.add_child(count)
	top.add_child(inventory)

	# A speech bubble with its tail, and a key prompt over the game world.
	var scene := Control.new()
	scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene.custom_minimum_size.y = 64
	game.add_child(scene)
	_bubble = PanelContainer.new()
	_bubble.theme_type_variation = "SpeechBubble"
	_bubble.position = Vector2(150, 2)
	var said := Label.new()
	said.theme_type_variation = "BubbleLabel"
	said.text = "Psst! Got any gems?"
	_bubble.add_child(said)
	scene.add_child(_bubble)
	_tail = TextureRect.new()
	_tail.stretch_mode = TextureRect.STRETCH_KEEP
	scene.add_child(_tail)
	_bubble.resized.connect(_place_tail)
	var prompt := HBoxContainer.new()
	prompt.position = Vector2(410, 8)
	prompt.add_theme_constant_override("separation", 8)
	var key := Label.new()
	key.theme_type_variation = "KeyCap"
	key.text = "E"
	prompt.add_child(key)
	var action := Label.new()
	action.theme_type_variation = "OutlineLabel"
	action.text = "Talk"
	prompt.add_child(action)
	scene.add_child(prompt)

	# Dialogue box.
	var dialogue := PanelContainer.new()
	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 8)
	dialogue.add_child(dbox)
	var who := Label.new()
	who.text = "Blacksmith"
	who.theme_type_variation = "TitleLabel"
	who.add_theme_font_size_override("font_size", 24)
	dbox.add_child(who)
	var line := Label.new()
	line.text = "That blade has seen better days. Leave it with me until sundown and it will cut like new. Fifty gold, not a coin less."
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.y = 66
	dbox.add_child(line)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	dbox.add_child(buttons)
	var tip := CheckBox.new()
	tip.text = "Tip"
	tip.button_pressed = true
	buttons.add_child(tip)
	var patience := HSlider.new()
	patience.value = 60
	patience.custom_minimum_size = Vector2(90, 0)
	patience.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_child(patience)
	for item in [["Pay 50 G", false], ["Haggle", false], ["Steal it", true]]:
		var b := Button.new()
		b.text = item[0]
		b.disabled = item[1]
		b.custom_minimum_size = Vector2(120, 0)
		if item[0] == "Pay 50 G":
			b.theme_type_variation = "AccentButton"
		buttons.add_child(b)
	game.add_child(dialogue)
	return game


func _build_menu() -> Control:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var left := PanelContainer.new()
	left.custom_minimum_size.x = 280
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 6)
	left.add_child(lbox)
	var title := Label.new()
	title.text = "MOON ANVIL"
	title.theme_type_variation = "TitleLabel"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	lbox.add_child(title)
	var tagline := Label.new()
	tagline.text = "A tiny blacksmith RPG"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbox.add_child(tagline)
	lbox.add_child(HSeparator.new())
	for item in [["Continue", false, ""], ["New game", false, "glyph_plus"], ["Load game", true, "glyph_lock"], ["Quit", false, "glyph_close"]]:
		var b := Button.new()
		b.text = item[0]
		b.disabled = item[1]
		if item[0] == "Continue":
			b.theme_type_variation = "AccentButton"
		if item[2] != "":
			# Glyphs are drawn in the theme's text colour, so they sit well on a normal button.
			_icons.append([b, item[2]])
		lbox.add_child(b)
	var saves := ItemList.new()
	saves.name = "Saves"
	saves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for save in ["1  Aria    Lv 12", "2  Borin   Lv 4", "3  empty", "4  empty", "5  empty", "6  empty"]:
		saves.add_item(save)
	saves.select(0)
	lbox.add_child(saves)
	row.add_child(left)

	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 5)
	right.add_child(rbox)
	rbox.add_child(_header("Options"))
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Name your save"
	rbox.add_child(_row("Save name", name_edit, 120))
	var difficulty := OptionButton.new()
	for d in ["Easy", "Normal", "Hard"]:
		difficulty.add_item(d)
	difficulty.select(1)
	rbox.add_child(_row("Difficulty", difficulty, 120))
	var lives := SpinBox.new()
	lives.min_value = 1
	lives.max_value = 9
	lives.value = 3
	rbox.add_child(_row("Lives", lives, 120))
	for item in [["Music", 70.0], ["Sound", 40.0]]:
		var slider := HSlider.new()
		slider.value = item[1]
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rbox.add_child(_row(item[0], slider, 120))
	var checks := HBoxContainer.new()
	checks.add_theme_constant_override("separation", 16)
	rbox.add_child(checks)
	var full := CheckBox.new()
	full.text = "Fullscreen"
	full.button_pressed = true
	checks.add_child(full)
	for item in [["Shake", true], ["Hints", false]]:
		var toggle := CheckButton.new()
		toggle.text = item[0]
		toggle.button_pressed = item[1]
		checks.add_child(toggle)
	var radios := HBoxContainer.new()
	radios.add_theme_constant_override("separation", 16)
	rbox.add_child(radios)
	var group := ButtonGroup.new()
	for item in [["Keys", true], ["Gamepad", false], ["Touch", false]]:
		var radio := CheckBox.new()
		radio.text = item[0]
		radio.button_group = group
		radio.button_pressed = item[1]
		radios.add_child(radio)
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rbox.add_child(filler)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	rbox.add_child(actions)
	for text in ["Apply", "Back"]:
		var b := Button.new()
		b.text = text
		b.custom_minimum_size.x = 110
		if text == "Apply":
			b.theme_type_variation = "AccentButton"
		actions.add_child(b)
	row.add_child(right)
	return row


func _build_shop() -> Control:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)

	var left := PanelContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 7)
	left.add_child(lbox)
	lbox.add_child(_header("Moon Anvil Shop", "250 G", "icon_coin"))
	var kinds := TabBar.new()
	for kind in ["Buy", "Sell", "Craft"]:
		kinds.add_tab(kind)
	lbox.add_child(kinds)
	for item in [
		["icon_potion", "Health potion", "25 G", "", false, false],
		["icon_sword", "Iron sword", "120 G", "", true, false],
		["icon_bomb", "Fire bomb", "60 G", "NEW", false, false],
		["icon_scroll", "Town scroll", "40 G", "", false, false],
		["icon_crown", "Old crown", "900 G", "", false, true],
	]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		# The rows share the height of the panel, whatever the theme's margins are.
		line.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lbox.add_child(line)
		line.add_child(_slot(item[0], 44, item[4]))
		var item_name := Label.new()
		item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_name.text = item[1]
		item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_name.clip_text = true
		line.add_child(item_name)
		if item[3] != "":
			var tag := Label.new()
			tag.theme_type_variation = "Badge"
			tag.text = item[3]
			tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.add_child(tag)
		var price := Label.new()
		price.text = item[2]
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price.custom_minimum_size.x = 64
		line.add_child(price)
		if item[5]:
			item_name.modulate.a = 0.5
			price.modulate.a = 0.5
		var buy := Button.new()
		buy.text = "Buy"
		buy.custom_minimum_size.x = 72
		buy.disabled = item[5]
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if item[4]:
			buy.theme_type_variation = "AccentButton"
		line.add_child(buy)
	row.add_child(left)

	var right := PanelContainer.new()
	right.custom_minimum_size.x = 250
	var rbox := VBoxContainer.new()
	rbox.add_theme_constant_override("separation", 7)
	right.add_child(rbox)
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	rbox.add_child(card)
	card.add_child(_slot("icon_sword", 56))
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(names)
	var title := Label.new()
	title.text = "Iron sword"
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 16)
	names.add_child(title)
	var kind_label := Label.new()
	kind_label.text = "Weapon"
	kind_label.modulate.a = 0.7
	names.add_child(kind_label)
	rbox.add_child(HSeparator.new())
	var blurb := Label.new()
	blurb.text = "Plain, heavy and honest. Forged right here."
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rbox.add_child(blurb)
	for stat in [["Damage", 64.0], ["Speed", 38.0], ["Weight", 80.0]]:
		var bar := ProgressBar.new()
		bar.value = stat[1]
		bar.show_percentage = false
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rbox.add_child(_row(stat[0], bar, 76))
	var amount := SpinBox.new()
	amount.min_value = 1
	amount.max_value = 9
	amount.value = 1
	rbox.add_child(_row("Amount", amount, 76))
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rbox.add_child(filler)
	var prompts := HBoxContainer.new()
	prompts.add_theme_constant_override("separation", 6)
	prompts.alignment = BoxContainer.ALIGNMENT_CENTER
	rbox.add_child(prompts)
	for prompt in [["E", "Buy"], ["Q", "Back"]]:
		var key := Label.new()
		key.theme_type_variation = "KeyCap"
		key.text = prompt[0]
		prompts.add_child(key)
		var what := Label.new()
		what.text = prompt[1] + "  "
		prompts.add_child(what)
	row.add_child(right)
	return row


## A small night landscape drawn by code (200 x 157, stretched behind the mock screens), so the
## demo needs no art besides the themes.
static func make_backdrop(backdrop_seed: int) -> Image:
	var w := 200
	var h := 157
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bands := [Color("1b2140"), Color("232b52"), Color("2c3766"), Color("38467a"), Color("46578c")]
	for y in h:
		var band: Color = bands[mini(y * bands.size() / h, bands.size() - 1)]
		for x in w:
			img.set_pixel(x, y, band)
	var rng := RandomNumberGenerator.new()
	rng.seed = backdrop_seed
	for i in 70:
		var star := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.6)))
		img.set_pixel(star.x, star.y, Color("cfd8ff") if i % 4 == 0 else Color("7f8cc4"))
	for y in range(-7, 8):
		for x in range(-7, 8):
			if x * x + y * y <= 49:
				img.set_pixel(178 + x, 70 + y, Color("f3efd2") if (x + 3) * (x + 3) + (y + 2) * (y + 2) > 30 else Color("dcd7b4"))
	var ridges := [[Color("303c6c"), 96.0, 9.0, 0.045], [Color("222c52"), 110.0, 7.0, 0.08], [Color("161c36"), 126.0, 5.0, 0.13]]
	for ridge in ridges:
		var phase := rng.randf() * TAU
		for x in w:
			var top := int(ridge[1] + sin(x * ridge[3] + phase) * ridge[2] + sin(x * ridge[3] * 2.7 + phase * 2.0) * ridge[2] * 0.4)
			for y in range(clampi(top, 0, h), h):
				img.set_pixel(x, y, ridge[0])
	return img
