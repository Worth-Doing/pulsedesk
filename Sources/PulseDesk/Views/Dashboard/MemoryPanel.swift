import SwiftUI

struct MemoryPanel: View {
    @EnvironmentObject var metrics: MetricsEngine

    private var pressureColor: Color {
        Color.forPressure(metrics.memory.pressure)
    }

    var body: some View {
        GlassPanel(title: "Memory", icon: "memorychip", color: .pulsePurple) {
            VStack(spacing: 12) {
                HStack(alignment: .bottom) {
                    BigMetric(
                        value: String(format: "%.1f", metrics.memory.usagePercent),
                        unit: "%",
                        color: Color.forUsage(metrics.memory.usagePercent)
                    )

                    Spacer()

                    // Pressure badge
                    Text(metrics.memory.pressure.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(pressureColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(pressureColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                LiveGraph(
                    data: metrics.memory.history,
                    maxValue: 100,
                    color: .pulsePurple
                )
                .frame(height: 70)

                // Composition bar
                MemoryCompositionBar(metrics: metrics.memory)

                VStack(spacing: 3) {
                    MetricRow(label: "Used", value: formatBytes(metrics.memory.used), color: .pulseOrange)
                    MetricRow(label: "Active", value: formatBytes(metrics.memory.active))
                    MetricRow(label: "Wired", value: formatBytes(metrics.memory.wired))
                    MetricRow(label: "Compressed", value: formatBytes(metrics.memory.compressed))
                    MetricRow(label: "Free", value: formatBytes(metrics.memory.free), color: .pulseGreen)
                    if metrics.memory.swapUsed > 0 {
                        MetricRow(label: "Swap", value: formatBytes(metrics.memory.swapUsed), color: .pulseRed)
                    }
                }
            }
        }
    }
}

struct MemoryCompositionBar: View {
    let metrics: MemoryMetrics

    var body: some View {
        GeometryReader { geometry in
            let total = max(Double(metrics.total), 1)
            let activeW = geometry.size.width * CGFloat(Double(metrics.active) / total)
            let wiredW = geometry.size.width * CGFloat(Double(metrics.wired) / total)
            let compressedW = geometry.size.width * CGFloat(Double(metrics.compressed) / total)

            HStack(spacing: 1) {
                if activeW > 0 {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.pulseOrange)
                        .frame(width: max(1, activeW))
                }
                if wiredW > 0 {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.pulseRed)
                        .frame(width: max(1, wiredW))
                }
                if compressedW > 0 {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.pulsePurple)
                        .frame(width: max(1, compressedW))
                }
                Spacer(minLength: 0)
            }
            .animation(.pulseGentle, value: metrics.used)
        }
        .frame(height: 5)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 2.5))
    }
}
