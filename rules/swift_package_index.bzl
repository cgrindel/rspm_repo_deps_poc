def _swift_package_index_impl(repository_ctx):
    swift_pkg_index = struct(
        inputs = [
            # str(pkg_info)
            str(repository_ctx.path(pkg_info))
            for pkg_info in repository_ctx.attr.pkg_infos
        ],
    )
    repository_ctx.file(
        "swift_pkg_index.json",
        content = json.encode_indent(swift_pkg_index, indent = "  "),
        executable = False,
    )

    repository_ctx.file(
        "BUILD.bazel",
        content = """
exports_files(["swift_pkg_index.json"])
""",
        executable = False,
    )

swift_package_index = repository_rule(
    implementation = _swift_package_index_impl,
    attrs = {
        "pkg_infos": attr.label_list(
            allow_files = [".json"],
            mandatory = True,
        ),
    },
    doc = "",
)
