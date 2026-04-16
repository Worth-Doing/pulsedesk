import Foundation
import Combine
import Darwin
import IOKit

// MARK: - Metrics Engine

final class MetricsEngine: ObservableObject {
    @Published var cpu = CPUMetrics()
    @Published var memory = MemoryMetrics()
    @Published var disk = DiskMetrics()
    @Published var network = NetworkMetrics()
    @Published var gpu = GPUMetrics()
    @Published var uptime: TimeInterval = 0

    private var highFreqTimer: Timer?
    private var lowFreqTimer: Timer?
    private var previousCPUInfo: host_cpu_load_info?
    private var previousPerCPU: [host_cpu_load_info] = []
    private var previousNetworkBytes: (sent: UInt64, received: UInt64)?
    private var previousDiskStats: (read: UInt64, write: UInt64)?
    private var lastHighFreqUpdate: Date?
    private var lastLowFreqUpdate: Date?

    var maxHistorySize = 120

    init() {
        startMonitoring()
    }

    deinit {
        highFreqTimer?.invalidate()
        lowFreqTimer?.invalidate()
    }

    func startMonitoring() {
        updateCPU()
        updateMemory()
        updateDisk(elapsed: 1.0)
        updateNetwork(elapsed: 1.0)
        updateGPU()
        updateUptime()

        // High-frequency: CPU + Memory (every 1s)
        highFreqTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateCPU()
            self.updateMemory()
        }

