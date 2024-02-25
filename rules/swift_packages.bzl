load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_tools//tools/build_defs/repo:git_worker.bzl", "git_repo")
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

    # Clone the packages
    repo_directory = str(repository_ctx.path("."))
    for swift_pkg in packages:
        _clone_or_update_repo(repository_ctx, repo_directory, swift_pkg)

    repository_ctx.file(
        "BUILD.bazel",
        content = """\
exports_files(["packages.json"])
""",
        executable = False,
    )

def _clone_or_update_repo(repository_ctx, repo_directory, swift_pkg):
    fake_ctx = struct(
        delete = repository_ctx.delete,
        path = repository_ctx.path,
        report_progress = repository_ctx.report_progress,
        execute = repository_ctx.execute,
        os = repository_ctx.os,
        attr = struct(
            commit = swift_pkg.commit,
            remote = swift_pkg.remote,
            init_submodules = swift_pkg.init_submodules,
            recursive_init_submodules = swift_pkg.recursive_init_submodules,
            shallow_since = swift_pkg.shallow_since,
            tag = swift_pkg.tag,
            verbose = swift_pkg.verbose,
            branch = None,
        ),
    )
    pkg_directory = paths.join(repo_directory, swift_pkg.identity)
    git_repo(fake_ctx, pkg_directory)

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
