import Foundation
import Combine

// MARK: - Action Engine

final class ActionEngine: ObservableObject {
    @Published var suggestions: [SmartSuggestion] = []
    @Published var boostResult: BoostResult?
    @Published var isBoostActive: Bool = false

    weak var notifications: NotificationEngine?

    struct SmartSuggestion: Identifiable {
        let id = UUID()
        let message: String
        let action: () -> Void
        let severity: Severity
        let processName: String?

        enum Severity {
            case info, warning, critical
        }
    }

    // MARK: - Process Validation

    private func processExists(pid: pid_t) -> Bool {
        kill(pid, 0) == 0 || errno == EPERM
    }

    // MARK: - Basic Actions

    func killProcess(pid: pid_t, name: String = "") -> Bool {
        guard processExists(pid: pid) else {
            notifications?.warning("Process \(name) (PID \(pid)) no longer exists")
            return false
        }
        let result = kill(pid, SIGTERM)
        if result == 0 {
            notifications?.success("Terminated \(name.isEmpty ? "PID \(pid)" : name)")
            return true
        }
        notifications?.error("Failed to terminate \(name.isEmpty ? "PID \(pid)" : name): permission denied")
        return false
    }

    func forceKillProcess(pid: pid_t, name: String = "") -> Bool {
        guard processExists(pid: pid) else {
            notifications?.warning("Process \(name) (PID \(pid)) no longer exists")
            return false
        }
        let result = kill(pid, SIGKILL)
        if result == 0 {
            notifications?.success("Force killed \(name.isEmpty ? "PID \(pid)" : name)")
            return true
        }
        notifications?.error("Failed to force kill \(name.isEmpty ? "PID \(pid)" : name): permission denied")
        return false
    }

    func suspendProcess(pid: pid_t, name: String = "") -> Bool {
        guard processExists(pid: pid) else {
            notifications?.warning("Process no longer exists")
            return false
        }
        let result = kill(pid, SIGSTOP)
        if result == 0 {
            notifications?.success("Suspended \(name.isEmpty ? "PID \(pid)" : name)")
            return true
        }
        notifications?.error("Failed to suspend: permission denied")
        return false
    }

    func resumeProcess(pid: pid_t, name: String = "") -> Bool {
        let result = kill(pid, SIGCONT)
        if result == 0 {
            notifications?.success("Resumed \(name.isEmpty ? "PID \(pid)" : name)")
            return true
        }
        notifications?.error("Failed to resume: permission denied")
        return false
    }

    func setPriority(pid: pid_t, nice: Int32, name: String = "") -> Bool {
        guard processExists(pid: pid) else { return false }
        let result = setpriority(Int32(PRIO_PROCESS), UInt32(pid), nice)
        if result == 0 {
            notifications?.info("Set priority of \(name.isEmpty ? "PID \(pid)" : name) to \(nice)")
            return true
        }
        notifications?.error("Failed to change priority: permission denied")
        return false
    }

    // MARK: - Kill Process Tree

    func killProcessTree(pid: pid_t, name: String = "") -> Int {
        var killed = 0
        let children = findChildProcesses(of: pid)
        for child in children {
            if kill(child, SIGTERM) == 0 {
                killed += 1
            }
        }
        if kill(pid, SIGTERM) == 0 {
            killed += 1
        }
        notifications?.success("Killed process tree: \(killed) processes terminated")
        return killed
    }

    private func findChildProcesses(of parentPid: pid_t) -> [pid_t] {
        var children: [pid_t] = []
        var pids = [pid_t](repeating: 0, count: 4096)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))

        for i in 0..<Int(count) {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var bsdInfo = proc_bsdinfo()
            let size = Int32(MemoryLayout<proc_bsdinfo>.size)
            let ret = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, size)
            if ret == size && bsdInfo.pbi_ppid == parentPid {
                children.append(pid)
                children.append(contentsOf: findChildProcesses(of: pid))
            }
        }

        return children
    }

    // MARK: - Smart Suggestions

    func generateSuggestions(processes: [ProcessInfoModel], memoryPressure: MemoryPressure) {
        var newSuggestions: [SmartSuggestion] = []

        // Runaway process detection
        let runaways = processes.filter { $0.cpuUsage > 80 }
        for proc in runaways {
            let pid = proc.pid
            let name = proc.name
            newSuggestions.append(SmartSuggestion(
                message: "\(proc.name) is using \(String(format: "%.0f", proc.cpuUsage))% CPU",
                action: { [weak self] in _ = self?.killProcess(pid: pid, name: name) },
                severity: .critical,
                processName: proc.name
            ))
        }

        // Heavy memory consumers
        let heavyMem = processes.filter { $0.memoryMB > 500 }.sorted { $0.memoryUsage > $1.memoryUsage }.prefix(3)
        for proc in heavyMem {
            if memoryPressure != .normal {
                newSuggestions.append(SmartSuggestion(
                    message: "\(proc.name) using \(String(format: "%.0f", proc.memoryMB)) MB RAM",
                    action: {},
                    severity: memoryPressure == .critical ? .critical : .warning,
                    processName: proc.name
                ))
            }
        }

        // Memory pressure warning
        if memoryPressure == .critical {
            newSuggestions.append(SmartSuggestion(
                message: "Memory pressure is critical. Consider closing unused apps.",
                action: {},
                severity: .critical,
                processName: nil
            ))
        } else if memoryPressure == .warning {
            newSuggestions.append(SmartSuggestion(
                message: "Memory pressure is elevated.",
                action: {},
                severity: .warning,
                processName: nil
            ))
        }

        DispatchQueue.main.async {
            self.suggestions = newSuggestions
        }
    }

    // MARK: - Booster

    func activateBoost(level: BoostLevel, processes: [ProcessInfoModel]) -> BoostResult {
        isBoostActive = true
        var result = BoostResult()

        // Protected process names that should never be killed
        let protectedNames: Set<String> = [
            "PulseDesk", "Finder", "Dock", "WindowServer",
            "loginwindow", "SystemUIServer", "Spotlight",
            "kernel_task", "launchd", "syslogd", "notifyd"
        ]

        let candidates = processes.filter { proc in
            !proc.isSystemProcess &&
            proc.cpuUsage < level.cpuThreshold &&
            proc.memoryMB < level.memoryThresholdMB &&
            !protectedNames.contains(proc.name)
        }

        for proc in candidates {
            if processExists(pid: proc.pid) && kill(proc.pid, SIGTERM) == 0 {
                result.processesKilled += 1
                result.memoryFreed += proc.memoryUsage
            }
        }

        notifications?.success("Boost complete: \(result.processesKilled) processes freed \(formatBytes(result.memoryFreed))")
        boostResult = result
        isBoostActive = false
        return result
    }
}
