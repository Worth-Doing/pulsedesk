import Foundation

// MARK: - App Settings (persisted via UserDefaults)

final class AppSettings: ObservableObject {
    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: "pd_refreshInterval") }
    }
    @Published var historyPoints: Int {
        didSet { UserDefaults.standard.set(historyPoints, forKey: "pd_historyPoints") }
    }

    static let intervalPresets: [(label: String, value: Double)] = [
        ("0.5s", 0.5), ("1s", 1.0), ("2s", 2.0), ("3s", 3.0), ("5s", 5.0), ("10s", 10.0)
    ]

    static let historyPresets: [(label: String, value: Int)] = [
        ("1 min", 60), ("2 min", 120), ("5 min", 300), ("10 min", 600)
    ]

    init() {
        let savedInterval = UserDefaults.standard.double(forKey: "pd_refreshInterval")
        self.refreshInterval = savedInterval > 0 ? savedInterval : 1.0

        let savedHistory = UserDefaults.standard.integer(forKey: "pd_historyPoints")
        self.historyPoints = savedHistory > 0 ? savedHistory : 120
    }
}
