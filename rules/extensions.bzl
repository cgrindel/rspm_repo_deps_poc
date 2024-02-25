load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":repo_attrs.bzl", "repo_attrs")
load(":swift_packages.bzl", "swift_packages")
load(":swift_pkgs.bzl", "swift_pkgs")

def _swift_deps_impl(module_ctx):
    packages = []
    for mod in module_ctx.modules:
        for swift_pkg in mod.tags.swift_package:
            packages.append(
                swift_pkgs.new_remote_from_tag_class(swift_pkg),
            )

    swift_packages(
        name = "swiftpkgs",
        packages = [
            json.encode_indent(pkg, indent = "  ")
            for pkg in packages
        ],
    )

_swift_package_tag = tag_class(
    attrs = dicts.add({
        # This is a hack for now. The identity will be derived from the remote.
        "identity": attr.string(mandatory = True),
    }, repo_attrs.remote),
)

swift_deps = module_extension(
    implementation = _swift_deps_impl,
    tag_classes = {
        "swift_package": _swift_package_tag,
    },
)
