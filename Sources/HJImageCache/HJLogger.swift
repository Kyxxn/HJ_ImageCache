import Foundation
import OSLog

public enum HJLogger {
    private static func log<T>(
        _ object: T?,
        level: OSLogType,
        category: OSLog,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
#if DEBUG
        let message = object.map { String(describing: $0) } ?? "nil"
        let extraInfo = "[\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function)"
        let logMessage = "\(level.prefix) \(extraInfo) - \(message)"
        
        os_log("%@", log: category, type: level, logMessage)
#endif
    }
    
    public static func debug<T>(_ object: T?, category: OSLog = .data, file: String = #file, function: String = #function) {
        log(object, level: .debug, category: category, file: file, function: function)
    }
    
    public static func info<T>(_ object: T?, category: OSLog = .data, file: String = #file, function: String = #function) {
        log(object, level: .info, category: category, file: file, function: function)
    }
    
    public static func network<T>(_ object: T?, category: OSLog = .network, file: String = #file, function: String = #function) {
        log(object, level: .default, category: category, file: file, function: function)
    }
    
    public static func error<T>(_ object: T?, category: OSLog = .data, file: String = #file, function: String = #function) {
        log(object, level: .error, category: category, file: file, function: function)
    }
    
    public static func fault<T>(_ object: T?, category: OSLog = .data, file: String = #file, function: String = #function) {
        log(object, level: .fault, category: category, file: file, function: function)
    }
}

// MARK: - OSLog

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "HJImageCache"
    
    public static let ui = OSLog(subsystem: subsystem, category: "UI")
    public static let network = OSLog(subsystem: subsystem, category: "Network")
    public static let data = OSLog(subsystem: subsystem, category: "Data")
}

// MARK: - OSLogType

extension OSLogType {
    var prefix: String {
        switch self {
        case .debug: return "[🐞 DEBUG]"
        case .info: return "[✅ INFO]"
        case .default: return "[📝 DEFAULT]"
        case .error: return "[‼️ ERROR]"
        case .fault: return "[💥 FAULT]"
        default: return "[❓ UNKNOWN]"
        }
    }
}
