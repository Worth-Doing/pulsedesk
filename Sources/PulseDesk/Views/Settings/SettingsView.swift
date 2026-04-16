import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var metricsEngine: MetricsEngine
    @EnvironmentObject var thermalEngine: ThermalEngine

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                settingsHeader

                // Refresh interval
                GlassPanel(title: "Refresh Interval", icon: "timer", color: .pulseBlue) {
                    VStack(spacing: 14) {
                        Text("Controls how often system metrics are updated")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Current value
                        HStack {
                            Text("Current:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                            Text(String(format: "%.1fs", settings.refreshInterval))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.pulseBlue)
                            Spacer()
                        }

                        // Preset buttons
                        HStack(spacing: 6) {
                            ForEach(AppSettings.intervalPresets, id: \.value) { preset in
                                Button {
                                    withAnimation(.pulseSpring) {
                                        settings.refreshInterval = preset.value
                                        applyIntervals()
                                    }
                                } label: {
                                    Text(preset.label)
                                        .font(.system(size: 11, weight: settings.refreshInterval == preset.value ? .bold : .medium))
                                        .foregroundStyle(settings.refreshInterval == preset.value ? Color.pulseBlue : Color.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(settings.refreshInterval == preset.value ? Color.pulseBlue.opacity(0.12) : Color.surfaceSecondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(settings.refreshInterval == preset.value ? Color.pulseBlue.opacity(0.3) : Color.borderSubtle, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Slider
                        VStack(spacing: 4) {
                            Slider(
                                value: $settings.refreshInterval,
                                in: 0.5...10.0,
                                step: 0.5
                            ) {
                                Text("Interval")
                            } onEditingChanged: { editing in
                                if !editing {
                                    applyIntervals()
                                }
                            }
                            .tint(Color.pulseBlue)

                            HStack {
                                Text("0.5s (fastest)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                                Spacer()
                                Text("10s (battery saver)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }

                        // Impact note
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.textTertiary)
                            Text("Lower intervals use more CPU. Recommended: 1-2s for monitoring, 5-10s for background use.")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }

                // History duration
                GlassPanel(title: "History Duration", icon: "clock.arrow.circlepath", color: .pulsePurple) {
                    VStack(spacing: 14) {
                        Text("Number of data points stored for time series charts")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            Text("Current:")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                            Text("\(settings.historyPoints) points")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.pulsePurple)

                            let duration = Double(settings.historyPoints) * settings.refreshInterval
                            Text("(\(formatDuration(duration)))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textTertiary)

                            Spacer()
                        }

                        // Preset buttons
                        HStack(spacing: 6) {
                            ForEach(AppSettings.historyPresets, id: \.value) { preset in
                                Button {
                                    withAnimation(.pulseSpring) {
                                        settings.historyPoints = preset.value
                                        applyHistorySize()
                                    }
                                } label: {
                                    Text(preset.label)
                                        .font(.system(size: 11, weight: settings.historyPoints == preset.value ? .bold : .medium))
                                        .foregroundStyle(settings.historyPoints == preset.value ? Color.pulsePurple : Color.textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(settings.historyPoints == preset.value ? Color.pulsePurple.opacity(0.12) : Color.surfaceSecondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .stroke(settings.historyPoints == preset.value ? Color.pulsePurple.opacity(0.3) : Color.borderSubtle, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.textTertiary)
                            Text("More history points use slightly more memory. 120-300 is recommended.")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }

                // Current configuration summary
                GlassPanel(title: "Current Configuration", icon: "list.bullet.rectangle", color: .pulseGreen) {
                    VStack(spacing: 4) {
                        MetricRow(label: "High-freq update", value: String(format: "%.1fs", settings.refreshInterval))
                        MetricRow(label: "Low-freq update", value: String(format: "%.1fs", settings.refreshInterval * 2))
                        MetricRow(label: "History points", value: "\(settings.historyPoints)")
                        MetricRow(label: "Chart duration", value: formatDuration(Double(settings.historyPoints) * settings.refreshInterval))
                        MetricRow(label: "Est. CPU impact", value: cpuImpactLabel)
                    }
                }

                // About
                GlassPanel(title: "About PulseDesk", icon: "info.circle", color: .textSecondary) {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Color.pulseBlue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("PulseDesk")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.textPrimary)

                                Text("System Monitor & Control Center")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.textTertiary)
                            }

                            Spacer()

                            Text("v2.0.0")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.surfacePrimary)
                                .clipShape(Capsule())
                        }

                        Divider().background(Color.borderSubtle)

                        VStack(spacing: 3) {
                            MetricRow(label: "Platform", value: "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                            MetricRow(label: "Architecture", value: "ARM64 (Apple Silicon)")
                            MetricRow(label: "Built with", value: "Swift + SwiftUI")
                            MetricRow(label: "Dependencies", value: "None (pure native)")
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        VStack(spacing: 6) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.textSecondary)

            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Configure monitoring preferences")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func applyIntervals() {
        metricsEngine.updateIntervals(
            highFreq: settings.refreshInterval,
            lowFreq: settings.refreshInterval * 2
        )
        thermalEngine.updateInterval(settings.refreshInterval * 2)
    }

    private func applyHistorySize() {
        metricsEngine.maxHistorySize = settings.historyPoints
    }

    // MARK: - Helpers

    private var cpuImpactLabel: String {
        if settings.refreshInterval <= 1.0 { return "Higher" }
        if settings.refreshInterval <= 3.0 { return "Normal" }
        return "Minimal"
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds >= 60 {
            let minutes = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes)m"
        }
        return "\(Int(seconds))s"
    }
}
