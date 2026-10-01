extends RefCounted

var _failures: Array[String] = []
var _skip_reason := ""
var _temporary_paths: Array[String] = []

func suite_name() -> String:
	return "unnamed"

func test_names() -> Array[StringName]:
	return []

func begin_test():
	_failures.clear()
	_skip_reason = ""
	_temporary_paths.clear()

func finish_test() -> Dictionary:
	for path in _temporary_paths:
		var cleanup_error = _remove_tree(path)
		if cleanup_error != OK:
			_failures.append("Failed to clean temporary path %s: error %d" % [path, cleanup_error])
	return {
		"failures": _failures.duplicate(),
		"skip_reason": _skip_reason
	}

func assert_true(value: bool, message := "Expected true"):
	if !value:
		_failures.append(message)

func assert_equal(actual, expected, message := ""):
	if actual != expected:
		var prefix = message + ": " if message != "" else ""
		_failures.append("%sexpected %s, got %s" % [prefix, str(expected), str(actual)])

func assert_null(value, message := "Expected null"):
	if value != null:
		_failures.append("%s, got %s" % [message, str(value)])

func assert_not_null(value, message := "Expected non-null"):
	if value == null:
		_failures.append(message)

func assert_collection_size(collection, expected: int, message := ""):
	if collection == null:
		_failures.append(message if message != "" else "Expected a collection, got null")
		return
	var actual = collection.size()
	assert_equal(actual, expected, message if message != "" else "Collection size")

func skip(reason: String):
	_skip_reason = reason

func create_temporary_directory(label: String) -> String:
	var safe_label = label.validate_filename()
	var base_name = "miami-editor-tests-%s-%d-%d" % [safe_label, Time.get_ticks_usec(), get_instance_id()]
	var path = OS.get_temp_dir().path_join(base_name)
	var suffix = 0
	while DirAccess.dir_exists_absolute(path):
		suffix += 1
		path = OS.get_temp_dir().path_join(base_name + "-" + str(suffix))
	var error = DirAccess.make_dir_recursive_absolute(path)
	if error != OK:
		_failures.append("Failed to create temporary directory %s: error %d" % [path, error])
		return ""
	_temporary_paths.append(path)
	return path

func cleanup_temporary_paths():
	for path in _temporary_paths:
		var cleanup_error = _remove_tree(path)
		if cleanup_error != OK:
			_failures.append("Failed to clean temporary path %s: error %d" % [path, cleanup_error])

func application_root() -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/").get_base_dir()

func repository_root() -> String:
	return application_root().get_base_dir()

func _remove_tree(path: String) -> Error:
	if !DirAccess.dir_exists_absolute(path):
		return OK
	var directory = DirAccess.open(path)
	if directory == null:
		return DirAccess.get_open_error()
	directory.list_dir_begin()
	var entry = directory.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var child_path = path.path_join(entry)
			var error = OK
			if directory.current_is_dir():
				error = _remove_tree(child_path)
			else:
				error = DirAccess.remove_absolute(child_path)
			if error != OK:
				directory.list_dir_end()
				return error
		entry = directory.get_next()
	directory.list_dir_end()
	return DirAccess.remove_absolute(path)
