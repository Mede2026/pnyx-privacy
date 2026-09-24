import OSLog

public extension Logger {
    private static let subsystem = "app.qrstudio"

    static let scanner = Logger(subsystem: subsystem, category: "scanner")
    static let rendering = Logger(subsystem: subsystem, category: "rendering")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let actions = Logger(subsystem: subsystem, category: "actions")
    static let export = Logger(subsystem: subsystem, category: "export")
    static let general = Logger(subsystem: subsystem, category: "general")
}
