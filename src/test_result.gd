## Class to store the result of a test

extends RefCounted
class_name TestResult

var passed: bool
var error_message: String
var function_name: String
var file_name: String
var line_number: int


func _init(_passed: bool, _error_message: String, _function_name: String, _file_name: String, _line_number: int):
    self.passed = _passed
    self.error_message = _error_message
    self.function_name = _function_name
    self.file_name = _file_name
    self.line_number = _line_number


func _to_string() -> String:
    return (
        "TestResult(passed="
        + str(passed)
        + ", error_message="
        + error_message
        + ", function_name="
        + function_name
        + ", file_name="
        + file_name
        + ", line_number="
        + str(line_number)
        + ")"
    )
