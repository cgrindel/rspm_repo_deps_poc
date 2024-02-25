# Proposal: How to Remove Swift Index JSON File

As mentioned in #924, we want to minimize the files that are checked into source control when using
`rules_swift_package_manager`. The goal is to only require the `Package.swift` and the
`Package.resolved` files eliminating the need for the `swift_deps_index.json`. This document
proposes how we should achieve this.

## Background

The current iteration of the `swift_deps_index.json` file contains a number of useful items. However, for the purposes of this discussion, we will focus on the mapping of target dependencies to Bazel targets.

Swift Package Manger (SPM) is very lax in what is required to specify a dependency for an SPM target. Specifically, it supports [byName](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#target-dependency) lookups. The name can be a target or a product in the current package or any of its package dependencies. Hence, to resolve a `byName` target dependency, one must know all of the products in all of the packages that are direct dependencies of the current package.

This last point is important. We cannot generate a `BUILD.bazel` file for a Swift package without having downloaded and processed all of the Swift packages that are directly associated with the Swift package. Hence, we need to download all of the Swift package transitive dependencies for an `rules_swift_package_manager` project BEFORE generating the Bazel repository/repositories for those packages.

## Proposed Solution

_tl;dr Create a single Bazel repository that downloads the SPM packages and exposes their Bazel targets._

### Client Usage

A client will add the following to their `MODULE.bazel`.

```starlark
bazel_dep(
    name = "rules_swift_package_manager",
    version = "0.0.0",
)
swift_deps = use_extension(
    "@rules_swift_package_manager//:extensions.bzl",
    "swift_deps",
)

# Behind the scenes, this will call `swift_packages` passing along the `Package.swift` and
# `Package.resolved` labels.
swift_deps.from_package(
    resolved = "//:Package.resolved",
    swift = "//:Package.swift",
)

# Declare the Bazel repo that will contain all of the Swift packages.
use_repo(swift_deps, "swiftpkgs")
```

Alternatively, if they are using the legacy dependency mechanism, they will specify the following in their `WORKSPACE` file:

```starlark
load("@rules_swift_package_manager//swiftpkg:defs.bzl", "swift_packages")

swift_packages(
    name = "swiftpkgs",
    package_swift = "//:Package.swift",
    package_resolved = "//:Package.resolved",
)
```

### Implementation

The `swift_packages` repository rule will create a subdirectory for each Swift package (remote and local) that is specified in the `Package.swift`. Remote Swift packages will be cloned (git) into their directory using the `git_repo` function in `@bazel_tools//tools/build_defs/repo:git_worker.bzl`. The local Swift package directories will be populated with symlinks to the top-level files and directories of the original code (see the current implementation of `local_swift_package` for more details).

For each Swift package, we will generate the dump (`swift package dump-package`) and description JSON (`swift package describe --type json`) files. These will be combined into a `pkg_info.json` (see `pkginfos.get()` for implementation details).

Next, the `pkg_info.json` files for each Swift package will be combined to create a map of product name to a list of fully-qualified package-product references (e.g. `{"identity": "...", "product_name": "..."}`. This map will be serialized to a file called `spm_products.json` at the root of the `swiftpkgs` repository.

Finally, a `BUILD.bazel` file will be generated for each Swift package using the information from its `pkg_info.json` and the `spm_products.json`.

#### Bazel Label Formats

An SPM product will have a Bazel label with the following format:

```
@<repo_name>//<package_identity>:<product_name>
```

- `repo_name`: The name of the `swift_packages` repository.
- `package_identity`: The Swift package identity/name.
- `product_name`: The Swift product name.

An SPM target will have a Bazel label with the following format:

```
@<repo_name>//<package_identity>:<target_name>.rspm
```

- `repo_name`: The name of the `swift_packages` repository.
- `package_identity`: The Swift package identity/name.
- `target_name`: The Swift target name.

### Proof of Concept

You can see a POC of this scheme at https://github.com/cgrindel/rspm_repo_deps_poc/tree/all_pkgs_in_single_repo.

### Gazelle Plugin

We will update the Gazelle plugin to read the `spm_products.json` to aid in the resolution of Swift modules to Bazel labels.

### Miscellaneous

#### This Pattern Looks Familiar

The predecessor to `rules_swift_package_manager`, [rules_spm](https://github.com/cgrindel/rules_spm), used a similar scheme, storing all of the Swift packages in a single Bazel repository. However, the implementation details were very different.

#### Support for Declaring Swift Packages in `MODULE.bazel`

You may notice in [the POC](https://github.com/cgrindel/rspm_repo_deps_poc/tree/all_pkgs_in_single_repo) a tag class called `swift_package`. I implemented this as quick way to implement the POC. In theory, one could forgo specifying `swift_deps.from_package()` and instead specify all of the transitive dependencies using a sytnax like the following:

```starlark
swift_deps.swift_package(
    commit = "c8ed701b513cf5177118a175d85fbbbcd707ab41",
    identity = "swift-argument-parser",
    remote = "https://github.com/apple/swift-argument-parser",
)
```

If folks want this, we can add it. However, the plan is not to include it in the first implementation.

#### Support SPM Package Dependency API - NOT RECOMMENDED

In theory, we could even support a syntax that mimics [the API surface of SPM package dependencies](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#package-dependency). However, this would require `rules_swift_package_manager` to execute `swift package resolve` underneath the covers. This would cause the transitive dependencies to be downloaded twice. Once for the resolve action and again for the Bazel repository. Of course, we could try to use the source files from the resolve step in the Bazel repository.

I highly recommend that we do not pursue this. It will encourage unreproducible builds as the resolution would occur every time the build was run.

## Rejected Alternatives

### Three Tiers of Bazel Repositories

https://github.com/cgrindel/rspm_repo_deps_poc/tree/separate_download_and_build_repos

I spent some time trying an alternative where each Swift package was downloaded in one Bazel repository, indexed in another, and built in a third. This did not work as the labels that feed data to the downstream repositories do not resolve.

### Two Tiers of Bazel Repositories

Another scheme that was considered was to create a single Bazel repository to download and index all of the Swift packages and then create a separate Bazel repository for each Swift package that would contain symlinks to the downloaded code and a `BUILD.bazel` file with the actual build targets.

I could not think of a good reason to add this complexity other than it separates the Swift packages into their own Bazel repository...sort of.
