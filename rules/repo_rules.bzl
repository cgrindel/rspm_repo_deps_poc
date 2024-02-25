"""Module containing shared definitions and functions for repository rules."""

load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")

_swift_attrs = {
    "bazel_package_name": attr.string(
        doc = "The short name for the Swift package's Bazel repository.",
    ),
    "dependencies_index": attr.label(
        doc = """\
A JSON file that contains a mapping of Swift products and Swift modules.\
""",
    ),
}

_env_attrs = {
    "env": attr.string_dict(
        doc = """\
Environment variables that will be passed to the execution environments for \
this repository rule. (e.g. SPM version check, SPM dependency resolution, SPM \
package description generation)\
""",
    ),
}

_DEVELOPER_DIR_ENV = "DEVELOPER_DIR"

def _get_exec_env(repository_ctx):
    """Creates a `dict` of environment variables which will be past to all execution environments for this rule.

    Args:
        repository_ctx: A `repository_ctx` instance.

    Returns:
        A `dict` of environment variables which will be used for execution environments for this rule.
    """

    # If the DEVELOPER_DIR is specified in the environment, it will override
    # the value which may be specified in the env attribute.
    env = dicts.add(repository_ctx.attr.env)
    dev_dir = repository_ctx.os.environ.get(_DEVELOPER_DIR_ENV)
    if dev_dir:
        env[_DEVELOPER_DIR_ENV] = dev_dir
    return env

def _write_workspace_file(repository_ctx, repoDir):
    path = paths.join(repoDir, "WORKSPACE")
    repo_name = repository_ctx.name
    content = """\
workspace(name = "{}")
""".format(repo_name)
    repository_ctx.file(path, content = content, executable = False)

repo_rules = struct(
    env_attrs = _env_attrs,
    get_exec_env = _get_exec_env,
    swift_attrs = _swift_attrs,
    write_workspace_file = _write_workspace_file,
)
