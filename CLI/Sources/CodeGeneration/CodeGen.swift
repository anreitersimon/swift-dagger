import DependencyModel
import Foundation
import SourceModel
import StoreKit

extension String {

    /// Returns a form of the string that is a valid bundle identifier
    public func swiftIdentifier() -> String {
        return self.filter { $0.isNumber || $0.isLetter }
    }
}

// TODO: Dont duplicate
extension Function.Argument {

    public var isInjected: Bool {
        !Constants.injectAnnotations.intersection(attributes).isEmpty
    }

    public var isAssisted: Bool {
        !Constants.assistedAnnotations.intersection(attributes).isEmpty
    }
}

extension Initializer {
    public var isAssisted: Bool {
        return arguments.contains(where: \.isAssisted)
    }
}

public enum CodeGen {

    static let header = "// Automatically generated DO NOT MODIFY"

    public static func generateSources(
        moduleGraph graph: ModuleDependencyGraph
    ) -> String {

        let writer = FileWriter()

        writer.writeMultiline(
            """
            \(header)

            import DependencyInjection
            """
        )
        for module in graph.modules {
            writer.writeLine("import \(module)")
        }

        writer.scope("public enum \(graph.module)_Module: DependencyInjection.DependencyModule") {

            $0.writeLine("public static let submodules: [DependencyModule.Type] = [")
            $0.indent {
                for module in graph.modules {
                    $0.writeLine("\(module)_Module.self,")
                }
            }
            $0.writeLine("]")

            $0.scope("public static func register(in registry: DependencyRegistry)") {
                for file in graph.files {
                    let fileName = file.deletingPathExtension().lastPathComponent.swiftIdentifier()
                    $0.writeLine("register_\(fileName)(in: registry)")
                }
            }

        }

        return writer.builder
    }

    public static func generateSources(
        fileGraph graph: FileDependencyGraph
    ) -> String {

        let writer = FileWriter()

        writer.writeLine(header)
        writer.endLine()

        for imp in graph.imports {
            writer.writeLine(imp.description)
        }

        if !graph.imports.contains(where: { $0.path == "DependencyInjection" }) {
            writer.write("import DependencyInjection")
        }

        writer.endLine()

        writer.writeLine("// MARK: - File Extension -")

        writer.scope("extension \(graph.module)_Module") {
            $0.scope(
                "static func register_\(graph.fileName.swiftIdentifier())(in registry: DependencyRegistry)"
            ) {

                for provided in graph.provides
                where !provided.initializer.arguments.contains(where: \.isAssisted) {
                    $0.writeLine("\(provided.fullName).register(in: registry)")
                }

                for binding in graph.bindings {
                    $0.writeLine(
                        "register_Binding_\(binding.type.description.swiftIdentifier())(in: registry)"
                    )
                }
            }
        }

        writer.writeLine("// User defined Binding extensions")
        writer.endLine()

        writer.scope("extension \(graph.module)_Module") {
            for binding in graph.bindings {

                generateCustomBinding(in: $0, binding: binding)

            }
        }

        writer.writeLine("// Provied Types")
        writer.endLine()

        for provided in graph.provides {
            writer.scope("extension \(provided.fullName)") {
                generateRegistration(in: $0, injectable: provided)
                generateTypeFactory(in: $0, injectable: provided)
            }
        }

        writer.endLine()

        return writer.builder
    }

    private static func generateCustomBinding(
        in writer: FileWriter,
        binding: BoundType
    ) {

        writer.scope(
            "fileprivate static func register_Binding_\(binding.type.description.swiftIdentifier())(in registry: DependencyRegistry)"
        ) {
            generateRequirementsVariable(
                in: $0,
                arguments: binding.factoryMethod.arguments
            )

            let methodName: String
            let extendedScope: String

            switch binding.kind {
            case .factory:
                methodName = "registerFactory"
                extendedScope = "Dependencies.Factories"
            case .singleton:
                methodName = "registerSingleton"
                extendedScope = "Dependencies.Singletons"
            case .weakSingleton:
                methodName = "registerWeakSingleton"
                extendedScope = "Dependencies.WeakSingletons"
            }

            let typeName = binding.type.asMetatype()

            if typeName == nil {
                $0.writeLine("#error(\"No Metatype\")")
            }

            $0.writeMultiline(
                """
                registry.\(methodName)(
                    ofType: \(typeName ?? "Never.self"),
                    in: \(binding.scope.asMetatype() ?? "Never.self"),
                    requirements: requirements
                ) { resolver in
                """
            )
            $0.indent {
                $0.write("\(extendedScope).bind")
                $0.writeCallArguments(binding.factoryMethod.arguments) { _ in
                    "resolver.resolve()"
                }
                $0.endLine()
            }
            $0.writeLine("}")

        }
    }

