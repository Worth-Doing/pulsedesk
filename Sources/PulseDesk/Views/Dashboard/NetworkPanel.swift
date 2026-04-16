import SwiftUI

struct NetworkPanel: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        GlassPanel(title: "Network", icon: "network", color: .pulseCyan) {
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    SpeedLabel(icon: "arrow.down", label: "Download", value: formatSpeed(metrics.network.downloadSpeed), color: .pulseCyan)
                    SpeedLabel(icon: "arrow.up", label: "Upload", value: formatSpeed(metrics.network.uploadSpeed), color: .pulseOrange)
                    Spacer()
                }

                let maxSpeed = max(
                    metrics.network.uploadHistory.max() ?? 1,
                    metrics.network.downloadHistory.max() ?? 1,
                    1024
                )

                LiveGraph(
                    data: metrics.network.downloadHistory,
                    maxValue: maxSpeed,
                    color: .pulseCyan,
                    secondaryData: metrics.network.uploadHistory,
                    secondaryColor: .pulseOrange
                )
                .frame(height: 70)

                VStack(spacing: 3) {
                    MetricRow(label: "Total Sent", value: formatBytes(metrics.network.bytesSent))
                    MetricRow(label: "Total Received", value: formatBytes(metrics.network.bytesReceived))
                }
            }
        }
    }
}

struct SpeedLabel: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
    }
}
