extends SceneTree

const TESTS_PATH: String = "res://tests"
var test_files: Array[String] = []
var test_results: Array[Dictionary] = []


func _initialize():
    ## Entrypoint for the headless Godot instance
    ## Launched with this or similar:
    ##     godot4c-nomono --headless -s res://utils/test_runner_tree.gd
    print("[ Debug: Test Runner Starting ]")

    if not _validate_test_directory():
        quit(1)
        return

    _discover_test_files()
    _run_all_tests()
    print_summary()
    exit_safely()


func _validate_test_directory() -> bool:
    ## Return true if the tests directory is valid, false otherwise

    # Check if the tests directory exists
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TESTS_PATH)):
        push_error("[Error] Tests directory not found: " + TESTS_PATH)
        return false

    # Check if the tests directory can be opened
    var test_dir: DirAccess = DirAccess.open(TESTS_PATH)
    if test_dir == null:
        push_error("[Error] Failed to open tests directory: " + TESTS_PATH)
        return false

    return true


func _discover_test_files() -> void:
    ## Discover all the test files in the tests directory and add them to the test_files array
    var dir: DirAccess = DirAccess.open(TESTS_PATH)
    if dir == null:
        push_error("[Error] Could not open tests directory (should not happen)")
        return

    for file: String in dir.get_files():
        if file.ends_with(".gd"):
            test_files.append(file)
        # else:
        #     print("[Info] Ignored non-GDScript file:", file)

    if test_files.is_empty():
        push_warning("[Warning] No .gd test files found in " + TESTS_PATH)
    else:
        print("[ Debug: Found %d test file(s) ]" % test_files.size())


func _run_all_tests() -> void:
    ## Run all the test files in the test_files array
    for file: String in test_files:
        _run_test_file(file)


func _run_test_file(file: String) -> void:
    ## Run tests from a single test file
    var path: String = TESTS_PATH.path_join(file)
    print("\n[ Running:", file, "]")

    var script: Script = load(path)
    if script == null:
        push_error("[Error] Failed to load script: " + path)
        return

    var instance: Object = script.new()
    var methods: Array[Dictionary] = instance.get_method_list()

    for m in methods:
        if not m.name.begins_with("test_"):
            continue
        var result: Dictionary = _run_single_test(instance, file, m.name)
        test_results.append(result)


func _run_single_test(instance: Object, file_name: String, method_name: String) -> Dictionary:
    ## Execute a single test method and return the result

    # Print initial status with printraw to allow overwriting it later
    printraw(" > " + file_name + "::" + method_name + " \u001b[90m(running)\u001b[0m")

    # Ensure the method exists before calling
    if not instance.has_method(method_name):
        push_error("[Error] Missing method: " + method_name)
        return TestUtils.create_test_result(false, "Missing method: " + method_name)

    var result: Variant = instance.call(method_name)

    # Ensure the test returns a Dictionary with the correct keys, create a special error result if not
    if typeof(result) != TYPE_DICTIONARY:
        return TestUtils.create_test_result(false, "Unexpected result object for test: " + file_name + "::" + method_name)

    if not TestUtils.validate_test_result_format(result):
        return TestUtils.create_test_result(false, "Incorrect test result format for: " + file_name + "::" + method_name + " (Did you use TestUtils.create_test_result?)")

    # DEBUG, wait between tests to see the progression better
    OS.delay_msec(20)

    # Display success/failure inline by overwriting the initial status
    var ok: bool = result.get("status", false)
    var msg: String = result.get("message", "")
    if ok:
        printraw("\u001b[2K\r > " + file_name + "::" + method_name + " \u001b[32m(passed)\u001b[0m")  # \u001b[2K\r is to clear the line and move to the start of the line, \u001b[32m makes "Passed" green, \u001b[0m resets color
    else:
        printraw("\u001b[2K\r > " + file_name + "::" + method_name + " \u001b[31m(failed)\u001b[0m \u001b[90m(" + msg + ")\u001b[0m")  # \u001b[2K\r is to clear the line and move to the start of the line, \u001b[31m makes "(failed)" red, \u001b[90m makes message dark gray, \u001b[0m resets color
    print()  # Print a new line to separate the results

    return result


func print_summary() -> void:
    var total := test_results.size()
    var passed := 0
    for result in test_results:
        if result.get("status", false):
            passed += 1
    var failed := total - passed

    print("")  # spacer line
    print("────────────────────────────")
    print(" RESULTS")
    print("────────────────────────────")
    print(" " + str(total) + " tests run")
    print(" \u001b[32m" + str(passed) + " tests passed\u001b[0m")
    if failed > 0:
        print(" \u001b[31m" + str(failed) + " tests failed\u001b[0m")
    else:
        print(" \u001b[90m" + str(failed) + " tests failed\u001b[0m")

    if failed == 0:
        print("\n \u001b[1m\u001b[32mAll tests passed\u001b[0m")

    print("────────────────────────────")


func exit_safely() -> void:
    ## Exit the process safely, waiting for a frame to ensure all print statements are flushed
    await process_frame
    quit(0)
