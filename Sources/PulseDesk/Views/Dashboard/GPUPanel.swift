import SwiftUI

struct GPUPanel: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        GlassPanel(title: "GPU", icon: "gpu", color: .pulseGreen) {
            VStack(spacing: 12) {
                HStack(alignment: .bottom) {
                    BigMetric(
                        value: String(format: "%.0f", metrics.gpu.utilization),
                        unit: "%",
                        color: Color.forUsage(metrics.gpu.utilization)
                    )

                    Spacer()

                    Text("Apple Silicon")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }

                LiveGraph(
                    data: metrics.gpu.history,
                    maxValue: 100,
                    color: .pulseGreen
                )
                .frame(height: 50)

                UsageBar(value: metrics.gpu.utilization, color: .pulseGreen)

                if metrics.gpu.memoryTotal > 0 {
                    VStack(spacing: 3) {
                        MetricRow(label: "VRAM Used", value: formatBytes(metrics.gpu.memoryUsed))
                        MetricRow(label: "VRAM Total", value: formatBytes(metrics.gpu.memoryTotal))
                    }
                }
            }
        }
    }
}
