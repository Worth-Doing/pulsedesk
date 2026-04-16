import SwiftUI

// MARK: - Network Detail View

struct NetworkDetailView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                networkHeader

                // Time series
                GlassPanel(title: "Network Traffic Over Time", icon: "chart.xyaxis.line", color: .pulseCyan) {
                    let maxSpeed = max(
                        metrics.network.uploadHistory.max() ?? 1,
                        metrics.network.downloadHistory.max() ?? 1,
                        1024
                    )

                    TimeSeriesChart(
                        series: [
                            ChartSeries(name: "Download", data: metrics.network.downloadHistory, color: .pulseCyan),
                            ChartSeries(name: "Upload", data: metrics.network.uploadHistory, color: .pulseOrange)
                        ],
                        maxValue: maxSpeed,
                        formatValue: { formatSpeed($0) },
                        refreshInterval: settings.refreshInterval * 2
                    )
                    .frame(height: 200)
                }

                // Speed stats
                HStack(spacing: 14) {
                    StatBox(title: "Download", value: formatSpeed(metrics.network.downloadSpeed), color: .pulseCyan)
                    StatBox(title: "Upload", value: formatSpeed(metrics.network.uploadSpeed), color: .pulseOrange)
                    StatBox(title: "Peak Down", value: formatSpeed(metrics.network.downloadHistory.max() ?? 0), color: .pulsePurple)
                    StatBox(title: "Peak Up", value: formatSpeed(metrics.network.uploadHistory.max() ?? 0), color: .pulseYellow)
                }

                // Transfer totals
                GlassPanel(title: "Data Transfer Totals", icon: "arrow.up.arrow.down.circle.fill", color: .pulseBlue) {
                    VStack(spacing: 14) {
                        HStack(spacing: 20) {
                            transferBlock(
                                icon: "arrow.down.circle.fill",
                                label: "Total Downloaded",
                                value: formatBytes(metrics.network.bytesReceived),
                                color: .pulseCyan
                            )

                            Divider().frame(height: 40).background(Color.borderSubtle)

                            transferBlock(
                                icon: "arrow.up.circle.fill",
                                label: "Total Uploaded",
                                value: formatBytes(metrics.network.bytesSent),
                                color: .pulseOrange
                            )

                            Spacer()
                        }

                        Divider().background(Color.borderSubtle)

                        VStack(spacing: 4) {
                            MetricRow(label: "Total Received", value: formatBytes(metrics.network.bytesReceived), color: .pulseCyan)
                            MetricRow(label: "Total Sent", value: formatBytes(metrics.network.bytesSent), color: .pulseOrange)
                            MetricRow(label: "Combined", value: formatBytes(metrics.network.bytesReceived + metrics.network.bytesSent))
                        }
                    }
                }

                // Speed indicators with visual bars
                GlassPanel(title: "Current Throughput", icon: "speedometer", color: .pulseCyan) {
                    VStack(spacing: 10) {
                        throughputBar(
                            label: "Download",
                            icon: "arrow.down",
                            speed: metrics.network.downloadSpeed,
                            peak: metrics.network.downloadHistory.max() ?? 1024,
                            color: .pulseCyan
                        )

                        throughputBar(
                            label: "Upload",
                            icon: "arrow.up",
                            speed: metrics.network.uploadSpeed,
                            peak: metrics.network.uploadHistory.max() ?? 1024,
                            color: .pulseOrange
                        )
                    }
                }

                // Network info
                GlassPanel(title: "Connection Info", icon: "info.circle", color: .textSecondary) {
                    VStack(spacing: 4) {
                        MetricRow(label: "Session Download", value: formatBytes(metrics.network.bytesReceived))
                        MetricRow(label: "Session Upload", value: formatBytes(metrics.network.bytesSent))
                        MetricRow(label: "Avg Download", value: formatSpeed(
                            metrics.network.downloadHistory.isEmpty ? 0 :
                            metrics.network.downloadHistory.reduce(0, +) / Double(metrics.network.downloadHistory.count)
                        ))
                        MetricRow(label: "Avg Upload", value: formatSpeed(
                            metrics.network.uploadHistory.isEmpty ? 0 :
                            metrics.network.uploadHistory.reduce(0, +) / Double(metrics.network.uploadHistory.count)
                        ))
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var networkHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.pulseCyan.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "network")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.pulseCyan)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Network")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 16) {
                    SpeedLabel(icon: "arrow.down", label: "Download", value: formatSpeed(metrics.network.downloadSpeed), color: .pulseCyan)
                    SpeedLabel(icon: "arrow.up", label: "Upload", value: formatSpeed(metrics.network.uploadSpeed), color: .pulseOrange)
                }
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private func transferBlock(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    private func throughputBar(label: String, icon: String, speed: Double, peak: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 14)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.04))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(2, geo.size.width * CGFloat(min(speed / max(peak, 1), 1.0))))
                        .animation(.pulseSpring, value: speed)
                }
            }
            .frame(height: 8)

            Text(formatSpeed(speed))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
                .frame(width: 70, alignment: .trailing)
        }
    }
}
