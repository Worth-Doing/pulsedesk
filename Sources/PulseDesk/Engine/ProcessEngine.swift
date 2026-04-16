import Foundation
import Combine
import Darwin

// MARK: - Process Engine

final class ProcessEngine: ObservableObject {
    @Published var processes: [ProcessInfoModel] = []
    @Published var sortKey: ProcessSortKey = .cpu
    @Published var filterCategory: ProcessCategory = .all
    @Published var searchText: String = ""

    private var timer: Timer?
    private var previousTaskTimes: [pid_t: (user: UInt64, system: UInt64, timestamp: Date)] = [:]
    private let cpuWeight: Double = 0.5
    private let memWeight: Double = 0.3
    private let energyWeight: Double = 0.2
    private let totalSystemMemory = ProcessInfo.processInfo.physicalMemory
    private let coreCount = Double(ProcessInfo.processInfo.processorCount)

    var filteredProcesses: [ProcessInfoModel] {
        var result = processes

        if filterCategory != .all {
            result = result.filter { $0.category == filterCategory }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortKey {
        case .cpu:
            result.sort { $0.cpuUsage > $1.cpuUsage }
        case .memory:
            result.sort { $0.memoryUsage > $1.memoryUsage }
        case .score:
            result.sort { $0.score > $1.score }
        case .name:
            result.sort { $0.name.lowercased() < $1.name.lowercased() }
        }

        return result
    }

    var runawayProcesses: [ProcessInfoModel] {
        processes.filter { $0.status == .runaway }
    }

    var totalCPUByProcesses: Double {
        processes.reduce(0) { $0 + $1.cpuUsage }
    }

    var totalMemoryByProcesses: UInt64 {
        processes.reduce(0) { $0 + $1.memoryUsage }
    }

    var processCount: Int {
        processes.count
    }

    init() {
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoring() {
        refreshProcesses()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshProcesses()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refreshProcesses() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let procs = self.fetchProcesses()
            DispatchQueue.main.async {
                self.processes = procs
            }
        }
    }

    private func fetchProcesses() -> [ProcessInfoModel] {
        var result: [ProcessInfoModel] = []
        let now = Date()

        var pids = [pid_t](repeating: 0, count: 4096)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard count > 0 else { return result }

        var newTaskTimes: [pid_t: (user: UInt64, system: UInt64, timestamp: Date)] = [:]

        for i in 0..<Int(count) {
            let pid = pids[i]
            guard pid > 0 else { continue }

            var taskInfo = proc_taskinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)
            let ret = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
            guard ret == taskInfoSize else { continue }

            // Get process name
            let maxPathSize = 4 * Int(MAXPATHLEN)
            var pathBuffer = [CChar](repeating: 0, count: maxPathSize)
            proc_pidpath(pid, &pathBuffer, UInt32(maxPathSize))
            let path = String(cString: pathBuffer)
            let name = (path as NSString).lastPathComponent
            guard !name.isEmpty else { continue }

            // CPU usage via delta-time calculation
            let currentUser = taskInfo.pti_total_user
            let currentSystem = taskInfo.pti_total_system
            newTaskTimes[pid] = (currentUser, currentSystem, now)

            var cpuUsage: Double = 0
            if let prev = previousTaskTimes[pid] {
                let elapsed = now.timeIntervalSince(prev.timestamp)
                if elapsed > 0 {
                    let userDelta = Double(currentUser - prev.user) / 1_000_000_000.0
                    let systemDelta = Double(currentSystem - prev.system) / 1_000_000_000.0
                    cpuUsage = ((userDelta + systemDelta) / elapsed) * 100.0
                    cpuUsage = min(cpuUsage, coreCount * 100)
                }
            }

            let memoryUsage = UInt64(taskInfo.pti_resident_size)
            let threadCount = taskInfo.pti_threadnum

            // Better system process detection
            var bsdInfo = proc_bsdinfo()
            let bsdSize = Int32(MemoryLayout<proc_bsdinfo>.size)
            let bsdRet = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &bsdInfo, bsdSize)
            let uid = bsdRet == bsdSize ? bsdInfo.pbi_uid : UInt32.max
            let isSystem = uid == 0 || pid <= 1

            var proc = ProcessInfoModel(
                id: pid,
                pid: pid,
                name: name,
                cpuUsage: cpuUsage,
                memoryUsage: memoryUsage,
                threadCount: threadCount,
                isSystemProcess: isSystem,
                owner: isSystem ? "root" : NSUserName()
            )

            proc.score = calculateScore(cpu: proc.cpuUsage, memoryBytes: memoryUsage)
            result.append(proc)
        }

        previousTaskTimes = newTaskTimes
        return result
    }

    private func calculateScore(cpu: Double, memoryBytes: UInt64) -> Double {
        let cpuNorm = min(cpu / 100.0, 1.0)
        let memNorm = min(Double(memoryBytes) / Double(totalSystemMemory) * 4.0, 1.0)
        let energyEstimate = (cpuNorm * 0.7 + memNorm * 0.3)
        return (cpuWeight * cpuNorm + memWeight * memNorm + energyWeight * energyEstimate) * 100
    }
}
