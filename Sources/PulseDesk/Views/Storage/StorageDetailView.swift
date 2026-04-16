import SwiftUI

// MARK: - Storage Detail View

struct StorageDetailView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var storageEngine: StorageEngine
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                storageHeader

                // Disk I/O time series
                GlassPanel(title: "Disk I/O Over Time", icon: "chart.xyaxis.line", color: .pulseYellow) {
                    let maxIO = max(
                        metrics.disk.readHistory.max() ?? 1,
                        metrics.disk.writeHistory.max() ?? 1,
                        1024
                    )

                    TimeSeriesChart(
                        series: [
                            ChartSeries(name: "Read", data: metrics.disk.readHistory, color: .pulseOrange),
                            ChartSeries(name: "Write", data: metrics.disk.writeHistory, color: .pulseYellow)
                        ],
                        maxValue: maxIO,
                        formatValue: { formatSpeed($0) },
                        refreshInterval: settings.refreshInterval * 2
                    )
                    .frame(height: 180)
                }

                // I/O stats
                HStack(spacing: 14) {
                    StatBox(title: "Read Speed", value: formatSpeed(metrics.disk.readSpeed), color: .pulseOrange)
                    StatBox(title: "Write Speed", value: formatSpeed(metrics.disk.writeSpeed), color: .pulseYellow)
                    StatBox(title: "Disk Used", value: String(format: "%.1f%%", metrics.disk.usagePercent), color: Color.forUsage(metrics.disk.usagePercent))
                    StatBox(title: "Free Space", value: formatBytes(metrics.disk.freeSpace), color: .pulseGreen)
                }

                // Scan button
                if storageEngine.applications.isEmpty && !storageEngine.isScanning {
                    Button {
                        storageEngine.scanAll()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Analyze Storage")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.pulseBlue, .pulsePurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                // Scan progress
                if storageEngine.isScanning {
                    VStack(spacing: 8) {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Scanning storage...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(String(format: "%.0f%%", storageEngine.scanProgress * 100))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.pulseBlue)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.06))
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.pulseBlue)
                                    .frame(width: geo.size.width * storageEngine.scanProgress)
                                    .animation(.pulseSpring, value: storageEngine.scanProgress)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(14)
                    .glassCard()
                }

                // Applications
                if !storageEngine.applications.isEmpty {
                    GlassPanel(title: "Applications (\(storageEngine.applications.count))", icon: "app.badge.fill", color: .pulseBlue) {
                        VStack(spacing: 2) {
                            HStack {
                                Text("Total: \(formatBytes(storageEngine.totalAppsSize))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.textSecondary)
                                Spacer()
                                Button("Rescan") { storageEngine.scanAll() }
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.pulseBlue)
                                    .buttonStyle(.plain)
                            }
                            .padding(.bottom, 6)

                            ForEach(Array(storageEngine.applications.prefix(20).enumerated()), id: \.element.id) { index, app in
                                appRow(app: app, index: index + 1, maxSize: storageEngine.applications.first?.size ?? 1)
                            }

                            if storageEngine.applications.count > 20 {
                                Text("+ \(storageEngine.applications.count - 20) more apps")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }

                // Home directories
                if !storageEngine.homeDirectories.isEmpty {
                    GlassPanel(title: "Home Directories", icon: "folder.fill", color: .pulsePurple) {
                        VStack(spacing: 4) {
                            ForEach(storageEngine.homeDirectories) { dir in
                                directoryRow(dir: dir, maxSize: storageEngine.homeDirectories.first?.size ?? 1)
                            }
                        }
                    }
                }

                // Large files
                if !storageEngine.largeFiles.isEmpty {
                    GlassPanel(title: "Large Files (>50 MB)", icon: "doc.richtext.fill", color: .pulseOrange) {
                        VStack(spacing: 2) {
                            ForEach(Array(storageEngine.largeFiles.prefix(20).enumerated()), id: \.element.id) { _, file in
                                fileRow(file: file, maxSize: storageEngine.largeFiles.first?.size ?? 1)
                            }

                            if storageEngine.largeFiles.count > 20 {
                                Text("+ \(storageEngine.largeFiles.count - 20) more files")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var storageHeader: some View {
        HStack(spacing: 16) {
            // Disk usage ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 10)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(metrics.disk.usagePercent / 100))
                    .stroke(
                        Color.forUsage(metrics.disk.usagePercent),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.pulseSpring, value: metrics.disk.usagePercent)

                Text(String(format: "%.0f%%", metrics.disk.usagePercent))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Storage")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                Text("\(formatBytes(metrics.disk.usedSpace)) of \(formatBytes(metrics.disk.totalSpace)) used")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                Text("\(formatBytes(metrics.disk.freeSpace)) available")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.pulseGreen)
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Row Views

    private func appRow(app: AppStorageInfo, index: Int, maxSize: UInt64) -> some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 20, alignment: .trailing)

            // App initial
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.pulseBlue.opacity(0.15))
                    .frame(width: 22, height: 22)

                Text(String(app.name.prefix(1)))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.pulseBlue)
            }

            Text(app.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Spacer()

            // Size bar
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.pulseBlue.opacity(0.3))
                    .frame(width: max(2, geo.size.width * CGFloat(Double(app.size) / Double(maxSize))))
            }
            .frame(width: 60, height: 4)

            Text(formatBytes(app.size))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private func directoryRow(dir: DirectoryStorageInfo, maxSize: UInt64) -> some View {
        HStack(spacing: 8) {
            Image(systemName: dir.icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.pulsePurple)
                .frame(width: 20)

            Text(dir.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Text("\(dir.itemCount) items")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.pulsePurple.opacity(0.3))
                    .frame(width: max(2, geo.size.width * CGFloat(Double(dir.size) / Double(maxSize))))
            }
            .frame(width: 60, height: 4)

            Text(formatBytes(dir.size))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 5)
    }

    private func fileRow(file: FileStorageInfo, maxSize: UInt64) -> some View {
        HStack(spacing: 8) {
            Image(systemName: fileIcon(for: file.fileExtension))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.pulseOrange)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(file.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(file.path)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formatBytes(file.size))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 3)
    }

    private func fileIcon(for ext: String) -> String {
        switch ext.lowercased() {
        case "mp4", "mov", "avi", "mkv": return "film"
        case "mp3", "wav", "aac", "flac": return "music.note"
        case "jpg", "jpeg", "png", "heic", "gif": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "tar", "gz", "dmg": return "archivebox"
        case "app": return "app"
        default: return "doc"
        }
    }
}
