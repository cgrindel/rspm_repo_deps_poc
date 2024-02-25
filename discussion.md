# How to remove Swift index JSON file

As mentioned in #924, we want to minimize the files that are checked into source control when using
`rules_swift_package_manager`. The goal is to only require the `Package.swift` and the
`Package.resolved` files eliminating the need for the `swift_deps_index.json`. This document
proposes how we should achieve this.

## Background

The current iteration of the `swift_deps_index.json` file contains a number of useful items.
However, for the purposes of this discussion, we will focus on the mapping of target dependencies to
Bazel targets.

Swift Package Manger (SPM) is very lax in what is required to specify a dependency for an SPM
target. Specifically, it supports
[byName](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#target-dependency)
lookups. The name can be a target or a product in the current package or any of its package
dependencies. Hence, to resolve a `byName` target dependency, one must know all of the products in
all of the packages that are direct dependencies of the current package.

This last point is important. We cannot generate a `BUILD.bazel` file for a Swift package without
having downloaded all of the Swift packages that are directly associated with the Swift package.
Hence, we need to download all of the transitive dependencies BEFORE the
