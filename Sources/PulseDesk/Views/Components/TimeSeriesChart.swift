import SwiftUI

// MARK: - Chart Series

struct ChartSeries: Identifiable {
    let id = UUID()
    let name: String
    let data: [Double]
    let color: Color
}

// MARK: - Time Series Chart

struct TimeSeriesChart: View {
    let series: [ChartSeries]
    let maxValue: Double
    let formatValue: (Double) -> String
    var showLegend: Bool = true
    var showYAxis: Bool = true
    var gridLines: Int = 4
    var filled: Bool = true
    var refreshInterval: Double = 1.0

    private let yAxisWidth: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showLegend && !series.isEmpty {
                legendBar
            }

            HStack(spacing: 0) {
                if showYAxis {
                    yAxisLabels
                }

                GeometryReader { geometry in
                    ZStack {
                        chartGridLines(size: geometry.size)

                        ForEach(series) { s in
                            GraphLine(
                                data: s.data,
                                maxValue: maxValue,
                                size: geometry.size,
                                color: s.color,
                                filled: filled
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            timeAxisLabels
        }
    }

    // MARK: - Legend

    private var legendBar: some View {
        HStack(spacing: 16) {
            ForEach(series) { s in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(s.color)
                        .frame(width: 12, height: 3)

                    Text(s.name)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.textTertiary)

                    Text(formatValue(s.data.last ?? 0))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(s.color)
                }
            }
            Spacer()
        }
    }

    // MARK: - Y-Axis

    private var yAxisLabels: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(formatValue(maxValue))
            Spacer()
            Text(formatValue(maxValue * 0.75))
            Spacer()
            Text(formatValue(maxValue * 0.5))
            Spacer()
            Text(formatValue(maxValue * 0.25))
            Spacer()
            Text(formatValue(0))
        }
        .font(.system(size: 8, weight: .medium, design: .monospaced))
        .foregroundStyle(Color.textTertiary)
        .frame(width: yAxisWidth)
        .padding(.trailing, 4)
    }

    // MARK: - Grid

    private func chartGridLines(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let step = canvasSize.height / CGFloat(gridLines)
            for i in 0...gridLines {
                let y = CGFloat(i) * step
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(
                    path,
                    with: .color(.white.opacity(0.04)),
                    style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                )
            }
        }
    }

    // MARK: - Time Axis

    private var timeAxisLabels: some View {
        HStack {
            if showYAxis {
                Spacer().frame(width: yAxisWidth + 4)
            }

            let dataCount = series.first?.data.count ?? 0
            let totalSeconds = Int(Double(dataCount) * refreshInterval)

            Text(timeLabel(totalSeconds))
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)

            Spacer()

            if totalSeconds > 30 {
                let mid = totalSeconds / 2
                Text(timeLabel(mid))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)

                Spacer()
            }

            Text("now")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.pulseBlue.opacity(0.6))
        }
    }

    private func timeLabel(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "-\(seconds / 60)m"
        }
        return "-\(seconds)s"
    }
}

// MARK: - Circular Gauge

struct CircularGauge: View {
    let value: Double
    var maxValue: Double = 100
    let color: Color
    var lineWidth: CGFloat = 8
    var showValue: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(value / max(maxValue, 0.001), 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.pulseSpring, value: value)

            if showValue {
                Text(String(format: "%.0f%%", value))
                    .font(.system(size: lineWidth * 1.6, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())

            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 10)
    }
}

// MARK: - Section Header Bar

struct SectionHeaderBar: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            Spacer()
        }
    }
}
