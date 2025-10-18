extends GDTestCase


func test_basic_addition() -> GDTestResult:
    return assert_equal(1 + 1, 2)


func test_basic_addition_with_custom_message() -> GDTestResult:
    var result: int = 1 + 1
    return assert_equal(result, 2, "1+1 should be 2, but we got " + str(result))


func test_async_example() -> GDTestResult:
    var dummy_node: Node = Node.new()

    Engine.get_main_loop().root.add_child(dummy_node)

    # Example of waiting for a frame to pass
    await Engine.get_main_loop().process_frame

    # Example of waiting for a set amount of time
    # Note that these a blocking operations and that the test runner runs on a single thread/process
    # So await statements will block the test runner from running other tests until they complete
    await Engine.get_main_loop().create_timer(0.1).timeout

    return assert_not_null(dummy_node.get_parent(), "Node should have a parent by now")


func test_with_manually_handled_fail_pass() -> GDTestResult:
    var dummy_node: Node = Node.new()

    if dummy_node == null or not is_instance_valid(dummy_node):
        return fail_test("Expected node to be valid after creation")

    dummy_node.free()

    if is_instance_valid(dummy_node):
        return fail_test("Expected node to no longer be valid after calling free()")

    return pass_test()
