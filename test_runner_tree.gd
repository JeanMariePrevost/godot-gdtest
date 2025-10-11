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
        var result: Dictionary = _run_single_test(instance, m.name)
        test_results.append(result)


func _run_single_test(instance: Object, method_name: String) -> Dictionary:
    ## Execute a single test method and return the result

    # Print initial status with printraw to allow overwriting it later
    printraw(" • Running " + method_name + "...")

    # Ensure the method exists before calling
    if not instance.has_method(method_name):
        push_error("[Error] Missing method: " + method_name)
        return TestUtils.create_test_result(false, "Missing method: " + method_name)

    var result: Variant = instance.call(method_name)

    # Ensure the test returns a Dictionary with the correct keys, create a special error result if not
    if typeof(result) != TYPE_DICTIONARY:
        return TestUtils.create_test_result(false, "Unexpected result object for test: " + method_name)

    if not TestUtils.validate_test_result_format(result):
        return TestUtils.create_test_result(false, "Incorrect test result format for: " + method_name + " (Did you use TestUtils.create_test_result?)")

    # DEBUG, wait 1s
    OS.delay_msec(1000)

    # Display success/failure inline by overwriting the initial status
    var ok: bool = result.get("status", false)
    var msg: String = result.get("message", "")
    if ok:
        printraw("\u001b[2K\r • " + method_name + " ✅ Passed -> " + msg)  # \u001b[2K\r is to clear the line and move to the start of the line
    else:
        printraw("\u001b[2K\r • " + method_name + " ❌ Failed -> " + msg)  # \u001b[2K\r is to clear the line and move to the start of the line
    print()  # Print a new line to separate the results

    return result


func print_summary() -> void:
    print("\n[ Debug: All tests complete ]")

    var passed: int = 0
    var total: int = test_results.size()
    for result in test_results:
        if result["status"]:
            passed += 1
    print("[ Summary ] %d passed / %d failed" % [passed, total - passed])


func exit_safely() -> void:
    ## Exit the process safely, waiting for a frame to ensure all print statements are flushed
    await process_frame
    quit(0)
