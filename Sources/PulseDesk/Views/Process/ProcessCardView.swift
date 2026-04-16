import SwiftUI

struct ProcessCardView: View {
    let process: ProcessInfoModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onKill: () -> Void

    @State private var isHovered = false
    @EnvironmentObject var actionEngine: ActionEngine

    private var statusColor: Color {
        switch process.status {
        case .idle: return Color.textTertiary
        case .active: return .pulseGreen
        case .heavy: return .pulseOrange
        case .runaway: return .pulseRed
        }
    }

    private var processInitial: String {
        String(process.name.prefix(1)).uppercased()
    }

    private var cpuColor: Color {
        Color.forUsage(process.cpuUsage)
    }

    var body: some View {
        HStack(spacing: 10) {
            statusDot
            iconView
            infoSection
            Spacer()
            cpuSection
            memorySection
            ScoreBadge(score: process.score)
            if isHovered || isSelected {
                quickActions
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(cardBg)
        .overlay(cardBorder)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { h in withAnimation(.pulseSnap) { isHovered = h } }
        .animation(.pulseSnap, value: isSelected)
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 5, height: 5)
    }

    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(statusColor.opacity(0.1))
                .frame(width: 28, height: 28)

            Text(processInitial)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text(process.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if process.status == .runaway {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color.pulseRed)
                }
            }

            HStack(spacing: 6) {
                Text("\(process.pid)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                Text(process.category.rawValue)
                    .font(.system(size: 8, weight: .medium))
                Text("\(process.threadCount)t")
                    .font(.system(size: 8, weight: .medium))
            }
            .foregroundStyle(Color.textTertiary)
        }
    }

    private var cpuSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(String(format: "%.1f%%", process.cpuUsage))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(cpuColor)

            UsageBar(value: min(process.cpuUsage, 100), color: cpuColor, height: 2)
                .frame(width: 50)
        }
    }

    private var memorySection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formatMemory(process.memoryMB))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.pulsePurple)

            let memPct = Double(process.memoryUsage) / Double(ProcessInfo.processInfo.physicalMemory) * 100
            UsageBar(value: min(memPct * 4, 100), color: Color.pulsePurple, height: 2)
                .frame(width: 50)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 3) {
            QuickActionBtn(icon: "pause.fill", color: Color.pulseYellow) {
                _ = actionEngine.suspendProcess(pid: process.pid, name: process.name)
            }
            QuickActionBtn(icon: "xmark", color: Color.pulseRed) {
                onKill()
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isSelected ? Color.surfaceActive : isHovered ? Color.surfaceHover : Color.surfaceSecondary)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(isSelected ? Color.pulseBlue.opacity(0.25) : Color.clear, lineWidth: 0.5)
    }

    private func formatMemory(_ mb: Double) -> String {
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

// MARK: - Score Badge

struct ScoreBadge: View {
    let score: Double

    private var color: Color {
        if score > 70 { return .pulseRed }
        if score > 40 { return .pulseOrange }
        if score > 15 { return .pulseYellow }
        return Color.textTertiary
    }

    var body: some View {
        Text(String(format: "%.0f", score))
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .frame(width: 26)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Quick Action Button

struct QuickActionBtn: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button { action() } label: {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20, height: 20)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
