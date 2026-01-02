import SwiftUI
import USBInspectorCore

struct ContentView: View {
    @ObservedObject var viewModel: InspectorViewModel
    @State private var searchText = ""
    @State private var hideBuiltInDevices = true

    private var filteredDevices: [USBDeviceSummary] {
        var devices = viewModel.usbDevices

        // Filter out built-in devices if toggle is on
        if hideBuiltInDevices {
            devices = devices.filter { !$0.isBuiltIn }
        }

        // Apply search filter
        if !searchText.isEmpty {
            devices = devices.filter { device in
                let haystack = [
                    device.name,
                    device.vendor ?? "",
                    device.vendorID ?? "",
                    device.productID ?? "",
                    device.pathDescription
                ]
                    .joined(separator: " ")
                    .lowercased()
                return haystack.contains(searchText.lowercased())
            }
        }

        return devices
    }

    private var filteredCables: [ThunderboltCableSummary] {
        guard !searchText.isEmpty else { return viewModel.cables }
        return viewModel.cables.filter { cable in
            let haystack = [
                cable.name,
                cable.vendor ?? "",
                cable.productID ?? "",
                cable.serialNumber ?? ""
            ]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    if filteredDevices.isEmpty {
                        EmptyStateView(
                            isRefreshing: viewModel.isRefreshing,
                            message: searchText.isEmpty ? "No USB devices reported." : "No USB devices match \"\(searchText)\"."
                        )
                    } else {
                        ForEach(filteredDevices) { device in
                            DeviceSummaryRow(device: device)
                        }
                    }
                } header: {
                    sectionHeader(title: "USB Devices", count: filteredDevices.count)
                }

                Section {
                    if filteredCables.isEmpty {
                        Text("No smart USB-C / Thunderbolt cables detected.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredCables) { cable in
                            CableSummaryRow(cable: cable)
                        }
                    }
                } header: {
                    sectionHeader(title: "USB4 / Thunderbolt Cables", count: filteredCables.count)
                }

                if let error = viewModel.lastError {
                    Section("Latest Error") {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.pink)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("USB Inspector")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: viewModel.refresh) {
                        if viewModel.isRefreshing {
                            ProgressView()
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                    .help(viewModel.isRefreshing ? "Refreshing…" : "Fetch latest USB / Thunderbolt state")
                    .disabled(viewModel.isRefreshing)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { hideBuiltInDevices.toggle() }) {
                        Label(hideBuiltInDevices ? "Show Built-in" : "Hide Built-in",
                              systemImage: hideBuiltInDevices ? "eye.slash.fill" : "eye.fill")
                    }
                    .help(hideBuiltInDevices ? "Show built-in devices (cameras, Bluetooth, etc.)" : "Hide built-in devices")
                }
                if let lastUpdated = viewModel.lastUpdated {
                    ToolbarItem {
                        Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search vendor, VID/PID, or product")
            .overlay(alignment: .center) {
                if viewModel.usbDevices.isEmpty && viewModel.isRefreshing {
                    ProgressView("Loading USB data…")
                        .padding()
                }
            }
            .task {
                if viewModel.usbDevices.isEmpty {
                    viewModel.refresh()
                }
            }
        }
        .navigationViewStyle(.automatic)
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .textCase(nil)
    }
}

private struct EmptyStateView: View {
    let isRefreshing: Bool
    let message: String

