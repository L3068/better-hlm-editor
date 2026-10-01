extends "./TestCase.gd"

func suite_name() -> String:
	return "smoke"

func test_names() -> Array[StringName]:
	return [&"test_assertion_api", &"test_tile_coordinate_key"]

func test_assertion_api():
	assert_true(true)
	assert_equal(2 + 2, 4)
	assert_null(null)
	assert_not_null("value")
	assert_collection_size([1, 2, 3], 3)

func test_tile_coordinate_key():
	var source_path = application_root().path_join("Scripts/TileCoordinates.gd")
	assert_true(FileAccess.file_exists(source_path), "TileCoordinates.gd must exist")
	if !FileAccess.file_exists(source_path):
		return
	var script = GDScript.new()
	script.source_code = FileAccess.get_file_as_string(source_path)
	var reload_error = script.reload()
	assert_equal(reload_error, OK, "TileCoordinates.gd must compile in isolation")
	if reload_error != OK:
		return
	assert_equal(script.call("key", 0.0, 0.0), "0 0", "Float zero coordinates")
	assert_equal(script.call("key", 16.0, 32.0), "16 32", "Integral float coordinates")
	assert_equal(script.call("key", 8, 24), "8 24", "Integer coordinates")
