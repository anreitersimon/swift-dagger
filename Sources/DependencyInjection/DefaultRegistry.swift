class DependencyGraph {

    fileprivate var scopeToGraph: [ScopeID: ScopeGraph] = [:]

    func providers<Scope: DependencyScope>(for scope: Scope.Type) -> [TypeID: _AnyProvider] {
        return self.scopeToGraph[ScopeID(scope)]?.declarations.mapValues {
            $0.makeProvider()
        } ?? [:]
    }

    class ScopeGraph {

        init(parent: ScopeGraph?) {
            self.parent = parent
        }

        let parent: ScopeGraph?
        private(set) var keys: [TypeID] = []
        fileprivate var declarations: [TypeID: DependencyDeclaration] = [:]

        subscript(_ key: TypeID) -> DependencyDeclaration? {
            return declarations[key]
        }

        func addProvider(_ declaration: DependencyDeclaration, for key: TypeID) {
            keys.append(key)
            declarations[key] = declaration
        }
    }

    func addProvider<Scope: DependencyScope>(
        _ declaration: DependencyDeclaration,
        in scope: Scope.Type,
        for key: TypeID
    ) {
        self.registerScope(scope)

        scopeToGraph[ScopeID(scope)]!.addProvider(declaration, for: key)
    }

    @discardableResult
    private func registerScope<Scope: DependencyScope>(_ scope: Scope.Type) -> ScopeGraph {

        let id = ScopeID(Scope.self)

        if let graph = scopeToGraph[id] {
            return graph
        }

        let parent: ScopeGraph?

        if Scope.Parent.self == Never.self {
            parent = nil
        } else {
            parent = registerScope(Scope.Parent.self)
        }

        let graph = ScopeGraph(parent: parent)

        scopeToGraph[id] = graph

        return graph
    }

}

class DefaultRegistry: DependencyRegistry {
    private var isSetupFinished: Bool = false

    private let graph: DependencyGraph = DependencyGraph()

    private var registeredModules: Set<ObjectIdentifier> = []

    private(set) var container: DependencyContainer<GlobalScope>!

    private func registerModule(_ module: DependencyModule.Type) {
        if registeredModules.insert(ObjectIdentifier(module)).inserted {
            module.register(in: self)
        }

        for subModule in module.submodules {
            registerModule(subModule)
        }
    }

    func setup(_ modules: DependencyModule.Type...) throws {

        for module in modules {
            self.registerModule(module)
        }
        isSetupFinished = true

        let dotPrinter = DotGraphPrinter(graph: graph)
        try dotPrinter.run()

        print(dotPrinter.dotGraph)

        container = DependencyContainer(
            graph: self.graph,
            scope: GlobalScope(),
            parent: nil
        )
        
        print(graph.scopeToGraph)
        //try validator.run()
    }

    func registerSingleton<Value, Scope: DependencyScope>(
        ofType type: Value.Type,
        in scope: Scope.Type,
        requirements: [String: Any.Type],
        create: @escaping FactoryClosure<Value>
    ) {
        register(
            as: type,
            in: scope,
            provider: SingletonProvider<Value>(
                requirements: requirements.mapValues(TypeID.init),
                factory: create
            )
        )
    }

    func registerWeakSingleton<Value: AnyObject, Scope: DependencyScope>(
        ofType type: Value.Type,
        in scope: Scope.Type,
        requirements: [String: Any.Type],
        create: @escaping FactoryClosure<Value>
    ) {
        register(
            as: type,
            in: scope,
            provider: WeakSingletonProvider<Value>(
                requirements: requirements.mapValues(TypeID.init),
                factory: create
            )
        )
    }

    func registerFactory<Value, Scope: DependencyScope>(
        ofType type: Value.Type,
        in scope: Scope.Type,
        requirements: [String: Any.Type],
        create: @escaping FactoryClosure<Value>
    ) {
        register(
            as: type,
            in: scope,
            provider: FactoryProvider<Value>(
                requirements: requirements.mapValues(TypeID.init),
                factory: create
            )
        )
    }

    func registerAssistedFactory<Value, Scope: DependencyScope>(
        ofType type: Value.Type,
        in scope: Scope.Type,
        requirements: [String: Any.Type]
    ) {
        register(
            as: type,
            in: scope,
            provider: AssistedFactory<Value>(
                requirements: requirements.mapValues(TypeID.init)
            )
        )
    }

    private func register<Value, Scope: DependencyScope>(
        as type: Value.Type,
        in scope: Scope.Type,
        provider: DependencyDeclaration
    ) {
        assert(!isSetupFinished)

        graph.addProvider(provider, in: scope, for: TypeID(type))

    }

}
