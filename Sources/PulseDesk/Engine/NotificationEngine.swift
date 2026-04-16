import Foundation
import SwiftUI

// MARK: - Toast Notification System

final class NotificationEngine: ObservableObject {
    @Published var toasts: [Toast] = []

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType
        let timestamp = Date()

        enum ToastType {
            case success, error, warning, info
        }
    }

    func success(_ message: String) {
        push(Toast(message: message, type: .success))
    }

    func error(_ message: String) {
        push(Toast(message: message, type: .error))
    }

    func warning(_ message: String) {
        push(Toast(message: message, type: .warning))
    }

    func info(_ message: String) {
        push(Toast(message: message, type: .info))
    }

    private func push(_ toast: Toast) {
        DispatchQueue.main.async {
            withAnimation(.pulseSpring) {
                self.toasts.append(toast)
            }
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.pulseSpring) {
                    self.toasts.removeAll { $0.id == toast.id }
                }
            }
        }
    }

    func dismiss(_ id: UUID) {
        withAnimation(.pulseSpring) {
            toasts.removeAll { $0.id == id }
        }
    }
}
