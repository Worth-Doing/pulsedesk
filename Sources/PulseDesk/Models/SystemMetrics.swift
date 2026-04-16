import Foundation

// MARK: - CPU Metrics

struct CPUMetrics: Sendable {
    var totalUsage: Double = 0
    var userUsage: Double = 0
    var systemUsage: Double = 0
    var idleUsage: Double = 100
    var coreCount: Int = 0
    var threadCount: Int = 0
    var loadAverage: [Double] = [0, 0, 0]
    var perCoreUsage: [Double] = []
    var history: [Double] = []
}

// MARK: - Memory Metrics

struct MemoryMetrics: Sendable {
    var total: UInt64 = 0
    var used: UInt64 = 0
    var free: UInt64 = 0
    var active: UInt64 = 0
    var inactive: UInt64 = 0
    var wired: UInt64 = 0
    var compressed: UInt64 = 0
    var swapUsed: UInt64 = 0
    var swapTotal: UInt64 = 0
    var pressure: MemoryPressure = .normal
    var history: [Double] = []

    var usagePercent: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var compressedPercent: Double {
        guard total > 0 else { return 0 }
        return Double(compressed) / Double(total) * 100
    }
}

enum MemoryPressure: String, Sendable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
}

// MARK: - Disk Metrics

struct DiskMetrics: Sendable {
    var totalSpace: UInt64 = 0
    var freeSpace: UInt64 = 0
    var usedSpace: UInt64 = 0
    var readSpeed: Double = 0
    var writeSpeed: Double = 0
    var readOps: UInt64 = 0
    var writeOps: UInt64 = 0
    var readHistory: [Double] = []
    var writeHistory: [Double] = []

    var usagePercent: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
}

// MARK: - Network Metrics

struct NetworkMetrics: Sendable {
    var bytesSent: UInt64 = 0
    var bytesReceived: UInt64 = 0
    var uploadSpeed: Double = 0
    var downloadSpeed: Double = 0
    var activeConnections: Int = 0
    var uploadHistory: [Double] = []
    var downloadHistory: [Double] = []
}

// MARK: - GPU Metrics

struct GPUMetrics: Sendable {
    var utilization: Double = 0
    var memoryUsed: UInt64 = 0
    var memoryTotal: UInt64 = 0
    var history: [Double] = []

    var usagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }
}

// MARK: - Thermal Metrics

struct ThermalMetrics: Sendable {
    var thermalState: ThermalState = .nominal
    var cpuTemperature: Double? = nil

    enum ThermalState: String, Sendable {
        case nominal = "Normal"
        case fair = "Elevated"
        case serious = "High"
        case critical = "Critical"
    }
}
