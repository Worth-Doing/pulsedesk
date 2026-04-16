import SwiftUI

@main
struct PulseDeskApp: App {
    @StateObject private var metricsEngine = MetricsEngine()
    @StateObject private var processEngine = ProcessEngine()
    @StateObject private var actionEngine = ActionEngine()
    @StateObject private var thermalEngine = ThermalEngine()
    @StateObject private var notificationEngine = NotificationEngine()

    init() {}

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(metricsEngine)
                .environmentObject(processEngine)
                .environmentObject(actionEngine)
                .environmentObject(thermalEngine)
                .environmentObject(notificationEngine)
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    actionEngine.notifications = notificationEngine
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // View menu
            CommandGroup(after: .sidebar) {
                Button("Dashboard") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.dashboard)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Processes") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.processes)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Booster") {
                    NotificationCenter.default.post(name: .navigateToTab, object: SidebarTab.booster)
                }
                .keyboardShortcut("3", modifiers: .command)

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
