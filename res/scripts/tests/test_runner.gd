extends Node
class_name TestRunner

var tests: Array = []
var results: Array = []

func _ready() -> void:
	_collect_tests()
	_run_all()
	_write_results()
	print("TestRunner: ALL TESTS COMPLETED")
	get_tree().quit()

func _collect_tests() -> void:
	# Any child with a _run_all() method is treated as a test suite.
	for child in get_children():
		if child.has_method("_run_all"):
			tests.append(child)

func _run_all() -> void:
	for t in tests:
		var name := t.get_class()
		print("TestRunner: Running ", name)
		var ok := true
		var err_msg := ""
		var status := ERR_OK
		status = _run_suite(t)
		if status != OK:
			ok = false
			err_msg = "Suite failed with status %d" % status
		results.append({
			"name": name,
			"ok": ok,
			"error": err_msg,
		})

func _run_suite(suite: Node) -> int:
	# Simple wrapper: return OK if no error, non-zero otherwise.
	# Catch assertion/exception from test suites to mark failures.
	var status := OK
	var err := ""
	# GDScript try/except used to catch test failures.
	var _ok := true
	try:
		suite._run_all()
	except err:
		status = -1
		err = str(err)
		DebugLog.log("TestRunner", "SUITE_EXCEPTION", {"suite": suite.get_class(), "error": err})
	return status

func _write_results() -> void:
	var data := {
		"timestamp": Time.get_unix_time_from_system(),
		"results": results,
	}
	var json := JSON.stringify(data, "\t")
	# Prefer writing to project logs when running from source; when exported, user:// is writeable.
	var res_path := "res://logs/test_results.json"
	var user_path := "user://logs/test_results.json"

	# Attempt res:// first (convenient for CI/dev runs); fall back to user:// if not writable.
	var wrote := false
	var f := FileAccess.open(res_path, FileAccess.WRITE)
	if f:
		f.store_string(json)
		f.flush()
		print("TestRunner: wrote log to ", res_path)
		wrote = true
	else:
		# Ensure user:///logs exists
		var udir := "user://logs"
		if not DirAccess.dir_exists_absolute(udir):
			DirAccess.make_dir_recursive_absolute(udir)
		var uf := FileAccess.open(user_path, FileAccess.WRITE)
		if uf:
			uf.store_string(json)
			uf.flush()
			print("TestRunner: wrote log to ", user_path)
			wrote = true
		else:
			print("TestRunner: FAILED to write logs to both res:// and user://")

	if not wrote:
		DebugLog.log("TestRunner", "WRITE_RESULTS_FAILED", {"res_attempt": res_path, "user_attempt": user_path})
*** End Patch