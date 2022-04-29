class FactoryProvider<Value>: Provider {
    typealias Provided = Value
    let factory: FactoryClosure<Value>
    let requirements: [String: TypeID]

    init(
        requirements: [String: TypeID],
        factory: @escaping FactoryClosure<Value>
    ) {
        self.requirements = requirements
        self.factory = factory
    }

    func resolve(provider: DependencyResolver) throws -> Provided {
        return try factory(provider)
    }
}
