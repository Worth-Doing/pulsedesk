import SwiftUI

// MARK: - Thermal Detail View

struct ThermalDetailView: View {
    @EnvironmentObject var thermalEngine: ThermalEngine
    @EnvironmentObject var metrics: MetricsEngine

    private var stateColor: Color {
        Color.forThermal(thermalEngine.thermal.thermalState)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                thermalHeader

                // State history timeline
                GlassPanel(title: "Thermal History", icon: "clock.arrow.circlepath", color: stateColor) {
                    VStack(spacing: 12) {
                        // Timeline visualization
                        GeometryReader { geometry in
                            HStack(spacing: 1) {
                                ForEach(Array(thermalEngine.thermalHistory.enumerated()), id: \.offset) { _, state in
                                    Rectangle()
                                        .fill(Color.forThermal(state))
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .frame(height: 30)

                        // Timeline labels
                        HStack {
                            Text("oldest")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textTertiary)
                            Spacer()
                            Text("\(thermalEngine.thermalHistory.count) samples")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textTertiary)
                            Spacer()
                            Text("now")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.pulseBlue.opacity(0.6))
                        }

                        // State distribution
                        let stateCounts = thermalStateCounts()
                        if !stateCounts.isEmpty {
                            VStack(spacing: 4) {
                                Text("STATE DISTRIBUTION")
                                    .sectionHeader()
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                ForEach(stateCounts, id: \.state) { item in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.forThermal(item.state))
                                            .frame(width: 6, height: 6)

                                        Text(item.state.rawValue)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(Color.textSecondary)
                                            .frame(width: 60, alignment: .leading)

                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.white.opacity(0.04))

                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(Color.forThermal(item.state))
                                                    .frame(width: max(2, geo.size.width * CGFloat(item.percent / 100)))
                                            }
                                        }
                                        .frame(height: 5)

                                        Text(String(format: "%.0f%%", item.percent))
                                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(Color.textTertiary)
                                            .frame(width: 30, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }

                // Current state details
                HStack(spacing: 14) {
                    // Current state card
                    GlassPanel(title: "Current State", icon: thermalEngine.thermalIcon, color: stateColor) {
                        VStack(spacing: 12) {
                            Text(thermalEngine.thermal.thermalState.rawValue)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(stateColor)

                            // State indicator steps
                            HStack(spacing: 6) {
                                ForEach(allStates, id: \.self) { state in
                                    let isActive = state == thermalEngine.thermal.thermalState
                                    VStack(spacing: 3) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(isActive ? Color.forThermal(state) : Color.white.opacity(0.06))
                                            .frame(height: 8)

                                        Text(state.rawValue.prefix(3))
                                            .font(.system(size: 7, weight: isActive ? .bold : .medium))
                                            .foregroundStyle(isActive ? Color.forThermal(state) : Color.textTertiary)
                                    }
                                }
                            }

                            Text(thermalEngine.thermalDescription)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Temperature card
                    GlassPanel(title: "Temperature", icon: "thermometer", color: .pulseOrange) {
                        VStack(spacing: 12) {
                            if let temp = thermalEngine.thermal.cpuTemperature {
                                Text(String(format: "%.0f°", temp))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(tempColor(temp))

                                Text("Celsius")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)

                                // Temp bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.pulseGreen, .pulseYellow, .pulseOrange, .pulseRed],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .opacity(0.2)

                                        Circle()
                                            .fill(tempColor(temp))
                                            .frame(width: 8, height: 8)
                                            .offset(x: geo.size.width * CGFloat(min(temp / 120, 1.0)) - 4)
                                    }
                                }
                                .frame(height: 8)

                                HStack {
                                    Text("0°").font(.system(size: 7)).foregroundStyle(Color.textTertiary)
                                    Spacer()
                                    Text("60°").font(.system(size: 7)).foregroundStyle(Color.textTertiary)
                                    Spacer()
                                    Text("120°").font(.system(size: 7)).foregroundStyle(Color.textTertiary)
                                }
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "thermometer.medium")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.textTertiary)

                                    Text("Temperature data\nnot available")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.textTertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxHeight: .infinity)
                            }
                        }
                    }
                }

                // Related system metrics
                GlassPanel(title: "System Impact", icon: "gauge.with.dots.needle.bottom.50percent", color: .pulseBlue) {
                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            impactMetric(label: "CPU Load", value: String(format: "%.1f%%", metrics.cpu.totalUsage), color: Color.forUsage(metrics.cpu.totalUsage))
                            impactMetric(label: "Memory", value: String(format: "%.1f%%", metrics.memory.usagePercent), color: Color.forUsage(metrics.memory.usagePercent))
                            impactMetric(label: "GPU", value: String(format: "%.0f%%", metrics.gpu.utilization), color: Color.forUsage(metrics.gpu.utilization))
                        }

                        Text("High CPU, memory, or GPU usage can contribute to elevated thermal states")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                // Recommendations
                if thermalEngine.thermal.thermalState != .nominal {
                    GlassPanel(title: "Recommendations", icon: "lightbulb.fill", color: .pulseYellow) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(recommendations, id: \.self) { rec in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.pulseYellow)
                                        .padding(.top, 1)

                                    Text(rec)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    // MARK: - Header

    private var thermalHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(stateColor.opacity(0.12))
                    .frame(width: 80, height: 80)

                Image(systemName: thermalEngine.thermalIcon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(stateColor)
                    .symbolEffect(.pulse, isActive: thermalEngine.thermal.thermalState == .critical)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Thermal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 8) {
                    Text(thermalEngine.thermal.thermalState.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(stateColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(stateColor.opacity(0.12))
                        .clipShape(Capsule())

                    if let temp = thermalEngine.thermal.cpuTemperature {
                        Text(String(format: "%.0f°C", temp))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Text(thermalEngine.thermalDescription)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Helpers

    private var allStates: [ThermalMetrics.ThermalState] {
        [.nominal, .fair, .serious, .critical]
    }

    private struct StateCount {
        let state: ThermalMetrics.ThermalState
        let count: Int
        let percent: Double
    }

    private func thermalStateCounts() -> [StateCount] {
        guard !thermalEngine.thermalHistory.isEmpty else { return [] }
        let total = Double(thermalEngine.thermalHistory.count)

        return allStates.compactMap { state in
            let count = thermalEngine.thermalHistory.filter { $0 == state }.count
            guard count > 0 else { return nil }
            return StateCount(state: state, count: count, percent: Double(count) / total * 100)
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 90 { return .pulseRed }
        if temp > 70 { return .pulseOrange }
        if temp > 50 { return .pulseYellow }
        return .pulseGreen
    }

    private func impactMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var recommendations: [String] {
        var recs: [String] = []
        if metrics.cpu.totalUsage > 70 {
            recs.append("High CPU usage detected — close heavy applications")
        }
        if metrics.memory.usagePercent > 80 {
            recs.append("Memory pressure is elevated — free up RAM")
        }
        if metrics.gpu.utilization > 60 {
            recs.append("GPU is under load — reduce graphics-heavy tasks")
        }
        recs.append("Ensure proper ventilation around your Mac")
        recs.append("Consider using a cooling pad for sustained workloads")
        return recs
    }
}
