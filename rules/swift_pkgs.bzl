def _new_remote(
        identity,
        commit,
        remote,
        init_submodules = False,
        recursive_init_submodules = False,
        shallow_since = None,
        tag = None,
        verbose = False,
        patch_args = None,
        patch_cmds = None,
        patch_cmds_win = None,
        patch_tool = None,
        patches = None):
    return struct(
        identity = identity,
        commit = commit,
        remote = remote,
        init_submodules = init_submodules,
        recursive_init_submodules = recursive_init_submodules,
        shallow_since = shallow_since,
        tag = tag,
        verbose = verbose,
        patch_args = patch_args,
        patch_cmds = patch_cmds,
        patch_cmds_win = patch_cmds_win,
        patch_tool = patch_tool,
        patches = patches,
    )

def _new_remote_from_tag_class(tag_class):
    return _new_remote(
        tag_class.identity,
        commit = tag_class.commit,
        remote = tag_class.remote,
        init_submodules = tag_class.init_submodules,
        recursive_init_submodules = tag_class.recursive_init_submodules,
        shallow_since = tag_class.shallow_since,
        tag = tag_class.tag,
        verbose = tag_class.verbose,
        patch_args = tag_class.patch_args,
        patch_cmds = tag_class.patch_cmds,
        patch_cmds_win = tag_class.patch_cmds_win,
        patch_tool = tag_class.patch_tool,
        patches = tag_class.patches,
    )

def _new_remote_from_json(json_str):
    remote_dict = json.decode(json_str)
    return _new_remote(**remote_dict)

swift_pkgs = struct(
    new_remote = _new_remote,
    new_remote_from_json = _new_remote_from_json,
    new_remote_from_tag_class = _new_remote_from_tag_class,
)
