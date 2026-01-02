import Foundation
import Combine
import USBInspectorCore

@MainActor
final class InspectorViewModel: ObservableObject {
    @Published private(set) var usbDevices: [USBDeviceSummary] = []
    @Published private(set) var cables: [ThunderboltCableSummary] = []
    @Published var isRefreshing = false
    @Published var lastError: String?
    @Published var lastUpdated: Date?

    private let profiler = SystemProfiler()
    private let usbParser = USBTreeParser()
    private let thunderboltParser = ThunderboltParser()

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastError = nil

        Task(priority: .userInitiated) {
            do {
                let report = try await Task.detached {
                    try SystemProfiler().collectReport()
                }.value
                let parsedDevices = await Task.detached {
                    USBTreeParser().parseDevices(from: report.usbNodes)
                }.value
                let parsedCables = await Task.detached {
                    ThunderboltParser().parseCables(from: report.thunderboltNodes)
                }.value
                self.usbDevices = parsedDevices
                self.cables = parsedCables
                self.lastUpdated = Date()
                self.isRefreshing = false
            } catch {
                self.lastError = error.localizedDescription
                self.isRefreshing = false
            }
        }
    }
}
