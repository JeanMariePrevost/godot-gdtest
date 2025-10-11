extends RefCounted
class_name TestUtils


static func create_test_result(ok: bool, message: String) -> Dictionary:
    ## Helper to create a standardized test result object
    var stack: Array[Dictionary] = get_stack()
    var caller: Dictionary = stack[1] if stack.size() > 1 else {} as Dictionary
    return {
        "status": ok,
        "message": message,
        "function_name": caller.get("function", "<unknown>"),
        "file_name": _extract_file_name(caller.get("source", "<unknown>")),
        "line_number": caller.get("line", 0),
    }


static func validate_test_result_format(result: Dictionary) -> bool:
    ## Helper to validate the format of a test result object
    return result.has("status") and result.has("message") and result.has("function_name") and result.has("file_name") and result.has("line_number")


static func _extract_file_name(path: String) -> String:
    ## Extract the file name from a path
    if path == "<unknown>":
        return path
    return path.get_file()
