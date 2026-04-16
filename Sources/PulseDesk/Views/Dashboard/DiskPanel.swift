import SwiftUI

struct DiskPanel: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        GlassPanel(title: "Disk", icon: "internaldrive", color: .pulseYellow) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // Usage ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 5)
                            .frame(width: 46, height: 46)

                        Circle()
                            .trim(from: 0, to: CGFloat(metrics.disk.usagePercent / 100))
                            .stroke(
                                Color.forUsage(metrics.disk.usagePercent),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 46, height: 46)
                            .rotationEffect(.degrees(-90))
                            .animation(.pulseSpring, value: metrics.disk.usagePercent)

                        Text(String(format: "%.0f%%", metrics.disk.usagePercent))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        MetricRow(label: "Used", value: formatBytes(metrics.disk.usedSpace))
                        MetricRow(label: "Free", value: formatBytes(metrics.disk.freeSpace), color: .pulseGreen)
                        MetricRow(label: "Total", value: formatBytes(metrics.disk.totalSpace))
                    }
                }

                // I/O speeds
                HStack(spacing: 16) {
                    SpeedLabel(icon: "arrow.up.doc", label: "Read", value: formatSpeed(metrics.disk.readSpeed), color: .pulseOrange)
                    SpeedLabel(icon: "arrow.down.doc", label: "Write", value: formatSpeed(metrics.disk.writeSpeed), color: .pulseYellow)
                    Spacer()
                }

                let maxIO = max(
                    metrics.disk.readHistory.max() ?? 1,
                    metrics.disk.writeHistory.max() ?? 1,
                    1024
                )

                LiveGraph(
                    data: metrics.disk.readHistory,
                    maxValue: maxIO,
                    color: .pulseOrange,
                    secondaryData: metrics.disk.writeHistory,
                    secondaryColor: .pulseYellow
                )
                .frame(height: 50)
            }
        }
    }
}