    var body: some View {
        HStack {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            }
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private struct DeviceSummaryRow: View {
    let device: USBDeviceSummary

    var cableTypeDescription: String {
        var capabilities: [String] = []

        switch device.dataPowerState {
        case .dataAndPower:
            capabilities.append("Data")
            capabilities.append("Power")
        case .powerOnly:
            capabilities.append("Power Only")
        case .unknown:
            capabilities.append("Unknown")
        }

        if device.videoCapability == .capable {
            if !capabilities.contains("Power Only") {
                capabilities.append("Video")
            }
        }

        return capabilities.joined(separator: " + ")
    }

    var cableIconName: String {
        if device.videoCapability == .capable {
            return "cable.connector.horizontal"
        } else if device.dataPowerState == .dataAndPower {
            return "cable.connector"
        } else if device.dataPowerState == .powerOnly {
            return "bolt.fill"
        } else {
            return "questionmark.circle"
        }
    }

    var cableTypeColor: Color {
        if device.videoCapability == .capable && device.dataPowerState == .dataAndPower {
            return .green  // Best: Data + Power + Video
        } else if device.dataPowerState == .dataAndPower {
            return .blue   // Good: Data + Power
        } else if device.dataPowerState == .powerOnly {
            return .orange // Limited: Power Only
        } else {
            return .gray   // Unknown
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(device.name)
                    .font(.headline)
                Spacer()
                CapabilityTag(text: device.dataPowerState.rawValue, tint: device.dataPowerState.tint)
                CapabilityTag(text: device.transport.rawValue, tint: .blue.opacity(0.8))
                CapabilityTag(text: device.videoCapability.rawValue, tint: device.videoCapability.tint)
            }

            // Prominent cable type indicator
            HStack(spacing: 4) {
                Image(systemName: cableIconName)
                    .foregroundStyle(cableTypeColor)
                Text(cableTypeDescription)
                    .font(.subheadline.bold())
                    .foregroundStyle(cableTypeColor)
            }
            .padding(.vertical, 2)

            Text(device.pathDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let vendor = device.vendor {
                keyValueRow(label: "Vendor", value: vendor)
            }
            if let vid = device.vendorID, let pid = device.productID {
                keyValueRow(label: "VID:PID", value: "\(vid):\(pid)")
            }
            if let serial = device.serialNumber {
                keyValueRow(label: "Serial", value: serial)
            }
            if let bsd = device.bsdName {
                keyValueRow(label: "BSD Name", value: bsd)
            }
            if let version = device.usbVersion {
                keyValueRow(label: "USB Version", value: version)
            }
            if let speed = device.deviceSpeed {
                keyValueRow(label: "Speed", value: speed)
            }
            if device.interfaceCount > 0 {
                keyValueRow(label: "Interfaces", value: "\(device.interfaceCount)")
            }
            if let location = device.locationID {
                keyValueRow(label: "Location", value: location)
            }
            if let current = device.currentAvailable {
                keyValueRow(label: "Bus Power", value: "\(current)")
            }
            if let draw = device.currentRequired {
                keyValueRow(label: "Device Draw", value: "\(draw)")
            }
            if let extra = device.extraOperatingCurrent {
                keyValueRow(label: "Extra Current", value: "\(extra)")
            }
        }
        .padding(.vertical, 6)
    }

    private func keyValueRow(label: String, value: String) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

private struct CableSummaryRow: View {
    let cable: ThunderboltCableSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(cable.name)
                    .font(.headline)
                Spacer()
                CapabilityTag(text: cable.videoCapability.rawValue, tint: cable.videoCapability.tint)
            }
            if let vendor = cable.vendor {
                keyValueRow(label: "Vendor", value: vendor)
            }
            if let pid = cable.productID {
                keyValueRow(label: "Product ID", value: pid)
            }
            if let serial = cable.serialNumber {
                keyValueRow(label: "Serial", value: serial)
            }
            if let type = cable.cableType {
                keyValueRow(label: "Type", value: type)
            }
            if let speed = cable.maxSpeed {
                keyValueRow(label: "Max Speed", value: speed)
            }
            if !cable.supportedProtocols.isEmpty {
                keyValueRow(label: "Protocols", value: cable.supportedProtocols.joined(separator: ", "))
            }
        }
        .padding(.vertical, 6)
    }

    private func keyValueRow(label: String, value: String) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}

private struct CapabilityTag: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(tint.opacity(0.15))
            )
            .foregroundColor(tint)
    }
}

private extension DataPowerState {
    var tint: Color {
        switch self {
        case .dataAndPower:
            return .green
        case .powerOnly:
            return .orange
        case .unknown:
            return .gray
        }
    }
}

private extension VideoCapability {
    var tint: Color {
        switch self {
        case .capable:
            return .green
        case .notCapable:
            return .secondary
        case .unknown:
            return .gray
        }
    }
}
