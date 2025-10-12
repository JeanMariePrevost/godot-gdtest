extends RefCounted
class_name TestUtils

# ------------------ Assertions


static func pass_test() -> Dictionary:
    ## Manually pass a test
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.pass_test("Expected test to pass")
    return _create_test_result(true, "")


static func fail_test(error_message: String) -> Dictionary:
    ## Manually fail a test
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.fail_test("Expected test to fail")
    return _create_test_result(false, error_message)


static func assert_true(condition: bool, error_message: String) -> Dictionary:
    ## Assert that a condition is true
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_true(a+b >= c, "Expected a+b >= c")
    return _create_test_result(condition, error_message)


static func assert_false(condition: bool, error_message: String) -> Dictionary:
    ## Assert that a condition is false
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_false(a+b == c, "Expected a+b != c")
    return _create_test_result(not condition, error_message)


static func assert_equal(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that two values are equal using the "==" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_equal(a+b, c, "Expected a+b == c")
    return _create_test_result(a == b, error_message)


static func assert_equal_almost(a: Variant, b: Variant, tolerance: float, error_message: String) -> Dictionary:
    ## Assert that two values are approximately equal within a tolerance
    ## Handles numeric types (int, float) and vector types (Vector2, Vector3, Vector4)
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_equal_almost(a+b, c, 0.0001, "Expected a+b == c")

    var result: bool = false

    # Handle numeric types (int, float)
    if a is int or a is float or b is int or b is float:
        result = abs(a - b) <= tolerance

    # Handle Vector2
    elif a is Vector2 and b is Vector2:
        result = a.distance_to(b) <= tolerance

    # Handle Vector3
    elif a is Vector3 and b is Vector3:
        result = a.distance_to(b) <= tolerance

    # Handle Vector4 (if available)
    elif Engine.has_singleton("GodotVersionHint_Vector4") and a is Vector4 and b is Vector4:
        # Vector4 doesn't have distance_to, so we use length of difference
        result = (a - b).length() <= tolerance

    # Fallback for other types that might support subtraction and abs
    else:
        # Try to use the original approach for other numeric-like types
        result = abs(a - b) <= tolerance

    return _create_test_result(result, error_message)


static func assert_not_equal(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that two values are not equal using the "!=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_equal(a+b, c, "Expected a+b != c")
    return _create_test_result(a != b, error_message)


static func assert_greater_than(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that a is greater than b using the ">" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_greater_than(a, b, "Expected a > b")
    return _create_test_result(a > b, error_message)


static func assert_greater_than_or_equal(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that a is greater than or equal to b using the ">=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_greater_than_or_equal(a, b, "Expected a >= b")
    return _create_test_result(a >= b, error_message)


static func assert_less_than(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that a is less than b using the "<" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_less_than(a, b, "Expected a < b")
    return _create_test_result(a < b, error_message)


static func assert_less_than_or_equal(a: Variant, b: Variant, error_message: String) -> Dictionary:
    ## Assert that a is less than or equal to b using the "<=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_less_than_equal(a, b, "Expected a <= b")
    return _create_test_result(a <= b, error_message)


static func assert_null(value: Variant, error_message: String) -> Dictionary:
    ## Assert that a value is null
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_null(some_value, "Expected some_value to be null")
    return _create_test_result(value == null, error_message)


static func assert_not_null(value: Variant, error_message: String) -> Dictionary:
    ## Assert that a value is not null
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_null(some_value, "Expected some_value to not be null")
    return _create_test_result(value != null, error_message)


static func assert_has_method(value: Variant, method_name: String, error_message: String) -> Dictionary:
    ## Assert that a value has a method
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_has_method(some_value, "some_method", "Expected some_value to have some_method")
    return _create_test_result(value.has_method(method_name), error_message)


static func assert_not_has_method(value: Variant, method_name: String, error_message: String) -> Dictionary:
    ## Assert that a value does not have a method
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_has_method(some_value, "some_method", "Expected some_value to not have some_method")
    return _create_test_result(not value.has_method(method_name), error_message)


static func assert_has_property(value: Variant, property_name: String, error_message: String) -> Dictionary:
    ## Assert that a value has a property
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_has_property(some_value, "some_property", "Expected some_value to have some_property")
    return _create_test_result(value.has_property(property_name), error_message)


static func assert_not_has_property(value: Variant, property_name: String, error_message: String) -> Dictionary:
    ## Assert that a value does not have a property
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_has_property(some_value, "some_property", "Expected some_value to not have some_property")
    return _create_test_result(not value.has_property(property_name), error_message)


static func assert_type_name(value: Variant, expected_type_name: String, error_message: String) -> Dictionary:
    ## Assert that a value matches the given type or class name.
    ##
    ## Works for both built-in types (e.g. "int", "Array") and custom classes.
    ##
    ## Rules:
    ## - Built-in types use `type_string(typeof(value))` (e.g. "int", "Array")
    ## - Built-in Objects use `value.get_class()` (e.g. "Node2D", "Button")
    ## - Custom objects with `class_name` use that class name (e.g. "class_name MyCustomClass" → "MyCustomClass")
    ## - Custom objects *without* `class_name`: falls back to the script's file name (e.g. "my_class.gd" → "my_class")
    ## - `null` is treated as "null"
    ##
    ## Example:
    ##     return TestUtils.assert_type_name("abc", "String", "Expected a string")
    ##     return TestUtils.assert_type_name("abc", type_string(TYPE_STRING), "Expected a string") # Equivalent to the above
    ##     return TestUtils.assert_type_name(Node2D.new(), "Node2D", "Expected a Node2D")
    ##     return TestUtils.assert_type_name(MyCustomClass.new(), "MyCustomClass", "Expected custom class")
    ##     return TestUtils.assert_type_name(load("res://my_class.gd").new(), "my_class", "Expected my_class.gd instance")
    ##
    ## Returns a test result dictionary with success or failure.

    var passes: bool = false

    # Handle null explicitly
    if value == null:
        passes = expected_type_name.to_lower() == "null"
        return _create_test_result(passes, error_message + " Expected " + expected_type_name + ", got null")

    # Built-in non-object types
    var t: int = typeof(value)
    if t != TYPE_OBJECT:
        var actual_type_name: String = type_string(t)
        passes = actual_type_name == expected_type_name
        return _create_test_result(passes, error_message + " Expected " + expected_type_name + ", got " + actual_type_name)

    # Objects (built-in or scripted)
    var actual_class: String = value.get_class()

    # Handle custom script objects (with or without class_name)
    if value.get_script() != null:
        var script: Script = value.get_script()
        var resource_path: String = script.resource_path
        var file_name: String = resource_path.get_file().get_basename() if resource_path != "" else ""

        # Prefer class_name if declared
        passes = actual_class == expected_type_name or expected_type_name == file_name or expected_type_name == resource_path
        return _create_test_result(passes, error_message + " Expected " + expected_type_name + ", got " + actual_class)

    # Otherwise (built-in engine objects like Node2D, Button, etc.)
    passes = actual_class == expected_type_name
    return _create_test_result(passes, error_message + " Expected " + expected_type_name + ", got " + actual_class)


# ------------------ Helper functions


static func _create_test_result(test_passed: bool, error_message: String) -> Dictionary:
    ## Helper to create a standardized test result object
    var stack: Array[Dictionary] = get_stack()
    var caller: Dictionary = stack[1] if stack.size() > 1 else {} as Dictionary
    return {
        "status": test_passed,
        "message": "" if test_passed else error_message,
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
