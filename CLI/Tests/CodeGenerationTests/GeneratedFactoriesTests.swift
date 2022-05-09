import CodeGeneration
import SnapshotTesting
import TestHelpers
import XCTest

@testable import DependencyModel
@testable import SourceModel

class DiagnosticsCollector: Diagnostics {
    var diagnostics: [Diagnostic] = []
    var hasErrors: Bool = false

    func record(_ diagnostic: Diagnostic) {
        diagnostics.append(diagnostic)
    }
}

class GeneratedFactoriesTests: XCTestCase {

    func testFactories() throws {

        let file = try SourceFile.parse(
            module: "Mock",
            fileName: "MockFile",
            source: """
                import TestModule

                struct ExplicitelyInitialized: Injectable {
                    typealias Scope = CustomScope
                    
                    init(
                        @Inject a: I,
                        bla: Int = 1
                    ) {}


                    class Nested: Injectable {
                        init() {}
                    }
                }

                struct ImplicitInitializer: Injectable {
                    @Inject var a: I
                    @Assisted var b: Int
                    var bla: Int = 1
                }

                class CustomScope: DependencyScope {
                    typealias ParentScope = GlobalScope
                }

                protocol Protocol {}

                extension Dependencies.Factories {
                    static func bind(a: ImplicitInitializer) -> Protocol where Scope == CustomScope {
                        a
                    }
                }

                extension Dependencies.Factories where Scope == GlobalScope {
                    static func bind(a: ImplicitInitializer) -> Protocol {
                        a
                    }
                }
                """
        )

        let diagnostics = DiagnosticsCollector()

        let graph = try DependencyGraphCollector.extractGraph(
            file: file,
            diagnostics: diagnostics
        )

        let text = CodeGen.generateSources(fileGraph: graph)
        
        isRecording = true

        assertSnapshot(matching: text, as: .lines)
        assertSnapshot(matching: graph, as: .yaml)

    }

}
