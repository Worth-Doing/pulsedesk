import Foundation

// MARK: - Process Info

struct ProcessInfoModel: Identifiable, Sendable {
    let id: pid_t
    let pid: pid_t
    var name: String
    var cpuUsage: Double       // percentage
    var memoryUsage: UInt64    // bytes
    var threadCount: Int32
    var isSystemProcess: Bool
    var owner: String
    var score: Double = 0

    var memoryMB: Double {
        Double(memoryUsage) / 1_048_576
    }

    var category: ProcessCategory {
        if isSystemProcess { return .system }
        return .user
    }

    var status: ProcessStatus {
        if cpuUsage > 80 { return .runaway }
        if cpuUsage > 50 { return .heavy }
        if cpuUsage > 10 { return .active }
        return .idle
    }
}

enum ProcessCategory: String, CaseIterable, Sendable {
    case all = "All"
    case user = "User"
    case system = "System"
}

enum ProcessStatus: String, Sendable {
    case idle = "Idle"
    case active = "Active"
    case heavy = "Heavy"
    case runaway = "Runaway"
}

enum ProcessSortKey: String, CaseIterable, Sendable {
    case cpu = "CPU"
    case memory = "Memory"
    case score = "Score"
    case name = "Name"
}
