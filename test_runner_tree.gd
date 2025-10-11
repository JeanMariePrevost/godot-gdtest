extends SceneTree


func _initialize():
    print("[ Debug: Test Runner Starting ]")

    # Ensure tests directory exists
    var tests_dir := "res://tests"
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(tests_dir)):
        push_error("[Error] Tests directory not found: " + tests_dir)
        quit(1)
        return

    # Try to open the tests directory
    var tests_dir_access := DirAccess.open(tests_dir)
    if tests_dir_access == null:
        push_error("[Error] Failed to open tests directory: " + tests_dir)
        quit(1)
        return

    var gd_files: Array[String] = []
    var all_files := tests_dir_access.get_files()

    if all_files.is_empty():
        push_warning("[Warning] Tests directory is empty: " + tests_dir)
    else:
        for file in all_files:
            if file.ends_with(".gd"):
                gd_files.append(file)
            else:
                print("[Info] Ignored non-GDScript file:", file)

    if gd_files.is_empty():
        push_warning("[Warning] No .gd test files found in: " + tests_dir)
    else:
        print("[ Debug: Found %d test file(s) ]" % gd_files.size())
        for file in gd_files:
            print(" →", file)

    # Wait a frame to allow for async operations (if any tests get run later)
    await process_frame
    print("[ Debug: Test Runner Complete ]")
    quit()
