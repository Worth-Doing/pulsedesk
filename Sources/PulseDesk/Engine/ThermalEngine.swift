import Foundation
import Combine
import IOKit

// MARK: - Thermal Engine

final class ThermalEngine: ObservableObject {
    @Published var thermal = ThermalMetrics()
    @Published var thermalHistory: [ThermalMetrics.ThermalState] = []

    private var timer: Timer?
    private let maxHistoryPoints = 60

    init() {
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoring() {
        updateThermal()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateThermal()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateThermal() {
        // Get thermal state from ProcessInfo
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            thermal.thermalState = .nominal
        case .fair:
            thermal.thermalState = .fair
        case .serious:
            thermal.thermalState = .serious
        case .critical:
            thermal.thermalState = .critical
        @unknown default:
            thermal.thermalState = .nominal
        }

        // Attempt to read CPU temperature via IOKit SMC
        thermal.cpuTemperature = readCPUTemperature()

        // History
        thermalHistory.append(thermal.thermalState)
        if thermalHistory.count > maxHistoryPoints {
            thermalHistory.removeFirst()
        }
    }

    private func readCPUTemperature() -> Double? {
        // Try to read from AppleSMC
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMCKeySensor"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = properties?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        // Try common temperature keys
        if let temp = dict["Temperature"] as? Double {
            return temp
        }

        return nil
    }

    var thermalIcon: String {
        switch thermal.thermalState {
        case .nominal: return "thermometer.low"
        case .fair: return "thermometer.medium"
        case .serious: return "thermometer.high"
        case .critical: return "thermometer.sun.fill"
        }
    }

    var thermalDescription: String {
        switch thermal.thermalState {
        case .nominal: return "System temperature is normal"
        case .fair: return "System is slightly warm"
        case .serious: return "System is running hot — consider reducing load"
        case .critical: return "System is overheating — close heavy applications immediately"
        }
    }
}