    private static func generateRegistration(
        in writer: FileWriter,
        injectable: ProvidedType
    ) {
        writer.scope("fileprivate static func register(in registry: DependencyRegistry)") {
            generateRequirementsVariable(
                in: $0,
                arguments: injectable.initializer.arguments.filter(\.isInjected)
            )

            switch injectable.kind {
            case .factory where injectable.initializer.isAssisted:
                $0.writeMultiline(
                    """
                    registry.registerAssistedFactory(
                        ofType: \(injectable.fullName).self,
                        in: \(injectable.fullName).Scope.self,
                        requirements: requirements
                    )
                    """
                )
            case .factory, .singleton, .weakSingleton:
                let methodName: String

                switch injectable.kind {
                case .factory:
                    methodName = "registerFactory"
                case .singleton:
                    methodName = "registerSingleton"
                case .weakSingleton:
                    methodName = "registerWeakSingleton"
                }

                $0.writeMultiline(
                    """
                    registry.\(methodName)(
                        ofType: \(injectable.fullName).self,
                        in: \(injectable.fullName).Scope.self,
                        requirements: requirements
                    ) { resolver in
                        \(injectable.fullName).newInstance(resolver: resolver)
                    }
                    """
                )
            }

        }
    }

    private static func generateTypeFactory(
        in writer: FileWriter,
        injectable: ProvidedType
    ) {
        let allArguments = injectable.initializer.arguments
            .filter { $0.isAssisted || $0.isInjected }
        let assisted = allArguments.filter(\.isAssisted)

        writer.writeLine("public static func newInstance(")
        writer.indent {
            $0.write("resolver: DependencyResolver = Dependencies.sharedResolver")

            for argument in assisted {
                $0.write(",")
                $0.endLine()
                $0.write(argument.description)
            }
        }
        writer.endLine()
        writer.scope(") -> \(injectable.fullName)") {
            $0.write("\(injectable.fullName)")
            $0.writeCallArguments(allArguments.filter { $0.isInjected || $0.isAssisted }) {
                $0.isInjected ? "resolver.resolve()" : nil
            }
        }

    }

    private static func generateRequirementsVariable(
        in writer: FileWriter,
        arguments: [Function.Argument]
    ) {
        writer.write("let requirements: [String: Any.Type] = [")

        guard !arguments.isEmpty else {
            writer.write(":]")
            writer.endLine()
            writer.endLine()
            return
        }
        writer.endLine()

        writer.indent {
            for field in arguments {
                if let metaType = field.type?.asMetatype() {
                    $0.writeLine("\"\(field.firstName ?? field.secondName ?? "-")\": \(metaType),")
                }
            }
        }
        writer.writeLine("]")
        writer.endLine()
    }
}

extension FileWriter {

    func writeCallArguments(
        _ arguments: [Function.Argument],
        valueProvider: (Function.Argument) -> String?
    ) {
        self.write("(")
        self.indent {

            var isFirst = true

            for argument in arguments {

                if !isFirst {
                    $0.write(",")
                }
                $0.endLine()

                if let argName = argument.callSiteName {
                    $0.write(argName)
                    $0.write(": ")
                }

                if let custom = valueProvider(argument) {
                    $0.write(custom)
                } else if argument.isAssisted {
                    let internalName = argument.secondName ?? argument.firstName

                    assert(internalName != nil, "argument must at least have internal name")

                    $0.write(internalName!)
                }
                isFirst = false
            }
        }

        if !arguments.isEmpty {
            endLine()
        }

        self.write(")")
    }

}