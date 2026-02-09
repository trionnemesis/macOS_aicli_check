import Foundation

/// A simple service to run shell commands and capture output.
enum ShellService {
    
    /// Executes a shell command synchronously and returns the output.
    /// - Parameter command: The command string to execute (e.g., "gemini /status").
    /// - Returns: The standard output as a String, or nil on failure.
    static func run(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command] // -l for login shell to include PATH
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("ShellService Error: \(error.localizedDescription)")
            return nil
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