        // Low-frequency: Disk + Network + GPU (every 2s)
        lowFreqTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let elapsed = self.lastLowFreqUpdate.map { now.timeIntervalSince($0) } ?? 2.0
            self.lastLowFreqUpdate = now
            self.updateDisk(elapsed: elapsed)
            self.updateNetwork(elapsed: elapsed)
            self.updateGPU()
            self.updateUptime()
        }
    }

    func stopMonitoring() {
        highFreqTimer?.invalidate()
        lowFreqTimer?.invalidate()
        highFreqTimer = nil
        lowFreqTimer = nil
    }

    // MARK: - Uptime

    private func updateUptime() {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.size
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        if sysctl(&mib, 2, &boottime, &size, nil, 0) == 0 {
            uptime = Date().timeIntervalSince1970 - Double(boottime.tv_sec)
        }
    }

    // MARK: - CPU (real per-core via processor_info)

    private func updateCPU() {
        // Overall CPU via host_statistics
        var loadInfo = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        if let prev = previousCPUInfo {
            let userDiff = Double(loadInfo.cpu_ticks.0 - prev.cpu_ticks.0)
            let sysDiff = Double(loadInfo.cpu_ticks.1 - prev.cpu_ticks.1)
            let idleDiff = Double(loadInfo.cpu_ticks.2 - prev.cpu_ticks.2)
            let niceDiff = Double(loadInfo.cpu_ticks.3 - prev.cpu_ticks.3)
            let total = userDiff + sysDiff + idleDiff + niceDiff

            if total > 0 {
                cpu.userUsage = (userDiff / total) * 100
                cpu.systemUsage = (sysDiff / total) * 100
                cpu.idleUsage = (idleDiff / total) * 100
                cpu.totalUsage = cpu.userUsage + cpu.systemUsage
            }
        }

        previousCPUInfo = loadInfo
        cpu.coreCount = ProcessInfo.processInfo.processorCount
        cpu.threadCount = ProcessInfo.processInfo.activeProcessorCount

        // Load average
        var loadavg = [Double](repeating: 0, count: 3)
        getloadavg(&loadavg, 3)
        cpu.loadAverage = loadavg

        // Real per-core usage via host_processor_info
        updatePerCoreCPU()

        // History
        appendHistory(&cpu.history, value: cpu.totalUsage)
        appendHistory(&cpu.userHistory, value: cpu.userUsage)
        appendHistory(&cpu.systemHistory, value: cpu.systemUsage)
    }

    private func updatePerCoreCPU() {
        var cpuCount: natural_t = 0
        var cpuInfoArray: processor_info_array_t?
        var cpuInfoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &cpuInfoArray,
            &cpuInfoCount
        )

        guard result == KERN_SUCCESS, let infoArray = cpuInfoArray else { return }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: infoArray), vm_size_t(cpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        let numCores = Int(cpuCount)
        var currentPerCPU: [host_cpu_load_info] = []
        var perCoreUsage: [Double] = []

        for core in 0..<numCores {
            let offset = Int(CPU_STATE_MAX) * core
            var info = host_cpu_load_info()
            info.cpu_ticks.0 = UInt32(infoArray[offset + Int(CPU_STATE_USER)])
            info.cpu_ticks.1 = UInt32(infoArray[offset + Int(CPU_STATE_SYSTEM)])
            info.cpu_ticks.2 = UInt32(infoArray[offset + Int(CPU_STATE_IDLE)])
            info.cpu_ticks.3 = UInt32(infoArray[offset + Int(CPU_STATE_NICE)])
            currentPerCPU.append(info)

            if core < previousPerCPU.count {
                let prev = previousPerCPU[core]
                let userDiff = Double(info.cpu_ticks.0 - prev.cpu_ticks.0)
                let sysDiff = Double(info.cpu_ticks.1 - prev.cpu_ticks.1)
                let idleDiff = Double(info.cpu_ticks.2 - prev.cpu_ticks.2)
                let niceDiff = Double(info.cpu_ticks.3 - prev.cpu_ticks.3)
                let total = userDiff + sysDiff + idleDiff + niceDiff
                if total > 0 {
                    perCoreUsage.append(((userDiff + sysDiff) / total) * 100)
                } else {
                    perCoreUsage.append(0)
                }
            } else {
                perCoreUsage.append(0)
            }
        }

        previousPerCPU = currentPerCPU
        cpu.perCoreUsage = perCoreUsage
    }

    // MARK: - Memory

    private func updateMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        memory.total = ProcessInfo.processInfo.physicalMemory
        memory.active = UInt64(stats.active_count) * pageSize
        memory.inactive = UInt64(stats.inactive_count) * pageSize
        memory.wired = UInt64(stats.wire_count) * pageSize
        memory.compressed = UInt64(stats.compressor_page_count) * pageSize
        memory.free = UInt64(stats.free_count) * pageSize
        memory.used = memory.active + memory.wired + memory.compressed

        // Swap
        var swapUsage = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swapUsage, &swapSize, nil, 0)
        memory.swapUsed = swapUsage.xsu_used
        memory.swapTotal = swapUsage.xsu_total

        // Memory pressure — use compressed ratio as additional signal
        let usageRatio = Double(memory.used) / Double(memory.total)
        let compressedRatio = Double(memory.compressed) / Double(memory.total)
        if usageRatio > 0.9 || compressedRatio > 0.3 {
            memory.pressure = .critical
        } else if usageRatio > 0.75 || compressedRatio > 0.15 {
            memory.pressure = .warning
        } else {
            memory.pressure = .normal
        }

        appendHistory(&memory.history, value: memory.usagePercent)
    }

    // MARK: - Disk (fixed: no longer corrupts memory.total)

    private func updateDisk(elapsed: TimeInterval) {
        // Disk space
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") {
            if let totalSize = attrs[.systemSize] as? UInt64,
               let freeSize = attrs[.systemFreeSize] as? UInt64 {
                disk.totalSpace = totalSize
                disk.freeSpace = freeSize
                disk.usedSpace = totalSize - freeSize
            }
        }

        // Disk I/O via IOKit
        let matchingDict = IOServiceMatching("IOBlockStorageDriver")
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return
        }

        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = properties?.takeRetainedValue() as? [String: Any],
               let stats = dict["Statistics"] as? [String: Any] {
                if let bytesRead = stats["Bytes (Read)"] as? UInt64 {
                    totalRead += bytesRead
                }
                if let bytesWritten = stats["Bytes (Write)"] as? UInt64 {
                    totalWrite += bytesWritten
                }
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)

        if let prev = previousDiskStats, elapsed > 0 {
            let readDelta = totalRead >= prev.read ? totalRead - prev.read : 0
            let writeDelta = totalWrite >= prev.write ? totalWrite - prev.write : 0
            disk.readSpeed = Double(readDelta) / elapsed
            disk.writeSpeed = Double(writeDelta) / elapsed
        }
        previousDiskStats = (totalRead, totalWrite)

        appendHistory(&disk.readHistory, value: disk.readSpeed)
        appendHistory(&disk.writeHistory, value: disk.writeSpeed)
    }

    // MARK: - Network

    private func updateNetwork(elapsed: TimeInterval) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var totalSent: UInt64 = 0
        var totalReceived: UInt64 = 0

        var ptr = firstAddr
        while true {
            let iface = ptr.pointee
            if iface.ifa_addr.pointee.sa_family == UInt8(AF_LINK) {
                let name = String(cString: iface.ifa_name)
                if name.hasPrefix("en") || name.hasPrefix("lo") {
                    if let data = iface.ifa_data {
                        let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                        totalSent += UInt64(networkData.ifi_obytes)
                        totalReceived += UInt64(networkData.ifi_ibytes)
                    }
                }
            }
            guard let next = iface.ifa_next else { break }
            ptr = next
        }

        if let prev = previousNetworkBytes, elapsed > 0 {
            let sentDelta = totalSent >= prev.sent ? totalSent - prev.sent : 0
            let recvDelta = totalReceived >= prev.received ? totalReceived - prev.received : 0
            network.uploadSpeed = Double(sentDelta) / elapsed
            network.downloadSpeed = Double(recvDelta) / elapsed
        }

        network.bytesSent = totalSent
        network.bytesReceived = totalReceived
        previousNetworkBytes = (totalSent, totalReceived)

        appendHistory(&network.uploadHistory, value: network.uploadSpeed)
        appendHistory(&network.downloadHistory, value: network.downloadSpeed)
    }

    // MARK: - GPU

    private func updateGPU() {
        let matchingDict = IOServiceMatching("AGXAccelerator")
        var iterator: io_iterator_t = 0

        if IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS {
            let entry = IOIteratorNext(iterator)
            if entry != 0 {
                var properties: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let dict = properties?.takeRetainedValue() as? [String: Any] {
                    if let utilization = dict["Device Utilization %"] as? Int {
                        gpu.utilization = Double(utilization)
                    }
                    if let vramUsed = dict["VRAM Used"] as? UInt64 {
                        gpu.memoryUsed = vramUsed
                    }
                    if let vramTotal = dict["VRAM Total"] as? UInt64 {
                        gpu.memoryTotal = vramTotal
                    }
                }
                IOObjectRelease(entry)
            }
            IOObjectRelease(iterator)
        }

        appendHistory(&gpu.history, value: gpu.utilization)
    }

    // MARK: - Helpers

    // MARK: - Configurable Intervals

    func updateIntervals(highFreq: Double, lowFreq: Double) {
        stopMonitoring()

        updateCPU()
        updateMemory()
        updateDisk(elapsed: 1.0)
        updateNetwork(elapsed: 1.0)
        updateGPU()
        updateUptime()

        highFreqTimer = Timer.scheduledTimer(withTimeInterval: highFreq, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateCPU()
            self.updateMemory()
        }

        lowFreqTimer = Timer.scheduledTimer(withTimeInterval: lowFreq, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            let elapsed = self.lastLowFreqUpdate.map { now.timeIntervalSince($0) } ?? lowFreq
            self.lastLowFreqUpdate = now
            self.updateDisk(elapsed: elapsed)
            self.updateNetwork(elapsed: elapsed)
            self.updateGPU()
            self.updateUptime()
        }
    }

    // MARK: - Helpers

    private func appendHistory(_ history: inout [Double], value: Double) {
        history.append(value)
        if history.count > maxHistorySize {
            history.removeFirst()
        }
    }
}
