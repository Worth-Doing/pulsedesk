import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine
    @EnvironmentObject var actionEngine: ActionEngine
    @EnvironmentObject var processEngine: ProcessEngine

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // Quick status strip
                StatusBar()

                // Primary metrics: CPU + Memory (tall panels)
                HStack(spacing: 14) {
                    CPUPanel()
                    MemoryPanel()
                }

                // Secondary metrics row
                HStack(spacing: 14) {
                    NetworkPanel()
                    DiskPanel()
                }

                // Tertiary metrics row
                HStack(spacing: 14) {
                    GPUPanel()
                    ThermalPanel()
                }

                // Smart suggestions
                if !actionEngine.suggestions.isEmpty {
                    SuggestionsPanel()
                }
            }
            .padding(18)
        }
    }
}

// MARK: - Status Bar

struct StatusBar: View {
    @EnvironmentObject var metrics: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine
    @EnvironmentObject var processEngine: ProcessEngine

    var body: some View {
        HStack(spacing: 16) {
            StatusPill(
                icon: "cpu",
                label: "CPU",
                value: String(format: "%.1f%%", metrics.cpu.totalUsage),
                color: Color.forUsage(metrics.cpu.totalUsage)
            )

            StatusPill(
                icon: "memorychip",
                label: "RAM",
                value: String(format: "%.1f%%", metrics.memory.usagePercent),
                color: Color.forUsage(metrics.memory.usagePercent)
            )

            StatusPill(
                icon: "arrow.down",
                label: "Down",
                value: formatSpeed(metrics.network.downloadSpeed),
                color: Color.pulseCyan
            )

            StatusPill(
                icon: "arrow.up",
                label: "Up",
                value: formatSpeed(metrics.network.uploadSpeed),
                color: Color.pulseOrange
            )

            StatusPill(
                icon: thermalEngine.thermalIcon,
                label: "Thermal",
                value: thermalEngine.thermal.thermalState.rawValue,
                color: Color.forThermal(thermalEngine.thermal.thermalState)
            )

            Spacer()

            // Process count
            HStack(spacing: 4) {
                Image(systemName: "gearshape.2")
                    .font(.system(size: 9, weight: .medium))
                Text("\(processEngine.processCount) processes")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 10)
    }
}

struct StatusPill: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Thermal Panel

struct ThermalPanel: View {
    @EnvironmentObject var thermalEngine: ThermalEngine

    private var stateColor: Color {
        Color.forThermal(thermalEngine.thermal.thermalState)
    }

    var body: some View {
        GlassPanel(title: "Thermal", icon: thermalEngine.thermalIcon, color: stateColor) {
            VStack(spacing: 12) {
                HStack {
                    Text(thermalEngine.thermal.thermalState.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(stateColor)

                    Spacer()

                    if let temp = thermalEngine.thermal.cpuTemperature {
                        Text(String(format: "%.0f°C", temp))
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Text(thermalEngine.thermalDescription)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // State indicator
                HStack(spacing: 6) {
                    ForEach(thermalStates, id: \.self) { state in
                        let isActive = stateForName(state) == thermalEngine.thermal.thermalState
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isActive ? stateColor : Color.white.opacity(0.06))
                            .frame(height: 3)
                    }
                }
            }
        }
    }

    private var thermalStates: [String] {
        ["nominal", "fair", "serious", "critical"]
    }

    private func stateForName(_ name: String) -> ThermalMetrics.ThermalState {
        switch name {
        case "nominal": return .nominal
        case "fair": return .fair
        case "serious": return .serious
        case "critical": return .critical
        default: return .nominal
        }
    }
}

// MARK: - Suggestions Panel

struct SuggestionsPanel: View {
    @EnvironmentObject var actionEngine: ActionEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.pulseYellow)
                Text("Suggestions")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text("\(actionEngine.suggestions.count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            ForEach(actionEngine.suggestions) { suggestion in
                HStack(spacing: 8) {
                    Circle()
                        .fill(severityColor(suggestion.severity))
                        .frame(width: 5, height: 5)

                    Text(suggestion.message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 10)
    }

    private func severityColor(_ severity: ActionEngine.SmartSuggestion.Severity) -> Color {
        switch severity {
        case .info: return .pulseBlue
        case .warning: return .pulseOrange
        case .critical: return .pulseRed
        }
    }
}
