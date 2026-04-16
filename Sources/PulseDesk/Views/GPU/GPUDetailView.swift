import SwiftUI

// MARK: - GPU Detail View

struct GPUDetailView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                gpuHeader

                // Time series
                GlassPanel(title: "GPU Utilization Over Time", icon: "chart.xyaxis.line", color: .pulseGreen) {
                    TimeSeriesChart(
                        series: [
                            ChartSeries(name: "GPU Usage", data: metrics.gpu.history, color: .pulseGreen)
                        ],
                        maxValue: 100,
                        formatValue: { String(format: "%.0f%%", $0) },
                        refreshInterval: settings.refreshInterval * 2
                    )
                    .frame(height: 200)
                }

                // Stats row
                HStack(spacing: 14) {
                    StatBox(title: "Utilization", value: String(format: "%.0f%%", metrics.gpu.utilization), color: Color.forUsage(metrics.gpu.utilization))
                    StatBox(title: "VRAM Used", value: formatBytes(metrics.gpu.memoryUsed), color: .pulsePurple)
                    StatBox(title: "VRAM Total", value: formatBytes(metrics.gpu.memoryTotal), color: .pulseBlue)
                    StatBox(title: "Peak", value: String(format: "%.0f%%", metrics.gpu.history.max() ?? 0), color: .pulseOrange)
                }

                // VRAM
                if metrics.gpu.memoryTotal > 0 {
                    GlassPanel(title: "Video Memory (VRAM)", icon: "memorychip", color: .pulsePurple) {
                        VStack(spacing: 14) {
                            HStack(spacing: 20) {
                                CircularGauge(
                                    value: metrics.gpu.usagePercent,
                                    color: Color.forUsage(metrics.gpu.usagePercent),
                                    lineWidth: 8
                                )
                                .frame(width: 70, height: 70)

                                VStack(alignment: .leading, spacing: 6) {
                                    MetricRow(label: "Used", value: formatBytes(metrics.gpu.memoryUsed), color: .pulsePurple)
                                    MetricRow(label: "Total", value: formatBytes(metrics.gpu.memoryTotal))
                                    MetricRow(label: "Free", value: formatBytes(
                                        metrics.gpu.memoryTotal > metrics.gpu.memoryUsed
                                            ? metrics.gpu.memoryTotal - metrics.gpu.memoryUsed
                                            : 0
                                    ), color: .pulseGreen)
                                }

                                Spacer()
                            }

                            UsageBar(value: metrics.gpu.usagePercent, color: Color.forUsage(metrics.gpu.usagePercent), height: 6)
                        }
                    }
                }

                // Usage visualization
                GlassPanel(title: "Usage Distribution", icon: "chart.pie.fill", color: .pulseGreen) {
                    VStack(spacing: 12) {
                        let avgUsage = metrics.gpu.history.isEmpty ? 0 :
                            metrics.gpu.history.reduce(0, +) / Double(metrics.gpu.history.count)
                        let maxUsage = metrics.gpu.history.max() ?? 0
                        let minUsage = metrics.gpu.history.min() ?? 0

                        HStack(spacing: 20) {
                            VStack(spacing: 3) {
                                Text(String(format: "%.0f%%", minUsage))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.pulseGreen)
                                Text("Min")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            VStack(spacing: 3) {
                                Text(String(format: "%.0f%%", avgUsage))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.pulseBlue)
                                Text("Average")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            VStack(spacing: 3) {
                                Text(String(format: "%.0f%%", maxUsage))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.pulseOrange)
                                Text("Max")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            Spacer()
                        }

                        // Usage range bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.white.opacity(0.04))

                                // Range
                                let startX = geo.size.width * CGFloat(minUsage / 100)
                                let endX = geo.size.width * CGFloat(maxUsage / 100)
                                let avgX = geo.size.width * CGFloat(avgUsage / 100)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.pulseGreen.opacity(0.3))
                                    .frame(width: max(2, endX - startX))
                                    .offset(x: startX)

                                // Average marker
                                Circle()
                                    .fill(Color.pulseBlue)
                                    .frame(width: 8, height: 8)
                                    .offset(x: avgX - 4)
                            }
                        }
                        .frame(height: 8)
                    }
                }

                // GPU info
                GlassPanel(title: "GPU Info", icon: "info.circle", color: .textSecondary) {
                    VStack(spacing: 4) {
                        MetricRow(label: "GPU Type", value: "Apple Silicon (Integrated)")
                        MetricRow(label: "Current Usage", value: String(format: "%.1f%%", metrics.gpu.utilization))
                        if metrics.gpu.memoryTotal > 0 {
                            MetricRow(label: "VRAM Usage", value: String(format: "%.1f%%", metrics.gpu.usagePercent))
                        }
                        MetricRow(label: "Data Points", value: "\(metrics.gpu.history.count)")
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var gpuHeader: some View {
        HStack(spacing: 16) {
            CircularGauge(
                value: metrics.gpu.utilization,
                color: Color.forUsage(metrics.gpu.utilization),
                lineWidth: 10
            )
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("GPU")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                Text("Apple Silicon — Integrated Graphics")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                if metrics.gpu.memoryTotal > 0 {
                    Text("VRAM: \(formatBytes(metrics.gpu.memoryUsed)) / \(formatBytes(metrics.gpu.memoryTotal))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }
}
