import SwiftUI

// MARK: - Glass Panel

struct GlassPanel<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Spacer()
            }

            content()
        }
        .padding(16)
        .glassCard()
        .glassCardHover()
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let label: String
    let value: String
    var color: Color = .white

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.85))
        }
    }
}

// MARK: - Usage Bar

struct UsageBar: View {
    let value: Double
    let color: Color
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.white.opacity(0.06))
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * min(CGFloat(value) / 100, 1.0), height: height)
                    .animation(.pulseSpring, value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Big Metric Display

struct BigMetric: View {
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())

            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color.opacity(0.5))
        }
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let current: Double
    let previous: Double

    private var trend: Trend {
        let diff = current - previous
        if abs(diff) < 1 { return .stable }
        return diff > 0 ? .up : .down
    }

    private enum Trend {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .pulseOrange
            case .down: return .pulseGreen
            case .stable: return Color.textTertiary
            }
        }
    }

    var body: some View {
        Image(systemName: trend.icon)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(trend.color)
    }
}

// MARK: - Toast Overlay

struct ToastOverlay: View {
    @EnvironmentObject var notifications: NotificationEngine

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            ForEach(notifications.toasts) { toast in
                ToastView(toast: toast) {
                    notifications.dismiss(toast.id)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .animation(.pulseSpring, value: notifications.toasts.count)
    }
}

struct ToastView: View {
    let toast: NotificationEngine.Toast
    let onDismiss: () -> Void

    private var iconName: String {
        switch toast.type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch toast.type {
        case .success: return .pulseGreen
        case .error: return .pulseRed
        case .warning: return .pulseOrange
        case .info: return .pulseBlue
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            Text(toast.message)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 10)
        .frame(maxWidth: 400)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.textTertiary)

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textSecondary)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}
