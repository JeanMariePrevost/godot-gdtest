## The base class for any test file

extends RefCounted
class_name GDTestCase


## Get the file name of the test file
func get_file_name() -> String:
    return _extract_file_name(get_script().resource_path)


func pass_test() -> GDTestResult:
    ## Manually pass a test
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.pass_test()
    return _create_test_result(true, "")


func fail_test(error_message: String = "") -> GDTestResult:
    ## Manually fail a test
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.fail_test()
    if error_message == "":
        error_message = "Test manually failed"
    return _create_test_result(false, error_message)


func assert_true(condition: bool, error_message: String = "") -> GDTestResult:
    ## Assert that a condition is true
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_true(a+b >= c)
    if error_message == "":
        error_message = "Expected condition to be true"
    return _create_test_result(condition, error_message)


func assert_false(condition: bool, error_message: String = "") -> GDTestResult:
    ## Assert that a condition is false
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_false(a+b == c)
    if error_message == "":
        error_message = "Expected condition to be false"
    return _create_test_result(not condition, error_message)


func assert_equal(expected: Variant, actual: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that two values are equal using the "==" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_equal(a+b, c)
    if error_message == "":
        error_message = "Expected " + str(expected) + ", got " + str(actual)
    return _create_test_result(expected == actual, error_message)


func assert_equal_almost(expected: Variant, actual: Variant, tolerance: float, error_message: String = "") -> GDTestResult:
    ## Assert that two values are approximately equal within a tolerance
    ## Handles numeric types (int, float) and vector types (Vector2, Vector3, Vector4)
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_equal_almost(a+b, c, 0.0001)

    var result: bool = false

    if error_message == "":
        error_message = "Expected " + str(expected) + " (± " + str(tolerance) + "), got " + str(actual)

    # Handle numeric types (int, float)
    if expected is int or expected is float or actual is int or actual is float:
        result = abs(expected - actual) <= tolerance

    # Handle Vector2
    elif expected is Vector2 and actual is Vector2:
        result = expected.distance_to(actual) <= tolerance

    # Handle Vector3
    elif expected is Vector3 and actual is Vector3:
        result = expected.distance_to(actual) <= tolerance

    # Handle Vector4 (if available)
    elif Engine.has_singleton("GodotVersionHint_Vector4") and expected is Vector4 and actual is Vector4:
        # Vector4 doesn't have distance_to, so we use length of difference
        result = (expected - actual).length() <= tolerance

    # Fallback for other types that might support subtraction and abs
    else:
        # Try to use the original approach for other numeric-like types
        result = abs(expected - actual) <= tolerance

    return _create_test_result(result, error_message)


func assert_not_equal(expected: Variant, actual: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that two values are not equal using the "!=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_equal(a+b, c)
    if error_message == "":
        error_message = "Expected a value other than " + str(expected) + ", got " + str(actual)
    return _create_test_result(expected != actual, error_message)


func assert_not_equal_almost(expected: Variant, actual: Variant, tolerance: float = 0.0001, error_message: String = "") -> GDTestResult:
    ## Assert that two values are not approximately equal within a tolerance
    ## Handles numeric types (int, float) and vector types (Vector2, Vector3, Vector4)
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_equal_almost(a+b, c, 0.0001)

    var result: bool = false

    if error_message == "":
        error_message = "Expected a value other than " + str(expected) + " (± " + str(tolerance) + "), got " + str(actual)

    # Handle numeric types (int, float)
    if expected is int or expected is float or actual is int or actual is float:
        result = abs(expected - actual) > tolerance

    # Handle Vector2
    elif expected is Vector2 and actual is Vector2:
        result = expected.distance_to(actual) > tolerance

    # Handle Vector3
    elif expected is Vector3 and actual is Vector3:
        result = expected.distance_to(actual) > tolerance

    # Handle Vector4 (if available)
    elif Engine.has_singleton("GodotVersionHint_Vector4") and expected is Vector4 and actual is Vector4:
        # Vector4 doesn't have distance_to, so we use length of difference
        result = (expected - actual).length() > tolerance

    # Fallback for other types that might support subtraction and abs
    else:
        # Try to use the original approach for other numeric-like types
        result = abs(expected - actual) > tolerance

    return _create_test_result(result, error_message)


func assert_greater_than(a: Variant, b: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a is greater than b using the ">" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_greater_than(a, b)
    if error_message == "":
        error_message = "Expected a value greater than " + str(b) + ", got " + str(a)
    return _create_test_result(a > b, error_message)


func assert_greater_than_or_equal(a: Variant, b: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a is greater than or equal to b using the ">=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_greater_than_or_equal(a, b)
    if error_message == "":
        error_message = "Expected a value greater than or equal to " + str(b) + ", got " + str(a)
    return _create_test_result(a >= b, error_message)


func assert_less_than(a: Variant, b: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a is less than b using the "<" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_less_than(a, b)
    if error_message == "":
        error_message = "Expected a value less than " + str(b) + ", got " + str(a)
    return _create_test_result(a < b, error_message)


func assert_less_than_or_equal(a: Variant, b: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a is less than or equal to b using the "<=" operator
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_less_than_equal(a, b)
    if error_message == "":
        error_message = "Expected a value less than or equal to " + str(b) + ", got " + str(a)
    return _create_test_result(a <= b, error_message)


func assert_null(value: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a value is null
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_null(some_value)
    if error_message == "":
        error_message = "Expected value to be null, got " + str(value)
    return _create_test_result(value == null, error_message)


func assert_not_null(value: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a value is not null
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_null(some_value)
    if error_message == "":
        error_message = "Expected value to not be null"
    return _create_test_result(value != null, error_message)


func assert_has_method(value: Variant, method_name: String, error_message: String = "") -> GDTestResult:
    ## Assert that a value has a method
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_has_method(some_value, "some_method")
    if error_message == "":
        error_message = "Expected value to have method " + method_name
    return _create_test_result(value.has_method(method_name), error_message)


func assert_not_has_method(value: Variant, method_name: String, error_message: String = "") -> GDTestResult:
    ## Assert that a value does not have a method
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_has_method(some_value, "some_method")
    if error_message == "":
        error_message = "Expected value to not have method " + method_name
    return _create_test_result(not value.has_method(method_name), error_message)


func assert_has_property(value: Variant, property_name: String, error_message: String = "") -> GDTestResult:
    ## Assert that a value has a property
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_has_property(some_value, "some_property")
    if error_message == "":
        error_message = "Expected value to have property " + property_name
    return _create_test_result(value.has_property(property_name), error_message)


func assert_not_has_property(value: Variant, property_name: String, error_message: String = "") -> GDTestResult:
    ## Assert that a value does not have a property
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_not_has_property(some_value, "some_property")
    if error_message == "":
        error_message = "Expected value to not have property " + property_name
    return _create_test_result(not value.has_property(property_name), error_message)


func assert_contains(container: Variant, item: Variant, error_message: String = "") -> GDTestResult:
    ## Assert that a collection/object contains an item
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_contains(some_array, item)
    var result := _contains(container, item)
    if error_message == "":
        error_message = "Expected " + str(container) + " to contain " + str(item)
    return _create_test_result(result, error_message)


func assert_not_contains(container: Variant, item: Variant, error_message: String = "") -> GDTestResult:
    var result := _contains(container, item)
    if error_message == "":
        error_message = "Expected " + str(container) + " to not contain " + str(item)
    return _create_test_result(not result, error_message)


func assert_contains_all(container: Variant, items: Array[Variant], error_message: String = "") -> GDTestResult:
    ## Assert that a container contains all items in an array
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_contains_all(some_array, [item1, item2, item3])

    if items == null:
        return _create_test_result(true, "")  # No items to check (null input).
    if items.is_empty():
        return _create_test_result(true, "")  # No items to check (empty array).

    for item in items:
        if not _contains(container, item):
            if error_message == "":
                error_message = "Expected object to contain " + str(item)
            return _create_test_result(false, error_message)

    return _create_test_result(true, "")


func assert_contains_none(container: Variant, items: Array[Variant], error_message: String = "") -> GDTestResult:
    ## Assert that a container does not contain any items in an array
    ## Use at the end of a test by returning the result, e.g.
    ##     return TestUtils.assert_contains_none(some_array, [item1, item2, item3])

    for item in items:
        if _contains(container, item):
            if error_message == "":
                error_message = "Expected object to not contain " + str(item)
            return _create_test_result(false, error_message)
    return _create_test_result(true, "")


func assert_type_name(value: Variant, expected_type_name: String, error_message: String = "") -> GDTestResult:
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

    var passed: bool = false

    if error_message == "":
        error_message = "Expected type name " + expected_type_name + ", got " + type_string(typeof(value))

    # Handle null explicitly
    if value == null:
        passed = expected_type_name.to_lower() == "null"
        return _create_test_result(passed, error_message)

    # Built-in non-object types
    var t: int = typeof(value)
    if t != TYPE_OBJECT:
        var actual_type_name: String = type_string(t)
        passed = actual_type_name == expected_type_name
        return _create_test_result(passed, error_message)

    # Objects (built-in or scripted)
    var actual_class: String = value.get_class()

    # Handle custom script objects (with or without class_name)
    if value.get_script() != null:
        var script: Script = value.get_script()
        var resource_path: String = script.resource_path
        var file_name: String = resource_path.get_file().get_basename() if resource_path != "" else ""

        # Prefer class_name if declared
        passed = actual_class == expected_type_name or expected_type_name == file_name or expected_type_name == resource_path
        return _create_test_result(passed, error_message)

    # Otherwise (built-in engine objects like Node2D, Button, etc.)
    passed = actual_class == expected_type_name
    return _create_test_result(passed, error_message)


# ------------------ Helper functions


## Helper to create a standardized test result object
func _create_test_result(test_passed: bool, error_message: String) -> GDTestResult:
    var caller: Dictionary = find_caller_frame()
    var test_result: GDTestResult = GDTestResult.new(test_passed, error_message, caller.get("function", "<unknown>"), get_file_name(), caller.get("line", 0))
    return test_result


## Find the first non-internal stack frame (outside the test utilities)
## Used to get the file name and line number of the test that failed, where the test actually lives
static func find_caller_frame() -> Dictionary:
    var stack: Array[Dictionary] = get_stack()
    var pattern_of_levels_to_skip: String = "*gdtest/gdtest*"  # "glob", not a regex

    for i in stack.size():
        var frame: Dictionary = stack[i]
        var source: String = frame.get("source", "")
        var is_internal := false
        if source.match(pattern_of_levels_to_skip):
            is_internal = true
        if not is_internal:
            return frame

    # fallback if nothing found
    return stack[0] if stack.size() > 0 else {}


## Extract the file name portion from a path
func _extract_file_name(path: String) -> String:
    if path == "<unknown>":
        return path
    return path.get_file()


## Helper to check if any common collection type contains an item
## Works for arrays, dictionaries, strings, and objects that implement a "has" method
func _contains(container: Variant, item: Variant) -> bool:
    if container == null:
        return false

    match typeof(container):
        TYPE_ARRAY:
            return item in container
        TYPE_DICTIONARY:
            return container.has(item)
        TYPE_STRING:
            return str(item) in container
        TYPE_OBJECT:
            if container.has_method("has"):
                return container.has(item)
            return false
        _:
            return false
