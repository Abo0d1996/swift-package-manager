/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import PackageModel
import SourceControl

extension PackageDependencyDescription {
    /// Create the package reference object for the dependency.
    public func createPackageRef(mirrors: DependencyMirrors) -> PackageReference {
        let effectiveURL = mirrors.effectiveURL(forURL: url)

        // FIXME: The identity of a package dependency is currently based on
        //        on a name computed from the package's effective URL.  This
        //        is because the name of the package that's in the manifest
        //        is not known until the manifest has been parsed.
        //        We should instead use the declared URL of a package dependency
        //        as its identity, as it will be needed for supporting package
        //        registries.
        let identity = PackageIdentity(url: effectiveURL)
        
        return PackageReference(
            identity: identity,
            path: effectiveURL,
            kind: requirement == .localPackage ? .local : .remote
        )
    }
}

extension Manifest {
    /// Constructs constraints of the dependencies in the raw package.
    public func dependencyConstraints(productFilter: ProductFilter, mirrors: DependencyMirrors) -> [PackageContainerConstraint] {
        return dependenciesRequired(for: productFilter).map({
            return PackageContainerConstraint(
                container: $0.createPackageRef(mirrors: mirrors),
                requirement: $0.requirement.toConstraintRequirement(),
                products: $0.productFilter)
        })
    }
}

extension PackageContainerConstraint {
    internal func nodes() -> [DependencyResolutionNode] {
        switch products {
        case .everything:
            return [.root(package: identifier)]
        case .specific:
            switch products {
            case .everything:
                fatalError("Attempted to enumerate a root package’s product filter; root packages have no filter.")
            case .specific(let set):
                if set.isEmpty { // Pointing at the package without a particular product.
                    return [.empty(package: identifier)]
                } else {
                    return set.sorted().map { .product($0, package: identifier) }
                }
            }
        }
    }
}

extension PackageReference {
    /// The repository of the package.
    ///
    /// This should only be accessed when the reference is not local.
    public var repository: RepositorySpecifier {
        precondition(kind == .remote)
        return RepositorySpecifier(url: path)
    }
}
