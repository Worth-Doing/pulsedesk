import SwiftUI

// MARK: - Byte Formatting

func formatBytes(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .memory
    return formatter.string(fromByteCount: Int64(bytes))
}

func formatSpeed(_ bytesPerSec: Double) -> String {
    if bytesPerSec < 1 { return "0 B/s" }
    let formatter = ByteCountFormatter()
    formatter.countStyle = .memory
    formatter.allowedUnits = bytesPerSec > 1_048_576 ? [.useMB] : bytesPerSec > 1024 ? [.useKB] : [.useBytes]
    return formatter.string(fromByteCount: Int64(bytesPerSec)) + "/s"
}

func formatUptime(_ seconds: TimeInterval) -> String {
    let days = Int(seconds) / 86400
    let hours = (Int(seconds) % 86400) / 3600
    let minutes = (Int(seconds) % 3600) / 60
    if days > 0 {
        return "\(days)d \(hours)h \(minutes)m"
    } else if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

// MARK: - Color Palette

extension Color {
    static let pulseBlue = Color(red: 0.25, green: 0.52, blue: 1.0)
    static let pulseGreen = Color(red: 0.22, green: 0.82, blue: 0.48)
    static let pulseOrange = Color(red: 1.0, green: 0.58, blue: 0.20)
    static let pulseRed = Color(red: 1.0, green: 0.28, blue: 0.32)
    static let pulsePurple = Color(red: 0.58, green: 0.32, blue: 1.0)
    static let pulseCyan = Color(red: 0.22, green: 0.78, blue: 0.92)
    static let pulseYellow = Color(red: 1.0, green: 0.82, blue: 0.22)
    static let pulsePink = Color(red: 1.0, green: 0.35, blue: 0.60)

    static let surfacePrimary = Color.white.opacity(0.05)
    static let surfaceSecondary = Color.white.opacity(0.03)
    static let surfaceHover = Color.white.opacity(0.08)
    static let surfaceActive = Color.white.opacity(0.10)
    static let borderSubtle = Color.white.opacity(0.08)
    static let borderMedium = Color.white.opacity(0.12)
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    static func forUsage(_ percent: Double) -> Color {
        if percent > 90 { return .pulseRed }
        if percent > 70 { return .pulseOrange }
        if percent > 40 { return .pulseYellow }
        return .pulseGreen
    }

    static func forPressure(_ pressure: MemoryPressure) -> Color {
        switch pressure {
        case .normal: return .pulseGreen
        case .warning: return .pulseOrange
        case .critical: return .pulseRed
        }
    }

    static func forThermal(_ state: ThermalMetrics.ThermalState) -> Color {
        switch state {
        case .nominal: return .pulseGreen
        case .fair: return .pulseYellow
        case .serious: return .pulseOrange
        case .critical: return .pulseRed
        }
    }
}

// MARK: - Animation System

extension Animation {
    static let pulseSpring = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let pulseSmoothSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)
    static let pulseSnap = Animation.spring(response: 0.25, dampingFraction: 0.72)
    static let pulseGentle = Animation.easeInOut(duration: 0.3)
}

// MARK: - View Modifiers

extension View {
    func glassCard(cornerRadius: CGFloat = 14) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.borderSubtle, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }

    func glassCardHover() -> some View {
        self.modifier(GlassHoverModifier())
    }

    func sectionHeader() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

struct GlassHoverModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.008 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.18 : 0.12), radius: isHovered ? 10 : 6)
            .animation(.pulseSpring, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}
