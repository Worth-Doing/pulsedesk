import SwiftUI

struct CPUPanel: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        GlassPanel(title: "CPU", icon: "cpu", color: .pulseBlue) {
            VStack(spacing: 12) {
                // Value + trend
                HStack(alignment: .bottom) {
                    BigMetric(
                        value: String(format: "%.1f", metrics.cpu.totalUsage),
                        unit: "%",
                        color: Color.forUsage(metrics.cpu.totalUsage)
                    )
                    Spacer()
                    if metrics.cpu.history.count > 2 {
                        TrendIndicator(
                            current: metrics.cpu.totalUsage,
                            previous: metrics.cpu.history.dropLast().last ?? 0
                        )
                    }
                }

                // Live graph
                LiveGraph(
                    data: metrics.cpu.history,
                    maxValue: 100,
                    color: Color.forUsage(metrics.cpu.totalUsage)
                )
                .frame(height: 70)

                UsageBar(value: metrics.cpu.totalUsage, color: Color.forUsage(metrics.cpu.totalUsage))

                // Info rows
                VStack(spacing: 3) {
                    MetricRow(label: "User", value: String(format: "%.1f%%", metrics.cpu.userUsage))
                    MetricRow(label: "System", value: String(format: "%.1f%%", metrics.cpu.systemUsage))
                    MetricRow(label: "Cores", value: "\(metrics.cpu.coreCount)")
                    MetricRow(
                        label: "Load Avg",
                        value: metrics.cpu.loadAverage.map { String(format: "%.2f", $0) }.joined(separator: "  ")
                    )
                }

                // Per-core heatmap
                if !metrics.cpu.perCoreUsage.isEmpty {
                    VStack(spacing: 4) {
                        Text("PER CORE")
                            .sectionHeader()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        let columns = min(metrics.cpu.coreCount, 10)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
                            ForEach(0..<metrics.cpu.perCoreUsage.count, id: \.self) { i in
                                CoreCell(usage: metrics.cpu.perCoreUsage[i])
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CoreCell: View {
    let usage: Double

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.forUsage(usage).opacity(max(0.15, usage / 100)))
            .frame(height: 12)
            .overlay(
                Text(String(format: "%.0f", usage))
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(usage > 20 ? 0.9 : 0.3))
            )
            .animation(.pulseGentle, value: usage)
    }
}
