import SwiftUI

@main
struct USBInspectorApp: App {
    @StateObject private var viewModel = InspectorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .frame(minWidth: 720, minHeight: 520)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Diagnostics") {
                Button("Refresh", action: viewModel.refresh)
                    .keyboardShortcut("r")
                    .disabled(viewModel.isRefreshing)
            }
        }
    }
}
