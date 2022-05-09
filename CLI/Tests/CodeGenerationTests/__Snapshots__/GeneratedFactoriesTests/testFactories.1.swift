// Automatically generated DO NOT MODIFY

import TestModule
import DependencyInjection
// MARK: - File Extension -
extension Mock_Module {
    static func register_MockFile(in registry: DependencyRegistry) {

        // Scopes
        registerScope(CustomScope.self)

        // Types
        Mock.ExplicitelyInitialized.register(in: registry)
        Mock.ExplicitelyInitialized.Nested.register(in: registry)

        // Bindings
        register_Binding_Protocol(in: registry)
        register_Binding_Protocol(in: registry)

        // Container Extensions
        extension DependencyContainer where Accessing_GlobalScope {
            internal func explicitelyInitialized() -> ExplicitelyInitialized {
                resolve()
            }
        }
        extension DependencyContainer where Accessing_GlobalScope {
            internal func nested() -> Nested {
                resolve()
            }
        }
        extension DependencyContainer where Accessing_GlobalScope {
            internal func implicitInitializer(,
            b: Int
            ) -> ImplicitInitializer {
                ImplicitInitializer.newInstance(
                    resolver: self,
                    b: b
                )
            }
        }
        extension DependencyContainer where Accessing_CustomScope {
            internal func protocol() -> Protocol {
                resolve()
            }
        }
        extension DependencyContainer where Accessing_GlobalScope {
            internal func protocol() -> Protocol {
                resolve()
            }
        }
    }
}
public protocol Accessing_CustomScope: Accessing_GlobalScope {}
// User defined Binding extensions

extension Mock_Module {
    fileprivate static func register_Binding_Protocol(in registry: DependencyRegistry) {
        let requirements: [String: Any.Type] = [
            "a": ImplicitInitializer.self,
        ]

        registry.registerFactory(
            ofType: Protocol.self,
            in: CustomScope.self,
            requirements: requirements
        ) { resolver in
            Dependencies.Factories.bind(
                a: resolver.resolve()
            )
        }
    }
    fileprivate static func register_Binding_Protocol(in registry: DependencyRegistry) {
        let requirements: [String: Any.Type] = [
            "a": ImplicitInitializer.self,
        ]

        registry.registerFactory(
            ofType: Protocol.self,
            in: GlobalScope.self,
            requirements: requirements
        ) { resolver in
            Dependencies.Factories.bind(
                a: resolver.resolve()
            )
        }
    }
}
// Provided Types

extension Mock.ExplicitelyInitialized {
    fileprivate static func register(in registry: DependencyRegistry) {
        let requirements: [String: Any.Type] = [
            "a": I.self,
        ]

        registry.registerFactory(
            ofType: Mock.ExplicitelyInitialized.self,
            in: Mock.ExplicitelyInitialized.Scope.self,
            requirements: requirements
        ) { resolver in
            Mock.ExplicitelyInitialized.newInstance(resolver: resolver)
        }
    }
    fileprivate static func newInstance(
        resolver: DependencyResolver = Dependencies.sharedResolver
    ) -> Mock.ExplicitelyInitialized {
        Mock.ExplicitelyInitialized(
            a: resolver.resolve()
        )
    }
}
extension Mock.ExplicitelyInitialized.Nested {
    fileprivate static func register(in registry: DependencyRegistry) {
        let requirements: [String: Any.Type] = [:]

        registry.registerFactory(
            ofType: Mock.ExplicitelyInitialized.Nested.self,
            in: Mock.ExplicitelyInitialized.Nested.Scope.self,
            requirements: requirements
        ) { resolver in
            Mock.ExplicitelyInitialized.Nested.newInstance(resolver: resolver)
        }
    }
    fileprivate static func newInstance(
        resolver: DependencyResolver = Dependencies.sharedResolver
    ) -> Mock.ExplicitelyInitialized.Nested {
        Mock.ExplicitelyInitialized.Nested()
    }
}
extension Mock.ImplicitInitializer {
    fileprivate static func register(in registry: DependencyRegistry) {
        let requirements: [String: Any.Type] = [
            "a": I.self,
        ]

        registry.registerAssistedFactory(
            ofType: Mock.ImplicitInitializer.self,
            in: Mock.ImplicitInitializer.Scope.self,
            requirements: requirements
        )
    }
    fileprivate static func newInstance(
        resolver: DependencyResolver = Dependencies.sharedResolver,
        b: Int
    ) -> Mock.ImplicitInitializer {
        Mock.ImplicitInitializer(
            a: resolver.resolve(),
            b: b
        )
    }
}

