import Foundation
import AppKit

/// Simple logging service that writes errors to a file.
final class LoggingService {
    static let shared = LoggingService()
    
    private let logFileURL: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.warden.AICLIDashboard.logging")
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("AICLIDashboard")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        logFileURL = appDir.appendingPathComponent("error.log")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    /// Logs a message to the log file.
    func log(_ message: String, level: LogLevel = .info) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = self.dateFormatter.string(from: Date())
            let logLine = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
            
            if let data = logLine.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: self.logFileURL.path) {
                    if let handle = try? FileHandle(forWritingTo: self.logFileURL) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                } else {
                    try? data.write(to: self.logFileURL)
                }
            }
        }
    }
    
    /// Logs an error with context.
    func logError(_ error: Error, context: String) {
        log("\(context): \(error.localizedDescription)", level: .error)
    }
    
    /// Opens the log file in the default application.
    func openLogFile() {
        NSWorkspace.shared.open(logFileURL)
    }
    
    enum LogLevel: String {
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
    }
}
