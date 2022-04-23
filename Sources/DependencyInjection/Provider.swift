protocol _AnyProvider {
    func resolveAny(provider: DependencyResolver) throws -> Any
}

protocol Provider: _AnyProvider {
    associatedtype Provided

    func resolve(provider: DependencyResolver) throws -> Provided
}

extension Provider {
    func resolveAny(provider: DependencyResolver) throws -> Any {
        return try resolve(provider: provider)
    }
}