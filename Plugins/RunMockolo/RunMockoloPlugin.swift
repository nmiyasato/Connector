import PackagePlugin

@main struct RunMockoloPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generatedSourcePath = context.pluginWorkDirectory.appending("GeneratedMocks.swift")

        return [
            .prebuildCommand(
                displayName: "Run mockolo",
                executable: try context.tool(named: "mockolo").path,
                arguments: [
                    "-s", target.directory.string,
                    "-d", generatedSourcePath,
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            ),
        ]
    }
}
