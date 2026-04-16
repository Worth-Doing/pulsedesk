import Foundation

// MARK: - Widget Type

enum WidgetType: String, CaseIterable, Codable {
    case cpuGauge = "CPU"
    case memoryGauge = "Memory"
    case networkSpeed = "Network"
    case diskUsage = "Disk"
    case systemHealth = "System"
    case gpuGauge = "GPU"

    var icon: String {
        switch self {
        case .cpuGauge: return "cpu"
        case .memoryGauge: return "memorychip"
        case .networkSpeed: return "network"
        case .diskUsage: return "internaldrive"
        case .systemHealth: return "heart.text.square"
        case .gpuGauge: return "gpu"
        }
    }

    var defaultWidth: Double {
        switch self {
        case .cpuGauge, .memoryGauge, .gpuGauge, .diskUsage: return 170
        case .networkSpeed: return 220
        case .systemHealth: return 280
        }
    }

    var defaultHeight: Double {
        switch self {
        case .cpuGauge, .memoryGauge, .gpuGauge, .diskUsage: return 170
        case .networkSpeed: return 130
        case .systemHealth: return 220
        }
    }

    var description: String {
        switch self {
        case .cpuGauge: return "Real-time CPU usage gauge"
        case .memoryGauge: return "Memory pressure & usage"
        case .networkSpeed: return "Upload & download speeds"
        case .diskUsage: return "Disk space usage ring"
        case .systemHealth: return "Overall system health summary"
        case .gpuGauge: return "GPU utilization gauge"
        }
    }
}

// MARK: - Widget Configuration

struct WidgetConfig: Identifiable, Codable {
    let id: UUID
    var type: WidgetType
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(type: WidgetType) {
        self.id = UUID()
        self.type = type
        self.x = 120 + Double.random(in: 0...200)
        self.y = 120 + Double.random(in: 0...200)
        self.width = type.defaultWidth
        self.height = type.defaultHeight
    }
}
