extends SceneTree
## godot --headless --path . --script res://tools/run_tests.gd
## Checks the two themes (the Theme loads on its own, font, type variations, 80 PNG pieces) and
## runs the demo through both themes and its three screens.

const Demo := preload("res://demo/demo.gd")

const VARIATIONS := {
	"AccentButton": "Button", "Header": "PanelContainer", "HeaderLabel": "Label",
	"SpeechBubble": "PanelContainer", "BubbleLabel": "Label", "PortraitFrame": "Panel",
	"KeyCap": "Label", "Badge": "Label", "TitleLabel": "Label", "OutlineLabel": "Label",
}

var _passed := 0
var _failed := 0


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL: ", label)


func _initialize() -> void:
	_check(Demo.THEMES.size() == 2, "the sample lists two themes")
	for entry: Array in Demo.THEMES:
		var folder: String = "res://themes/" + entry[0]
		var theme := load(folder + "/theme.tres") as Theme
		_check(theme != null, entry[0] + ": theme.tres loads")
		if theme == null:
			continue
		_check(theme.default_font != null and theme.default_font_size == 16, entry[0] + ": carries the pixel font at size 16")
		_check(theme.default_font.has_char("ñ".unicode_at(0)), entry[0] + ": the font has accented letters")
		var ok := true
		for variation: String in VARIATIONS:
			if theme.get_type_variation_base(variation) != StringName(VARIATIONS[variation]):
				ok = false
		_check(ok, entry[0] + ": the ten type variations are defined")
		var pngs := 0
		for file in DirAccess.get_files_at(folder + "/png"):
			if file.ends_with(".png"):
				pngs += 1
		_check(pngs == 80, entry[0] + ": png/ holds 80 pieces (got %d)" % pngs)
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(folder + "/kit.json"))
		_check(doc is Dictionary and (doc["frames"] as Dictionary).size() == 80 and doc["meta"]["scale"] == 3.0, entry[0] + ": kit.json describes 80 frames at 3x")
		for file in ["kit.png", "font.png", "font.fnt", "font_bold.fnt", "font_outline.fnt", "palette.hex", "preview.png", "kit.css"]:
			_check(FileAccess.file_exists(folder + "/" + file), "%s: %s is there" % [entry[0], file])

	# The root window joins the tree after _initialize() returns: wait one frame.
	await process_frame
	var demo: Control = load("res://demo/demo.tscn").instantiate()
	root.add_child(demo)
	for i in Demo.THEMES.size():
		demo.show_theme(i)
		_check(demo.theme != null and demo.current == i, "demo: theme %d applies" % i)
	demo.show_theme(2)
	_check(demo.current == 0, "demo: Next after the last theme wraps to the first")
	for view in 3:
		demo.show_view(view)
		_check(demo._views[view].visible, "demo: screen %d shows" % view)
	demo.free()
	print("%d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
