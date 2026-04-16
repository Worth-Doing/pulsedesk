import SwiftUI

// MARK: - Floating Widget View

struct FloatingWidgetView: View {
    let config: WidgetConfig
    let onClose: () -> Void
    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            widgetContent
                .frame(width: config.width, height: config.height)

            if isHovered {
                Button {
                    onClose()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 20, height: 20)
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .transition(.opacity.animation(.easeOut(duration: 0.15)))
            }
        }
        .background(
            ZStack {
                // Dark base for readability
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.08, blue: 0.14).opacity(0.88))

                // Subtle glass overlay
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.45)

                // Inner glow
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch config.type {
        case .cpuGauge:
            CPUGaugeWidget()
        case .memoryGauge:
            MemoryGaugeWidget()
        case .networkSpeed:
            NetworkSpeedWidget()
        case .diskUsage:
            DiskUsageWidget()
        case .systemHealth:
            SystemHealthWidget()
        case .gpuGauge:
            GPUGaugeWidget()
        }
    }
}

// MARK: - Widget Text Colors

private let wTitle = Color.white.opacity(0.45)
private let wValue = Color.white.opacity(0.95)
private let wSub = Color.white.opacity(0.55)

// MARK: - CPU Gauge Widget

struct CPUGaugeWidget: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            CircularGauge(
                value: metrics.cpu.totalUsage,
                color: Color.forUsage(metrics.cpu.totalUsage),
                lineWidth: 10
            )
            .frame(width: 72, height: 72)

            Text("CPU")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(wTitle)

            HStack(spacing: 10) {
                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", metrics.cpu.userUsage))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.pulseBlue)
                    Text("User")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(wTitle)
                }

                VStack(spacing: 1) {
                    Text(String(format: "%.0f%%", metrics.cpu.systemUsage))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.pulseOrange)
                    Text("Sys")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(wTitle)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Memory Gauge Widget

struct MemoryGaugeWidget: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            CircularGauge(
                value: metrics.memory.usagePercent,
                color: Color.forUsage(metrics.memory.usagePercent),
                lineWidth: 10
            )
            .frame(width: 72, height: 72)

            Text("Memory")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(wTitle)

            HStack(spacing: 10) {
                VStack(spacing: 1) {
                    Text(formatBytes(metrics.memory.used))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.pulseOrange)
                    Text("Used")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(wTitle)
                }

                VStack(spacing: 1) {
                    Text(formatBytes(metrics.memory.free))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.pulseGreen)
                    Text("Free")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(wTitle)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Network Speed Widget

struct NetworkSpeedWidget: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.pulseCyan)
                Text("Network")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(wTitle)
            }

            HStack(spacing: 20) {
                VStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.pulseCyan)

                    Text(formatSpeed(metrics.network.downloadSpeed))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(wValue)

                    Text("Down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(wTitle)
                }

                VStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.pulseOrange)

                    Text(formatSpeed(metrics.network.uploadSpeed))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(wValue)

                    Text("Up")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(wTitle)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Disk Usage Widget

struct DiskUsageWidget: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: CGFloat(metrics.disk.usagePercent / 100))
                    .stroke(
                        Color.forUsage(metrics.disk.usagePercent),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.pulseSpring, value: metrics.disk.usagePercent)

                Text(String(format: "%.0f%%", metrics.disk.usagePercent))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(wValue)
            }

            Text("Disk")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(wTitle)

            Text("\(formatBytes(metrics.disk.freeSpace)) free")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.pulseGreen)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - GPU Gauge Widget

struct GPUGaugeWidget: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            CircularGauge(
                value: metrics.gpu.utilization,
                color: Color.forUsage(metrics.gpu.utilization),
                lineWidth: 10
            )
            .frame(width: 72, height: 72)

            Text("GPU")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(wTitle)

            if metrics.gpu.memoryTotal > 0 {
                Text("\(formatBytes(metrics.gpu.memoryUsed)) VRAM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.pulsePurple)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - System Health Widget

struct SystemHealthWidget: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.pulseGreen)
                Text("System Health")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(wTitle)
            }
            .padding(.top, 12)

            VStack(spacing: 7) {
                widgetMetricRow(icon: "cpu", label: "CPU", value: String(format: "%.0f%%", metrics.cpu.totalUsage), color: Color.forUsage(metrics.cpu.totalUsage))
                widgetMetricRow(icon: "memorychip", label: "RAM", value: String(format: "%.0f%%", metrics.memory.usagePercent), color: Color.forUsage(metrics.memory.usagePercent))
                widgetMetricRow(icon: "internaldrive", label: "Disk", value: String(format: "%.0f%%", metrics.disk.usagePercent), color: Color.forUsage(metrics.disk.usagePercent))
                widgetMetricRow(icon: "gpu", label: "GPU", value: String(format: "%.0f%%", metrics.gpu.utilization), color: Color.forUsage(metrics.gpu.utilization))
                widgetMetricRow(icon: thermalEngine.thermalIcon, label: "Temp", value: thermalEngine.thermal.thermalState.rawValue, color: Color.forThermal(thermalEngine.thermal.thermalState))
            }
            .padding(.horizontal, 14)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func widgetMetricRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 14)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(wSub)
                .frame(width: 32, alignment: .leading)

            Spacer()

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
