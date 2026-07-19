import Foundation
import AppKit

/// Simple logging service that writes errors to a file.
final class LoggingService {
    static let shared = LoggingService()
    
    private let logFileURL: URL
    private let backupLogFileURL: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.warden.AICLIDashboard.logging")
    private let maximumLogSize = 1_048_576
    
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("AICLIDashboard")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        logFileURL = appDir.appendingPathComponent("error.log")
        backupLogFileURL = appDir.appendingPathComponent("error.log.1")
        
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
                self.rotateIfNeeded(incomingByteCount: data.count)
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

    private func rotateIfNeeded(incomingByteCount: Int) {
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attributes[.size] as? NSNumber,
              fileSize.intValue + incomingByteCount > maximumLogSize else {
            return
        }

        try? fileManager.removeItem(at: backupLogFileURL)
        try? fileManager.moveItem(at: logFileURL, to: backupLogFileURL)
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
