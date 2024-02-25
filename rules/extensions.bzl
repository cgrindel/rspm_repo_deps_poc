load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":swift_package_download.bzl", "ALL_ATTRS", "swift_package_download")

def _swift_deps_impl(module_ctx):
    for mod in module_ctx.modules:
        for swift_pkg in mod.tags.swift_package:
            _declare_swift_package(swift_pkg)

def _repo_name_from_identity(identity, repo_type):
    return "swiftpkg_{clean_id}_{type}".format(
        clean_id = identity.replace("-", "_"),
        type = repo_type,
    )

def _declare_swift_package(swift_pkg):
    swift_package_download(
        name = _repo_name_from_identity(
            identity = swift_pkg.identity,
            repo_type = "download",
        ),
        branch = swift_pkg.branch,
        commit = swift_pkg.commit,
        init_submodules = swift_pkg.init_submodules,
        recursive_init_submodules = swift_pkg.recursive_init_submodules,
        remote = swift_pkg.remote,
        shallow_since = swift_pkg.shallow_since,
        tag = swift_pkg.tag,
        verbose = swift_pkg.verbose,
        patch_args = swift_pkg.patch_args,
        patch_cmds = swift_pkg.patch_cmds,
        patch_cmds_win = swift_pkg.patch_cmds_win,
        patch_tool = swift_pkg.patch_tool,
        patches = swift_pkg.patches,
    )

_swift_package_tag = tag_class(
    attrs = dicts.add({
        # This is a hack for now. The identity will be dereived from the remote.
        "identity": attr.string(mandatory = True),
    }, ALL_ATTRS),
)

swift_deps = module_extension(
    implementation = _swift_deps_impl,
    tag_classes = {
        "swift_package": _swift_package_tag,
    },
)
