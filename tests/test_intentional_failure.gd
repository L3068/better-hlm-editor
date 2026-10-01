extends "./TestCase.gd"

func suite_name() -> String:
	return "intentional_failure_self_test"

func test_names() -> Array[StringName]:
	return [&"test_intentional_failure"]

func test_intentional_failure():
	assert_true(false, "Intentional failure proves the runner returns nonzero")
