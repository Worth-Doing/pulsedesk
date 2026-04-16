import SwiftUI

// MARK: - Widgets Manager View

struct WidgetsManagerView: View {
    @EnvironmentObject var widgetEngine: WidgetEngine
    @State private var selectedType: WidgetType = .cpuGauge

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                widgetsHeader

                // Active widgets
                GlassPanel(title: "Active Widgets (\(widgetEngine.configs.count))", icon: "square.on.square", color: .pulseBlue) {
                    if widgetEngine.configs.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "rectangle.on.rectangle.slash")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color.textTertiary)

                            Text("No active widgets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.textSecondary)

                            Text("Add a widget below to display real-time metrics on your desktop")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(widgetEngine.configs) { config in
                                activeWidgetRow(config: config)
                            }

                            if widgetEngine.configs.count > 1 {
                                Button {
                                    withAnimation(.pulseSpring) {
                                        widgetEngine.removeAllWidgets()
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 9, weight: .medium))
                                        Text("Remove All")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundStyle(Color.pulseRed)
                                    .padding(.top, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Add widget section
                GlassPanel(title: "Add Widget", icon: "plus.circle.fill", color: .pulseGreen) {
                    VStack(spacing: 14) {
                        Text("Choose a widget type to add to your desktop")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Widget type grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(WidgetType.allCases, id: \.self) { type in
                                widgetTypeCard(type: type)
                            }
                        }

                        // Add button
                        Button {
                            withAnimation(.pulseSpring) {
                                widgetEngine.addWidget(type: selectedType)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Add \(selectedType.rawValue) Widget")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [.pulseBlue, .pulsePurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color.pulseBlue.opacity(0.2), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Widget info
                GlassPanel(title: "About Widgets", icon: "info.circle", color: .textSecondary) {
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(icon: "arrow.up.and.down.and.arrow.left.and.right", text: "Drag widgets to reposition them on your desktop")
                        infoRow(icon: "xmark.circle", text: "Hover over a widget and click the X to remove it")
                        infoRow(icon: "square.stack.3d.up", text: "Widgets float above all windows")
                        infoRow(icon: "arrow.clockwise", text: "Widget positions are saved between sessions")
                        infoRow(icon: "display", text: "Widgets appear on all desktop spaces")
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Header

    private var widgetsHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pulsePurple.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "widget.small")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.pulsePurple)
            }

            Text("Desktop Widgets")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)

            Text("Pin real-time metrics to your desktop")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Active Widget Row

    private func activeWidgetRow(config: WidgetConfig) -> some View {
        HStack(spacing: 10) {
            Image(systemName: config.type.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.pulseBlue)
                .frame(width: 28, height: 28)
                .background(Color.pulseBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(config.type.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text(config.type.description)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text(String(format: "%.0fx%.0f", config.width, config.height))
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textTertiary)

            Button {
                withAnimation(.pulseSpring) {
                    widgetEngine.removeWidget(id: config.id)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Widget Type Card

    private func widgetTypeCard(type: WidgetType) -> some View {
        Button {
            withAnimation(.pulseSnap) {
                selectedType = type
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedType == type ? Color.pulseBlue : Color.textSecondary)

                Text(type.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(selectedType == type ? Color.textPrimary : Color.textSecondary)

                Text(type.description)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selectedType == type ? Color.pulseBlue.opacity(0.08) : Color.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selectedType == type ? Color.pulseBlue.opacity(0.3) : Color.borderSubtle, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Row

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textTertiary)
                .frame(width: 16)

            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
