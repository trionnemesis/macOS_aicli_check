import Foundation

protocol ExecutableLocating: Sendable {
    func locate(named executableName: String) -> URL?
}

/// Resolves executables without starting a login shell or sourcing user shell
/// profiles on every refresh.
struct SystemExecutableLocator: ExecutableLocating {
    func locate(named executableName: String) -> URL? {
        let fileManager = FileManager.default
        let environment = ProcessInfo.processInfo.environment
        let homeDirectory = fileManager.homeDirectoryForCurrentUser.path

        var searchPaths = environment["PATH"]?
            .split(separator: ":")
            .map(String.init) ?? []

        searchPaths.append(contentsOf: [
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/opt/local/bin",
            "/usr/bin",
            "/bin",
            "\(homeDirectory)/.local/bin",
            "\(homeDirectory)/.npm-global/bin",
            "\(homeDirectory)/.bun/bin"
        ])

        var visited = Set<String>()
        for directory in searchPaths where visited.insert(directory).inserted {
            let candidate = URL(fileURLWithPath: directory, isDirectory: true)
                .appendingPathComponent(executableName)
                .standardizedFileURL
            if fileManager.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }
}
