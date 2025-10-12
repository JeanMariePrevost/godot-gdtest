## A simple test runner for headless Godot instances.
##
## This script is designed to run tests in a headless Godot instance, from the CLI.
## It discovers test files in the `TESTS_PATH` directory, runs them, and prints the results.
##
## Basic usage:
##     [your Godot binary] --headless -s res://utils/test_runner_tree.gd
## For example:
##     godot4-nomono --headless -s res://utils/test_runner_tree.gd
##     or
##     & "D:\Work\Godot_Binaries\Godot_v4.5-stable_win64\Godot_v4.5-stable_win64.exe" --headless -s res://utils/test_runner_tree.gd

extends SceneTree

const TESTS_PATH: String = "res://tests"
var test_files: Array[String] = []
var test_results: Array[TestResult] = []
var errors: Array[String] = []


## Entrypoint for the whole process, automatically called when making this the SceneTree.
func _initialize():
    print("[ Test Runner Starting ]")

    if not _validate_test_directory():
        quit(1)
        return

    _discover_test_files()
    _run_all_tests()
    print_summary()
    exit_safely()


## Ensures the tests directory is valid and can be opened
func _validate_test_directory() -> bool:
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


## Discover all the test files in the tests directory and add them to the test_files array
##
## At this stage, every ".gd" file in TESTS_PATH is considered.
func _discover_test_files() -> void:
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


## Run all the test files in the test_files array
func _run_all_tests() -> void:
    for file: String in test_files:
        _run_test_file(file)


## Loads and validates a test file, then runs all the tests inside it
func _run_test_file(file: String) -> void:
    var path: String = TESTS_PATH.path_join(file)
    print("\n[ Running:", file, "]")

    var script: Script = load(path)
    if script == null:
        errors.append("[Error] Failed to load script: " + path)
        return

    if not script.can_instantiate():
        errors.append("[Error] Script at " + path + " failed to compile or can't be instantiated.")
        return

    var test_file_instance: Object = script.new()
    if test_file_instance == null:
        errors.append("[Error] Failed to instantiate script: " + path)
        return

    if not test_file_instance is TestFile:
        errors.append("[Error] Script at " + path + " does not inherit from TestFile and was ignored.")
        return

    var methods: Array[Dictionary] = test_file_instance.get_method_list()

    for m in methods:
        if not m.name.begins_with("test_"):
            continue
        var result: TestResult = _run_single_test(test_file_instance, file, m.name)
        test_results.append(result)


## Execute a single test method and return the result
func _run_single_test(instance: TestFile, file_name: String, method_name: String) -> TestResult:
    # Print initial status with printraw to allow overwriting it later
    printraw(" > " + file_name + "::" + method_name + " \u001b[90m(running)\u001b[0m")

    # Ensure the method exists before calling
    if not instance.has_method(method_name):
        push_error("[Error] Missing method: " + method_name)
        return TestResult.new(false, "Missing method: " + method_name, file_name, method_name, 0)

    var result: TestResult = instance.call(method_name)

    # DEBUG, wait between tests to see the progression better
    OS.delay_msec(3)

    # Display success/failure inline by overwriting the initial status
    if result.passed:
        printraw("\u001b[2K\r > " + file_name + "::" + method_name + " \u001b[32m(passed)\u001b[0m")  # \u001b[2K\r is to clear the line and move to the start of the line, \u001b[32m makes "Passed" green, \u001b[0m resets color
    else:
        printraw("\u001b[2K\r > " + file_name + "::" + method_name + " \u001b[31m(failed)\u001b[0m \u001b[90m(" + result.error_message + ")\u001b[0m")  # \u001b[2K\r is to clear the line and move to the start of the line, \u001b[31m makes "(failed)" red, \u001b[90m makes message dark gray, \u001b[0m resets color
        # Append the line number to the error message
        printraw(" \u001b[90m[" + str(result.file_name) + ":" + str(result.line_number) + "]\u001b[0m")
    print()  # Print a new line to separate the results

    return result


## Displays a summary of the test results to the console
func print_summary() -> void:
    var total := test_results.size()
    var passed := 0
    for result in test_results:
        if result.passed:
            passed += 1
    var failed := total - passed

    # Group test results by file name
    var test_files_groups: Dictionary = {}

    for result in test_results:
        if not test_files_groups.has(result.file_name):
            test_files_groups[result.file_name] = []
        test_files_groups[result.file_name].append(result)

    print("")  # spacer line
    print("┌────────────────────────────────────────────────────")
    print("│ RESULTS")
    print("├────────────────────────────────────────────────────")

    # Print per-file aggregate results
    for file_name in test_files:
        var file_passed := 0
        var file_failed := 0
        if test_files_groups.has(file_name):
            for result in test_files_groups[file_name]:
                if result.passed:
                    file_passed += 1
                else:
                    file_failed += 1
            var base_color := "\u001b[32m" if file_passed > 0 and file_failed == 0 else "\u001b[31m"
            print("│ " + base_color + file_name + " (" + str(file_passed) + " passed, " + str(file_failed) + " failed)\u001b[0m")
            for result in test_files_groups[file_name]:
                if not result.passed:
                    file_failed -= 1
                    var node_string := "├──" if file_failed > 0 else "└──"
                    print("│    \u001b[90m" + node_string + "[" + str(result.file_name) + ":" + str(result.line_number) + "] " + result.error_message + "\u001b[0m")
        else:
            print("│ - " + "\u001b[33m" + file_name + " (skipped)\u001b[0m")

    print("├────────────────────────────────────────────────────")
    print("│ SUMMARY")
    print("├────────────────────────────────────────────────────")
    print("│  " + str(total) + " tests run")
    print("│  \u001b[32m" + str(passed) + " tests passed\u001b[0m")
    if failed > 0:
        print("│  \u001b[31m" + str(failed) + " tests failed\u001b[0m")
    else:
        print("│  \u001b[90m" + str(failed) + " tests failed\u001b[0m")

    if failed == 0:
        print("│\n│ \u001b[1m\u001b[32mAll tests passed\u001b[0m")

    if errors.size() > 0:
        print("│\n│ \u001b[1m\u001b[31m" + str(errors.size()) + " Error(s) were encountered:\u001b[0m")
        for error in errors:
            print("│ " + error)

    print("└────────────────────────────────────────────────────")


## Exit the process safely, waiting for a frame to ensure all print statements are flushed (still required?)
func exit_safely() -> void:
    await process_frame
    quit(0)
