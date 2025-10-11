extends Node


func _ready():
	print("[ Debug: Test Runner Starting ]")

	# Get all the files in the tests directory
	var tests_dir = ProjectSettings.globalize_path("res://tests")
	var tests_dir_access = DirAccess.open(tests_dir)
	if tests_dir_access == null:
		print("Failed to open tests directory")
		get_tree().quit()
		return

	for file in tests_dir_access.get_files():
		print(" →", file)

	await get_tree().process_frame
	get_tree().quit()
