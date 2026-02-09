import Foundation

/// A simple service to run shell commands and capture output.
enum ShellService {
    
    private static var cachedEnvironment: [String: String]? = nil

    /// Fetches the environment from a login shell once and caches it.
    /// This is used to capture the user's PATH and other variables without
    /// having to start a login shell for every single command.
    private static func getEnvironment() -> [String: String] {
        if let cached = cachedEnvironment { return cached }

        var env = ProcessInfo.processInfo.environment

        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "env"]

        do {
            try process.run()
            // Using readToEnd() is safe here as 'env' output is usually small
            let data = try pipe.fileHandleForReading.readToEnd()
            process.waitUntilExit()

            if let data = data, let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: .newlines) {
                    let parts = line.split(separator: "=", maxSplits: 1)
                    if parts.count == 2 {
                        let key = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = String(parts[1])

                        // Only add if the key doesn't contain internal whitespace
                        if !key.isEmpty && !key.contains(where: { $0.isWhitespace }) {
                            env[key] = value
                        }
                    }
                }
            }
        } catch {
            print("ShellService: Failed to fetch login environment: \(error.localizedDescription)")
        }

        cachedEnvironment = env
        return env
    }

    /// Executes a shell command synchronously and returns the output.
    /// - Parameter command: The command string to execute (e.g., "gemini /status").
    /// - Returns: The standard output as a String, or nil on failure.
    static func run(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        // Optimization: Use cached environment and non-login shell (-c instead of -l -c)
        // to reduce power consumption and unnecessary directory access from sourcing shell profiles.
        process.environment = getEnvironment()
        process.arguments = ["-c", command]
        
        do {
            try process.run()

            // Read data safely (blocks until EOF, preventing buffer full deadlock)
            let data = try pipe.fileHandleForReading.readToEnd()

            process.waitUntilExit()

            if let data = data {
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        } catch {
            print("ShellService Error: \(error.localizedDescription)")
            return nil
        }
    }
}
