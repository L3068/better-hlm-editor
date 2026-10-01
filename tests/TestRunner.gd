extends SceneTree

const NORMAL_SUITES = [
	preload("./test_smoke.gd")
]
const INTENTIONAL_FAILURE_SUITE = preload("./test_intentional_failure.gd")

func _initialize():
	call_deferred("_run")

func _run():
	var started_at = Time.get_ticks_usec()
	var passed = 0
	var failed = 0
	var skipped = 0
	var intentional_failure = "--intentional-failure" in OS.get_cmdline_user_args()
	var suites = [INTENTIONAL_FAILURE_SUITE] if intentional_failure else NORMAL_SUITES

	for suite_script in suites:
		var test_case = suite_script.new()
		print("SUITE ", test_case.suite_name())
		for test_name in test_case.test_names():
			test_case.begin_test()
			var test_started_at = Time.get_ticks_usec()
			test_case.call(test_name)
			var result = test_case.finish_test()
			var duration_ms = float(Time.get_ticks_usec() - test_started_at) / 1000.0
			if result["skip_reason"] != "":
				skipped += 1
				print("  SKIP ", test_name, " (", result["skip_reason"], ") ", "%.2f ms" % duration_ms)
			elif result["failures"].is_empty():
				passed += 1
				print("  PASS ", test_name, " ", "%.2f ms" % duration_ms)
			else:
				failed += 1
				print("  FAIL ", test_name, " ", "%.2f ms" % duration_ms)
				for failure in result["failures"]:
					print("    - ", failure)

	var duration_ms = float(Time.get_ticks_usec() - started_at) / 1000.0
	print("SUMMARY passed=", passed, " failed=", failed, " skipped=", skipped, " duration_ms=", "%.2f" % duration_ms)
	quit(1 if failed > 0 else 0)
