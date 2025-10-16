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
##
##
## Command-line filters (patterns are glob-style (* = any string, ? = any single character); use quotes to avoid shell expansion)
##   --include="PATTERN"           Whitelist test files by filename
##   --exclude="PATTERN"           Blacklist  test files by filename.
##   --include-method="PATTERN"    Whitelist test methods by name (currently must still also start with `test_`).
##   --exclude-method="PATTERN"    Blacklist  test methods by name.
## Examples:
##   godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --include="*enemy*"                              # only files with “enemy” in name
##   godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --exclude="*_slow.gd"                            # skip files ending with _slow.gd
##   godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --include-method="*async*"                       # only methods containing “async”
##   godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --exclude-method="*flaky*"                       # skip methods containing “flaky”
##   godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --include="*final*" --exclude-method="*flaky*"   # only files with “final” in name and skip methods containing “flaky”

extends SceneTree

const TESTS_PATH: String = "res://tests"
const LOG_EXLUDED_FILES: bool = true
const LOG_EXLUDED_METHODS: bool = true
var test_files: Array[String] = []
var test_files_excluded_by_pattern: Array[String] = []
var test_methods_excluded_by_pattern: Array[String] = []
var test_results: Array[GDTestResult] = []
var errors: Array[String] = []
var tests_functions_processed: int = 0

## Launch argument to determine what files can get included during discovery, "glob" pattern (* = any string, ? = any single character)
var whitelist_file_pattern: String = ""

## Launch argument to determine what files can get excluded during discovery, "glob" pattern (* = any string, ? = any single character)
var blacklist_file_pattern: String = ""

## Launch argument to determine what methods can get included during discovery, "glob" pattern (* = any string, ? = any single character)
var whitelist_method_pattern: String = ""

## Launch argument to determine what methods can get excluded during discovery, "glob" pattern (* = any string, ? = any single character)
var blacklist_method_pattern: String = ""


## Entrypoint for the whole process, automatically called when making this the SceneTree.
func _initialize():
    print("[ Test Runner Starting ]")

    _extract_launch_arguments()

    if not _validate_test_directory():
        quit(1)
        return

    _discover_test_files()
    await _run_all_tests()
    print_summary()
    exit_safely()


## Extarct the values from the launch arguments
func _extract_launch_arguments() -> void:
    # DEBUG: Print the launch argument as is
    # print("Launch arguments: " + str(OS.get_cmdline_args()))

    var arguments = {}
    for argument in OS.get_cmdline_args():
        if argument.contains("="):
            var key_value = argument.split("=")
            arguments[key_value[0].trim_prefix("--")] = key_value[1]
        else:
            # Options without an argument will be present in the dictionary,
            # with the value set to an empty string.
            arguments[argument.trim_prefix("--")] = ""

    # Erase the expected default ones, "-s" and the first one to end with "lbg.godot.gdscript.gdtest/gdtest.gd"
    arguments.erase("-s")
    for key in arguments.keys():
        if key.ends_with("lbg.godot.gdscript.gdtest/gdtest.gd"):
            arguments.erase(key)
            break

    # Extract the arguments
    # Example covering all the possibilities:
    # godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd include="include this file" --exclude="exclude this file" include-method="include this method" --exclude-method="exclude this method"
    # Example of excluding a simple pattern (no need for quotes if no special characters/spaces)
    # godot4 --headless -s res://addons/lbg.godot.gdscript.gdtest/gdtest.gd --exclude-method=.*enemy.*
    whitelist_file_pattern = arguments.get("include", "")
    arguments.erase("include")
    blacklist_file_pattern = arguments.get("exclude", "")
    arguments.erase("exclude")
    whitelist_method_pattern = arguments.get("include-method", "")
    arguments.erase("include-method")
    blacklist_method_pattern = arguments.get("exclude-method", "")
    arguments.erase("exclude-method")

    # Print the extracted arguments
    if whitelist_file_pattern != "" or blacklist_file_pattern != "" or whitelist_method_pattern != "" or blacklist_method_pattern != "":
        print("Extracted arguments:")
        print("  \u001b[36minclude:\u001b[0m " + whitelist_file_pattern)  # Whitelisting of files
        print("  \u001b[36mexclude:\u001b[0m " + blacklist_file_pattern)  # Blacklisting of files
        print("  \u001b[36minclude-method:\u001b[0m " + whitelist_method_pattern)  # Whitelisting of methods
        print("  \u001b[36mexclude-method:\u001b[0m " + blacklist_method_pattern)  # Blacklisting of methods

    # Print the unknown arguments
    if not arguments.is_empty():
        print("\u001b[33mUnknown arguments:\u001b[0m")
        for key in arguments:
            print("  \u001b[33m" + key + ': "' + str(arguments[key]) + '"\u001b[0m"')


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
            if blacklist_file_pattern != "" and file.match(blacklist_file_pattern):
                if LOG_EXLUDED_FILES:
                    print("\u001b[33mFile excluded:\u001b[0m " + file + " \u001b[90m(matches blacklist)\u001b[0m")
                test_files_excluded_by_pattern.append(file)
                continue
            if whitelist_file_pattern != "" and not file.match(whitelist_file_pattern):
                if LOG_EXLUDED_FILES:
                    print("\u001b[33mFile excluded:\u001b[0m " + file + " \u001b[90m(does not match whitelist)\u001b[0m")
                test_files_excluded_by_pattern.append(file)
                continue
            test_files.append(file)

    if test_files.is_empty():
        push_warning("[Warning] No .gd test files found in " + TESTS_PATH)
    else:
        print("[ Debug: Found %d test file(s) ]" % test_files.size())


