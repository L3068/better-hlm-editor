extends Node

var failures: Array[String] = []

func check(condition: bool, message: String):
	if not condition:
		failures.append(message)

func _ready():
	call_deferred("run_checks")

func run_checks():
	await get_tree().process_frame
	var main = get_parent()
	var menu = main.get_node("CanvasLayer/Level List")
	var missing = "user://missing-cover.png"
	check(menu.get_cover(missing, true) == menu.SINGLE_COVER, "Missing single cover uses fallback")
	check(menu.get_cover(missing, false) == menu.CAMPAIGN_COVER, "Missing campaign cover uses fallback")
	var picture = Image.create(34, 57, false, Image.FORMAT_RGBA8)
	picture.fill(Color.RED)
	var cover_path = "user://ui-regression.png"
	check(picture.save_png(cover_path) == OK, "Create temporary cover")
	check(menu.get_cover(cover_path, true).get_image().get_pixel(0, 0) == Color.RED, "Existing cover is loaded")
	App.load_level("res://default_level")
	var level_tab = main.get_node("CanvasLayer/Main GUI/Panel/TabContainer/Level")
	App.level_path = "user://"
	App.level_hlm_prefix = "ui-regression"
	level_tab.show_level_info()
	check(level_tab.cover_texture_rect.texture != null, "Level cover loads")
	App.level_hlm_prefix = "missing-cover"
	level_tab.show_level_info()
	check(level_tab.cover_texture_rect.texture == null, "Missing cover clears previous level preview")
	DirAccess.remove_absolute(cover_path)
	var tab = main.get_node("CanvasLayer/Main GUI/Panel/TabContainer/Cutscene")
	var original_sprites = ObjectsLoader.sprites
	ObjectsLoader.sprites = {
		100: {"name": "MissingSprite", "center": Vector2i.ZERO},
		101: {"name": "ReadySprite", "center": Vector2i.ZERO, "file_name": "atlas/ReadySprite", "frames": [menu.SINGLE_COVER]},
		102: {"name": "EmptySprite", "center": Vector2i.ZERO, "frames": []}
	}
	tab.refresh_sprites()
	check(tab.item_list.item_count == 3, "Unavailable sprites remain visible without aborting the list")
	if tab.item_list.item_count == 3:
		check(tab.item_list.is_item_disabled(0), "Missing sprite cannot be selected")
		check(not tab.item_list.is_item_disabled(1), "Available sprite can be selected")
		check(tab.item_list.is_item_disabled(2), "Empty sprite cannot be selected")
		tab._on_item_list_item_selected(1)
		check(App.cursor.texture == menu.SINGLE_COVER, "Selection retains correct sprite mapping")
	tab.refresh_sprites("rEaDy")
	check(tab.listed_sprites == [101] and tab.item_list.item_count == 1, "Filtering remains case insensitive")
	ObjectsLoader.sprites = original_sprites
	tab.refresh_sprites()
	check(tab.item_list.item_count == original_sprites.size(), "Full local WAD sprite catalog can be listed")
	print("UI_REGRESSIONS failures=", failures.size())
	for failure in failures:
		push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)
