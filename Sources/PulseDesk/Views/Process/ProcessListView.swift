import SwiftUI

struct ProcessListView: View {
    @EnvironmentObject var processEngine: ProcessEngine
    @EnvironmentObject var actionEngine: ActionEngine
    @State private var selectedProcess: ProcessInfoModel?
    @State private var showKillConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            ProcessToolbar()

            if processEngine.filteredProcesses.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No processes found",
                    subtitle: processEngine.searchText.isEmpty
                        ? "Waiting for process data..."
                        : "No processes match \"\(processEngine.searchText)\""
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(processEngine.filteredProcesses) { process in
                            ProcessCardView(
                                process: process,
                                isSelected: selectedProcess?.id == process.id,
                                onSelect: { selectedProcess = process },
                                onKill: {
                                    selectedProcess = process
                                    showKillConfirm = true
                                }
                            )
                            .contextMenu {
                                processContextMenu(for: process)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }

            ProcessFooter()
        }
        .alert("Terminate Process", isPresented: $showKillConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Terminate") {
                if let proc = selectedProcess {
                    _ = actionEngine.killProcess(pid: proc.pid, name: proc.name)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        processEngine.refreshProcesses()
                    }
                }
            }
            Button("Force Kill", role: .destructive) {
                if let proc = selectedProcess {
                    _ = actionEngine.forceKillProcess(pid: proc.pid, name: proc.name)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        processEngine.refreshProcesses()
                    }
                }
            }
        } message: {
            if let proc = selectedProcess {
                Text("Terminate \"\(proc.name)\" (PID \(proc.pid))?")
            }
        }
    }

    @ViewBuilder
    private func processContextMenu(for process: ProcessInfoModel) -> some View {
        Button("Terminate") {
            _ = actionEngine.killProcess(pid: process.pid, name: process.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                processEngine.refreshProcesses()
            }
        }
        Button("Force Kill") {
            _ = actionEngine.forceKillProcess(pid: process.pid, name: process.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                processEngine.refreshProcesses()
            }
        }
        Divider()
        Button("Suspend") {
            _ = actionEngine.suspendProcess(pid: process.pid, name: process.name)
        }
        Button("Resume") {
            _ = actionEngine.resumeProcess(pid: process.pid, name: process.name)
        }
        Divider()
        Button("Lower Priority") {
            _ = actionEngine.setPriority(pid: process.pid, nice: 10, name: process.name)
        }
        Button("Raise Priority") {
            _ = actionEngine.setPriority(pid: process.pid, nice: -5, name: process.name)
        }
        Divider()
        Button("Kill Process Tree") {
            _ = actionEngine.killProcessTree(pid: process.pid, name: process.name)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                processEngine.refreshProcesses()
            }
        }
        Divider()
        Button("Copy PID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("\(process.pid)", forType: .string)
        }
        Button("Copy Name") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(process.name, forType: .string)
        }
    }
}

// MARK: - Process Toolbar

struct ProcessToolbar: View {
    @EnvironmentObject var processEngine: ProcessEngine

    var body: some View {
        HStack(spacing: 10) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textTertiary)

                TextField("Search processes...", text: $processEngine.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textPrimary)

                if !processEngine.searchText.isEmpty {
                    Button {
                        processEngine.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Category
            Picker("", selection: $processEngine.filterCategory) {
                ForEach(ProcessCategory.allCases, id: \.self) { cat in
                    Text(cat.rawValue).tag(cat)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Spacer()

            // Sort
            HStack(spacing: 4) {
                Text("Sort:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)

                Picker("", selection: $processEngine.sortKey) {
                    ForEach(ProcessSortKey.allCases, id: \.self) { key in
                        Text(key.rawValue).tag(key)
                    }
                }
                .frame(width: 90)
            }

            // Refresh
            Button {
                processEngine.refreshProcesses()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("r", modifiers: .command)

            Text("\(processEngine.filteredProcesses.count)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Process Footer

struct ProcessFooter: View {
    @EnvironmentObject var processEngine: ProcessEngine

    var body: some View {
        HStack(spacing: 16) {
            FooterStat(icon: "list.bullet", value: "\(processEngine.processCount) total")
            FooterStat(icon: "cpu", value: String(format: "%.1f%% CPU", processEngine.totalCPUByProcesses))
            FooterStat(icon: "memorychip", value: formatBytes(processEngine.totalMemoryByProcesses))

            if !processEngine.runawayProcesses.isEmpty {
                FooterStat(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(processEngine.runawayProcesses.count) runaway",
                    color: Color.pulseRed
                )
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
    }
}

struct FooterStat: View {
    let icon: String
    let value: String
    var color: Color = Color.textTertiary

    var body: some View {
        Label(value, systemImage: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
    }
}