## Run all the test files in the test_files array
func _run_all_tests() -> void:
    for file: String in test_files:
        await _run_test_file(file)


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

    if not test_file_instance is GDTestCase:
        errors.append("[Error] Script at " + path + " does not inherit from GDTestCase and was ignored.")
        return

    var methods: Array[Dictionary] = test_file_instance.get_method_list()

    for m in methods:
        if not m.name.begins_with("test_"):
            continue
        if blacklist_method_pattern != "" and m.name.match(blacklist_method_pattern):
            if LOG_EXLUDED_METHODS:
                print("\u001b[33mSkipped:\u001b[0m " + file + "::" + m.name + " \u001b[90m(matches blacklist)\u001b[0m")
            test_methods_excluded_by_pattern.append(file + "::" + m.name)
            continue
        if whitelist_method_pattern != "" and not m.name.match(whitelist_method_pattern):
            if LOG_EXLUDED_METHODS:
                print("\u001b[33mSkipped:\u001b[0m " + file + "::" + m.name + " \u001b[90m(does not match whitelist)\u001b[0m")
            test_methods_excluded_by_pattern.append(file + "::" + m.name)
            continue
        tests_functions_processed += 1
        var result: GDTestResult = await _run_single_test(test_file_instance, file, m.name)
        test_results.append(result)


## Execute a single test method and return the result
func _run_single_test(instance: GDTestCase, file_name: String, method_name: String) -> GDTestResult:
    # Print initial status with printraw to allow overwriting it later
    printraw(" > " + file_name + "::" + method_name + " \u001b[90m(running)\u001b[0m")

    # Ensure the method exists before calling
    if not instance.has_method(method_name):
        push_error("[Error] Missing method: " + method_name)
        return GDTestResult.new(false, "Missing method: " + method_name, file_name, method_name, 0)

    var result = instance.call(method_name)

    if result is not GDTestResult:
        result = await result  # This will be a GDScriptFunctionState instance, meaning the tests is async and must be awaited

    # DEBUG, wait between tests to see the progression better
    OS.delay_msec(3)

    # Display success/failure inline by overwriting the initial status
    if result == null:
        errors.append("[Error] Test result is null for " + file_name + "::" + method_name + ". Did the test fail mid-execution?")
        return GDTestResult.new(false, "Test failed to return a result", file_name, method_name, 0)
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
    var failed := 0
    for result in test_results:
        if result.passed:
            passed += 1
        else:
            failed += 1

    if failed + passed != total:
        errors.append("[Error] Test results do not add up. Some tests propbably failed to run.")

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
                    print("│   " + "\u001b[90m" + node_string + " " + result.function_name + " -> " + result.error_message + " " + "[ln:" + str(result.line_number) + "]\u001b[0m")
        else:
            print("│ - " + "\u001b[33m" + file_name + " (skipped)\u001b[0m")

    print("├────────────────────────────────────────────────────")
    print("│ SUMMARY")
    print("├────────────────────────────────────────────────────")
    print("│  " + str(tests_functions_processed) + " tests found")
    print("│  \u001b[32m" + str(passed) + " tests passed\u001b[0m")
    if failed > 0:
        print("│  \u001b[31m" + str(failed) + " tests failed\u001b[0m")
    else:
        print("│  \u001b[90m" + str(failed) + " tests failed\u001b[0m")

    print("│")

    if test_files_excluded_by_pattern.size() > 0:
        print("│  \u001b[90m(" + str(test_files_excluded_by_pattern.size()) + " test file(s) filtered out by command-line arguments)\u001b[0m")
    if test_methods_excluded_by_pattern.size() > 0:
        print("│  \u001b[90m(" + str(test_methods_excluded_by_pattern.size()) + " test(s) filtered out by command-line arguments)\u001b[0m")
    if test_files_excluded_by_pattern.size() > 0 or test_methods_excluded_by_pattern.size() > 0:
        print("│")

    if failed == 0:
        print("│ \u001b[1m\u001b[32mAll tests passed\u001b[0m")

    if errors.size() > 0:
        print("│\n│ \u001b[1m\u001b[31m" + str(errors.size()) + " Error(s) were encountered:\u001b[0m")
        for error in errors:
            print("│ \u001b[33m" + error + "\u001b[0m")

    print("└────────────────────────────────────────────────────")


## Exit the process safely, waiting for a frame to ensure all print statements are flushed (still required?)
func exit_safely() -> void:
    await process_frame
    await process_frame
    quit(0)
