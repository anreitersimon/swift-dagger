import Foundation
import PackagePlugin

@main struct SwiftDocCConvert: BuildToolPlugin {

    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {

        let target = target as! SwiftSourceModuleTarget
        
        let tool = try context.tool(named: "swift-dagger")
        let generatedSources = context.pluginWorkDirectory.appending("GeneratedSources")
        let dependencyGraphs = context.pluginWorkDirectory.appending("DependencyGraphs")

        let moduleFile = generatedSources.appending(
            "\(target.name)_Module.swift"
        )

        var graphFiles: [Path] = []
        var commands: [Command] = []

        for file in target.sourceFiles(withSuffix: "swift") {
            let outputFile = generatedSources.appending("\(file.path.stem)_Factories.swift")
            let graphFile = dependencyGraphs.appending("\(file.path.stem).json")

            graphFiles.append(graphFile)

            commands.append(
                Command.buildCommand(
                    displayName: "Analyzing \(file.path) \(tool.name)",
                    executable: tool.path,
                    arguments: [
                        "extract",
                        "--module-name=\(target.moduleName)",
                        "--output-file=\(outputFile)",
                        "--graph-file=\(graphFile)",
                        "--input-file=\(file.path)",
                    ],
                    environment: [:],
                    inputFiles: [file.path],
                    outputFiles: [outputFile, graphFile]
                )
            )
        }

        var arguments = [
            "merge",
            "--output-file=\(moduleFile)",
            "--module-name=\(target.moduleName)",
            "--input-files",
        ]
        graphFiles.forEach {
            arguments.append($0.string)
        }

        commands.append(
            Command.buildCommand(
                displayName: "Merging Dependencies",
                executable: tool.path,
                arguments: arguments,
                environment: [:],
                inputFiles: graphFiles,
                outputFiles: [moduleFile]
            )
        )

        return commands
    }

}
