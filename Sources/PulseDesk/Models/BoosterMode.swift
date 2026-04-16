import Foundation

enum BoostLevel: String, CaseIterable, Sendable {
    case light = "Light Boost"
    case aggressive = "Aggressive Boost"
    case custom = "Custom Profile"

    var description: String {
        switch self {
        case .light:
            return "Kill unnecessary background processes and free inactive memory"
        case .aggressive:
            return "Aggressively terminate non-essential processes and maximize available resources"
        case .custom:
            return "Apply your custom optimization profile"
        }
    }

    var icon: String {
        switch self {
        case .light: return "bolt"
        case .aggressive: return "bolt.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var cpuThreshold: Double {
        switch self {
        case .light: return 5.0
        case .aggressive: return 1.0
        case .custom: return 3.0
        }
    }

    var memoryThresholdMB: Double {
        switch self {
        case .light: return 200
        case .aggressive: return 50
        case .custom: return 100
        }
    }
}

struct BoostResult: Sendable {
    var processesKilled: Int = 0
    var memoryFreed: UInt64 = 0
    var timestamp: Date = Date()
}
