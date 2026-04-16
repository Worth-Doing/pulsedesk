import SwiftUI

@main
struct PulseDeskApp: App {
    @StateObject private var metricsEngine = MetricsEngine()
    @StateObject private var processEngine = ProcessEngine()
    @StateObject private var actionEngine = ActionEngine()
    @StateObject private var thermalEngine = ThermalEngine()
    @StateObject private var notificationEngine = NotificationEngine()
    @StateObject private var storageEngine = StorageEngine()
    @StateObject private var widgetEngine = WidgetEngine()
    @StateObject private var settings = AppSettings()

    init() {}

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(metricsEngine)
                .environmentObject(processEngine)
                .environmentObject(actionEngine)
                .environmentObject(thermalEngine)
                .environmentObject(notificationEngine)
                .environmentObject(storageEngine)
                .environmentObject(widgetEngine)
                .environmentObject(settings)
                .frame(minWidth: 1060, minHeight: 700)
                .onAppear {
                    actionEngine.notifications = notificationEngine
                    widgetEngine.setEngines(metrics: metricsEngine, thermal: thermalEngine)

                    // Apply saved settings
                    if settings.refreshInterval != 1.0 {
                        metricsEngine.updateIntervals(
                            highFreq: settings.refreshInterval,
                            lowFreq: settings.refreshInterval * 2
                        )
                        thermalEngine.updateInterval(settings.refreshInterval * 2)
                    }
                    if settings.historyPoints != 120 {
                        metricsEngine.maxHistorySize = settings.historyPoints
                    }
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1300, height: 850)
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Home") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.home)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("CPU") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.cpu)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Memory") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.memory)
                }
                .keyboardShortcut("3", modifiers: .command)

                Button("Storage") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.storage)
                }
                .keyboardShortcut("4", modifiers: .command)

                Button("Network") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.network)
                }
                .keyboardShortcut("5", modifiers: .command)

                Button("GPU") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.gpu)
                }
                .keyboardShortcut("6", modifiers: .command)

                Button("Thermal") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.thermal)
                }
                .keyboardShortcut("7", modifiers: .command)

                Button("Processes") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.processes)
                }
                .keyboardShortcut("8", modifiers: .command)

                Button("Booster") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.booster)
                }
                .keyboardShortcut("9", modifiers: .command)

                Button("Widgets") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.widgets)
                }
                .keyboardShortcut("0", modifiers: .command)

                Divider()

                Button("Refresh") {
                    processEngine.refreshProcesses()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let navigateToTab = Notification.Name("navigateToTab")
}
