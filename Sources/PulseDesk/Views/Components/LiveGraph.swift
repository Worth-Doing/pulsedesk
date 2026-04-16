import SwiftUI

// MARK: - Live Graph

struct LiveGraph: View {
    let data: [Double]
    let maxValue: Double
    let color: Color
    var secondaryData: [Double]? = nil
    var secondaryColor: Color? = nil
    var showGrid: Bool = true
    var filled: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showGrid {
                    GridLines()
                }

                if let secondary = secondaryData, let secColor = secondaryColor {
                    GraphLine(
                        data: secondary,
                        maxValue: maxValue,
                        size: geometry.size,
                        color: secColor,
                        filled: filled
                    )
                }

                GraphLine(
                    data: data,
                    maxValue: maxValue,
                    size: geometry.size,
                    color: color,
                    filled: filled
                )
            }
        }
    }
}

// MARK: - Graph Line

struct GraphLine: View {
    let data: [Double]
    let maxValue: Double
    let size: CGSize
    let color: Color
    let filled: Bool

    private func point(at index: Int) -> CGPoint {
        let stepX = size.width / CGFloat(max(data.count - 1, 1))
        let x = CGFloat(index) * stepX
        let normalized = CGFloat(data[index] / max(maxValue, 0.001))
        let y = size.height - (normalized * size.height)
        return CGPoint(x: x, y: max(0, min(size.height, y)))
    }

    var body: some View {
        ZStack {
            if filled, data.count > 1 {
                filledArea
            }

            if data.count > 1 {
                lineStroke
            }

            endDot
        }
        .animation(.linear(duration: 0.25), value: data.count)
    }

    private var filledArea: some View {
        Path { path in
            let stepX = size.width / CGFloat(max(data.count - 1, 1))
            path.move(to: CGPoint(x: 0, y: size.height))
            for i in 0..<data.count {
                let pt = point(at: i)
                if i == 0 {
                    path.addLine(to: pt)
                } else {
                    let prev = point(at: i - 1)
                    let cx = (prev.x + pt.x) / 2
                    path.addCurve(to: pt, control1: CGPoint(x: cx, y: prev.y), control2: CGPoint(x: cx, y: pt.y))
                }
            }
            path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [color.opacity(0.25), color.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var lineStroke: some View {
        Path { path in
            for i in 0..<data.count {
                let pt = point(at: i)
                if i == 0 {
                    path.move(to: pt)
                } else {
                    let prev = point(at: i - 1)
                    let cx = (prev.x + pt.x) / 2
                    path.addCurve(to: pt, control1: CGPoint(x: cx, y: prev.y), control2: CGPoint(x: cx, y: pt.y))
                }
            }
        }
        .stroke(color, lineWidth: 1.5)
    }

    @ViewBuilder
    private var endDot: some View {
        if data.count > 1 {
            let lastPt = point(at: data.count - 1)
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .shadow(color: color.opacity(0.5), radius: 4)
                .position(lastPt)
        }
    }
}

// MARK: - Grid Lines

struct GridLines: View {
    var lineCount: Int = 4

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let step = geometry.size.height / CGFloat(lineCount)
                for i in 1..<lineCount {
                    let y = CGFloat(i) * step
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.05), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
        }
    }
}
