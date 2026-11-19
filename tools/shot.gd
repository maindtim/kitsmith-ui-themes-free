extends SceneTree
## Takes the screenshots of the README from the running demo:
##   godot --path . --resolution 1152x648 --script res://tools/shot.gd
## Writes screenshots/<theme>-<screen>.png for both themes.


func _initialize() -> void:
	await process_frame
	var demo: Control = load("res://demo/demo.tscn").instantiate()
	root.add_child(demo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	var screens := ["hud", "menu", "shop"]
	for i in demo.themes.size():
		for view in screens.size():
			demo.show_theme(i)
			demo.show_view(view)
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			var file := "res://screenshots/%s-%s.png" % [demo.themes[i][0], screens[view]]
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path(file))
			print("saved ", file)
	quit()
