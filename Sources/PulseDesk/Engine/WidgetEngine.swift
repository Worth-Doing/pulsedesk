import AppKit
import SwiftUI
import Combine

// MARK: - Floating Panel (no animation crash)

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func animationResizeTime(_ newFrame: NSRect) -> TimeInterval { 0 }
}

// MARK: - Widget Engine

final class WidgetEngine: ObservableObject {
    @Published var configs: [WidgetConfig] = []

    private var metricsEngine: MetricsEngine?
    private var thermalEngine: ThermalEngine?

    private var windows: [UUID: NSPanel] = [:]
    private var moveObservers: [UUID: NSObjectProtocol] = [:]

    init() {
        loadConfigs()
    }

    deinit {
        for (_, obs) in moveObservers {
            NotificationCenter.default.removeObserver(obs)
        }
        for (_, window) in windows {
            window.contentView = nil
            window.orderOut(nil)
        }
    }

    // MARK: - Setup

    func setEngines(metrics: MetricsEngine, thermal: ThermalEngine) {
        self.metricsEngine = metrics
        self.thermalEngine = thermal
        restoreWidgets()
    }

    // MARK: - Add / Remove

    func addWidget(type: WidgetType) {
        let config = WidgetConfig(type: type)
        configs.append(config)
        saveConfigs()
        createWindow(for: config)
    }

    func removeWidget(id: UUID) {
        if let obs = moveObservers.removeValue(forKey: id) {
            NotificationCenter.default.removeObserver(obs)
        }
        if let window = windows.removeValue(forKey: id) {
            window.contentView = nil
            window.orderOut(nil)
        }
        configs.removeAll { $0.id == id }
        saveConfigs()
    }

    func removeAllWidgets() {
        for (id, _) in windows {
            if let obs = moveObservers[id] {
                NotificationCenter.default.removeObserver(obs)
            }
        }
        for (_, window) in windows {
            window.contentView = nil
            window.orderOut(nil)
        }
        windows.removeAll()
        moveObservers.removeAll()
        configs.removeAll()
        saveConfigs()
    }

    // MARK: - Restore

    private func restoreWidgets() {
        for config in configs {
            if windows[config.id] == nil {
                createWindow(for: config)
            }
        }
    }

    // MARK: - Window Management

    private func createWindow(for config: WidgetConfig) {
        guard let metrics = metricsEngine, let thermal = thermalEngine else { return }
        guard windows[config.id] == nil else { return }

        let panel = FloatingPanel(
            contentRect: NSRect(x: config.x, y: config.y, width: config.width, height: config.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .none
        panel.becomesKeyOnlyIfNeeded = true
        panel.worksWhenModal = true
        panel.isFloatingPanel = true

        let widgetID = config.id
        let view = FloatingWidgetView(config: config, onClose: { [weak self] in
            DispatchQueue.main.async {
                self?.removeWidget(id: widgetID)
            }
        })
        .environmentObject(metrics)
        .environmentObject(thermal)

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: config.width, height: config.height)
        panel.contentView = hosting
        panel.orderFront(nil)
        windows[config.id] = panel

        // Track position changes
        let obs = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] notification in
            guard let movedWindow = notification.object as? NSWindow else { return }
            self?.updatePosition(id: config.id, frame: movedWindow.frame)
        }
        moveObservers[config.id] = obs
    }

    private func updatePosition(id: UUID, frame: NSRect) {
        guard let idx = configs.firstIndex(where: { $0.id == id }) else { return }
        configs[idx].x = Double(frame.origin.x)
        configs[idx].y = Double(frame.origin.y)
        saveConfigs()
    }

    // MARK: - Persistence

    private func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: "pd_widgetConfigs")
        }
    }

    private func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: "pd_widgetConfigs"),
           let saved = try? JSONDecoder().decode([WidgetConfig].self, from: data) {
            configs = saved
        }
    }
}
