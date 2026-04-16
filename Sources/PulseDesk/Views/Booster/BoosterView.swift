import SwiftUI

struct BoosterView: View {
    @EnvironmentObject var actionEngine: ActionEngine
    @EnvironmentObject var processEngine: ProcessEngine
    @EnvironmentObject var metrics: MetricsEngine
    @State private var selectedLevel: BoostLevel = .light
    @State private var showConfirm = false
    @State private var lastResult: BoostResult?
    @State private var isAnimating = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                boostHeader
                    .padding(.top, 24)

                SystemStatusCard()

                // Boost levels
                VStack(spacing: 8) {
                    Text("OPTIMIZATION LEVEL")
                        .sectionHeader()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)

                    ForEach(BoostLevel.allCases, id: \.self) { level in
                        BoostLevelCard(
                            level: level,
                            isSelected: selectedLevel == level,
                            onSelect: { selectedLevel = level }
                        )
                    }
                }

                activateButton

                if let result = lastResult {
                    BoostResultCard(result: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .alert("Activate Boost", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Boost") { performBoost() }
        } message: {
            Text("This will \(selectedLevel.description.lowercased()). Continue?")
        }
    }

    private var boostHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pulseBlue.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 15,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .opacity(isAnimating ? 0.4 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.pulseBlue)
                    .symbolEffect(.pulse, isActive: isAnimating)
            }

            Text("System Booster")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Optimize system performance instantly")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
    }

    private var activateButton: some View {
        Button { showConfirm = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Activate \(selectedLevel.rawValue)")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.pulseBlue, .pulsePurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.pulseBlue.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func performBoost() {
        withAnimation { isAnimating = true }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = actionEngine.activateBoost(
                level: selectedLevel,
                processes: processEngine.processes
            )
            DispatchQueue.main.async {
                withAnimation(.pulseSpring) {
                    lastResult = result
                    isAnimating = false
                }
                processEngine.refreshProcesses()
            }
        }
    }
}

// MARK: - System Status Card

struct SystemStatusCard: View {
    @EnvironmentObject var metrics: MetricsEngine

    var body: some View {
        HStack(spacing: 0) {
            MiniStatusMetric(label: "CPU", value: String(format: "%.0f%%", metrics.cpu.totalUsage), color: Color.forUsage(metrics.cpu.totalUsage))
            Divider().frame(height: 24).background(Color.borderSubtle)
            MiniStatusMetric(label: "RAM", value: String(format: "%.0f%%", metrics.memory.usagePercent), color: Color.forUsage(metrics.memory.usagePercent))
            Divider().frame(height: 24).background(Color.borderSubtle)
            MiniStatusMetric(label: "Disk", value: String(format: "%.0f%%", metrics.disk.usagePercent), color: Color.forUsage(metrics.disk.usagePercent))
        }
        .padding(.vertical, 14)
        .glassCard()
    }
}

struct MiniStatusMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Boost Level Card

struct BoostLevelCard: View {
    let level: BoostLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button { onSelect() } label: {
            HStack(spacing: 10) {
                Image(systemName: level.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.pulseBlue : Color.textSecondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Text(level.description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.pulseBlue)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.pulseBlue.opacity(0.08) : Color.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.pulseBlue.opacity(0.2) : Color.borderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.pulseSnap, value: isSelected)
    }
}

// MARK: - Boost Result Card

struct BoostResultCard: View {
    let result: BoostResult

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.pulseGreen)
                Text("Boost Complete")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
            }

            HStack(spacing: 14) {
                Label("\(result.processesKilled) terminated", systemImage: "xmark.circle")
                Label(formatBytes(result.memoryFreed) + " freed", systemImage: "memorychip")
                Spacer()
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Color.textSecondary)
        }
        .padding(12)
        .glassCard(cornerRadius: 10)
    }
}
