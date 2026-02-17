load("@rules_python//python:py_test.bzl", "py_test")

py_test(
    name = "compile_test",
    srcs = ["test/compile_test.py"],
    data = glob([
        "identifiers/**/*.csv",
    ]) + ["scripts/compile.py"],
    main = "test/compile_test.py",
)
