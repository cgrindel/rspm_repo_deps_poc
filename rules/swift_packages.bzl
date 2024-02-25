load(":swift_pkgs.bzl", "swift_pkgs")

def _swift_packages_impl(repository_ctx):
    packages = [
        swift_pkgs.new_remote_from_json(pkg_json)
        for pkg_json in repository_ctx.attr.packages
    ]
    repository_ctx.file(
        "packages.json",
        content = json.encode_indent(packages, indent = "  "),
        executable = False,
    )

    repository_ctx.file(
        "BUILD.bazel",
        content = """\
exports_files(["packages.json"])
""",
        executable = False,
    )

swift_packages = repository_rule(
    implementation = _swift_packages_impl,
    attrs = {
        "packages": attr.string_list(
            mandatory = True,
            allow_empty = False,
            doc = "List of JSON strings for structs returned by `swift_pkgs.new_remote()`.",
        ),
    },
    doc = "",
)
