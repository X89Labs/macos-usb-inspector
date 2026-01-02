import Foundation

public struct USBTreeParser {
    public init() {}

    public func parseDevices(from roots: [JSONDict]) -> [USBDeviceSummary] {
        var devices: [USBDeviceSummary] = []
        for root in roots {
            walk(node: root, ancestors: [], results: &devices)
        }
        return devices.sorted { $0.pathDescription < $1.pathDescription }
    }

    private func walk(node: JSONDict, ancestors: [String], results: inout [USBDeviceSummary]) {
        let nodeName = node.stringValue(for: ["_name", "name"]) ?? "Unnamed"
        var newAncestors = ancestors
        if !nodeName.isEmpty {
            newAncestors.append(nodeName)
        }

        if isDeviceNode(node), let summary = makeSummary(from: node, path: newAncestors) {
            results.append(summary)
        }

        if let children = node.children {
            for child in children {
                walk(node: child, ancestors: newAncestors, results: &results)
            }
        }
    }

    private func isDeviceNode(_ node: JSONDict) -> Bool {
        let identifyingKeys = [
            "vendor_id",
            "idVendor",
            "vendorID",
            "product_id",
            "idProduct",
            "device_speed",
            "spusb_device_speed"
        ]
        return identifyingKeys.contains { node[$0] != nil }
    }

    private func makeSummary(from node: JSONDict, path: [String]) -> USBDeviceSummary? {
        let name = node.stringValue(for: ["_name", "name"]) ?? "Unnamed device"
        let vendor = node.stringValue(for: ["vendor", "manufacturer", "Vendor Name", "vendor_id"])
        let vendorID = node.stringValue(for: ["vendor_id", "idVendor", "vendor-id"])
        let productID = node.stringValue(for: ["product_id", "idProduct", "product-id"])
        let serial = node.stringValue(for: ["serial_num", "serial_number", "Serial Number"])
        let location = node.stringValue(for: ["location_id", "Location ID"])
        let bsdName = node.stringValue(for: ["bsd_name", "BSD Name"])
        let usbVersion = node.stringValue(for: ["usb_version", "bcdUSB", "bcd_device"])
        let deviceSpeed = node.stringValue(for: ["device_speed", "spusb_device_speed", "speed"])
        let currentRequired = MilliAmpValue(string: node.stringValue(for: ["current_required", "spusb_current_required"]))
        let currentAvailable = MilliAmpValue(string: node.stringValue(for: ["current_available", "spusb_current_available", "spusb_bus_power_available"]))
        let extraCurrent = MilliAmpValue(string: node.stringValue(for: ["extra_current", "spusb_current_extra"]))
        let interfaceCount = inferInterfaceCount(node: node)
        let deviceClass = node.stringValue(for: ["usb_device_class", "Device Class", "class"])
        let deviceSubClass = node.stringValue(for: ["usb_device_subclass", "Device Subclass", "subclass"])
        let deviceProtocol = node.stringValue(for: ["usb_device_protocol", "Device Protocol", "protocol"])
        let transport = USBTransport.infer(usbVersion: usbVersion, speedDescription: deviceSpeed)
        let powerState = DataPowerState.infer(deviceSpeed: deviceSpeed, currentRequired: currentRequired, bsdName: bsdName, interfaceCount: interfaceCount)
        let videoCapability = VideoCapability.inferUSBDevice(path: pathDescription(from: path), nodeName: name, vendor: vendor, productName: node.stringValue(for: ["product_name"]))
        let deviceType = DeviceType.infer(path: pathDescription(from: path), name: name, vendor: vendor, vendorID: vendorID, deviceClass: deviceClass)
        let isBuiltIn = deviceType == .builtIn

        return USBDeviceSummary(
            pathDescription: pathDescription(from: path),
            name: name,
            vendor: vendor,
            vendorID: vendorID,
            productID: productID,
            serialNumber: serial,
            locationID: location,
            bsdName: bsdName,
            usbVersion: usbVersion,
            deviceSpeed: deviceSpeed,
            currentRequired: currentRequired,
            currentAvailable: currentAvailable,
            extraOperatingCurrent: extraCurrent,
            interfaceCount: interfaceCount,
            deviceClass: deviceClass,
            deviceSubClass: deviceSubClass,
            deviceProtocol: deviceProtocol,
            transport: transport,
            dataPowerState: powerState,
            videoCapability: videoCapability,
            isBuiltIn: isBuiltIn
        )
    }

    private func pathDescription(from path: [String]) -> String {
        path.joined(separator: " > ")
    }

    private func inferInterfaceCount(node: JSONDict) -> Int {
        if let explicit = node.intValue(for: ["num_interfaces", "spusb_num_interfaces", "number_of_interfaces"]) {
            return explicit
        }
        guard let children = node.children else {
            return 0
        }
        let interfaceChildren = children.filter {
            $0["interface_number"] != nil ||
            $0["bInterfaceNumber"] != nil ||
            ($0.stringValue(for: ["_name", "name"])?.lowercased().contains("interface") ?? false)
        }
        return interfaceChildren.count
    }
}

public struct ThunderboltParser {
    public init() {}

    public func parseCables(from roots: [JSONDict]) -> [ThunderboltCableSummary] {
        var cables: [ThunderboltCableSummary] = []
        for root in roots {
            walk(node: root, results: &cables)
        }
        return cables.sorted { $0.name < $1.name }
    }

    private func walk(node: JSONDict, results: inout [ThunderboltCableSummary]) {
        if isCableNode(node), let summary = makeSummary(from: node) {
            cablesAppend(summary, to: &results)
        }

        if let children = node.children {
            for child in children {
                walk(node: child, results: &results)
            }
        }
    }

    private func cablesAppend(_ summary: ThunderboltCableSummary, to results: inout [ThunderboltCableSummary]) {
        if let index = results.firstIndex(where: { $0.serialNumber == summary.serialNumber && summary.serialNumber != nil }) {
            results[index] = summary
        } else {
            results.append(summary)
        }
    }

    private func isCableNode(_ node: JSONDict) -> Bool {
        if node["cable_type"] != nil {
            return true
        }
        if let name = node.stringValue(for: ["_name", "name"])?.lowercased(), name.contains("cable") {
            return true
        }
        if let type = node.stringValue(for: ["device_type"])?.lowercased(), type.contains("cable") {
            return true
        }
        return false
    }

    private func makeSummary(from node: JSONDict) -> ThunderboltCableSummary? {
        let name = node.stringValue(for: ["_name", "name", "device_name"]) ?? "Cable"
        let vendor = node.stringValue(for: ["vendor", "vendor_name", "Manufacturer"])
        let productID = node.stringValue(for: ["product_id", "idProduct"])
        let serial = node.stringValue(for: ["serial_number", "Serial Number"])
        let cableType = node.stringValue(for: ["cable_type", "device_type"])
        let maxSpeed = node.stringValue(for: ["cable_speed", "device_speed", "current_link_speed", "link_speed"])
        let protocols = node.stringArray(for: ["supported_protocols", "protocols", "transport_support", "supported_modes"])
        let capability = ThunderboltParser.determineVideoCapability(protocols: protocols, cableType: cableType, name: name)

        return ThunderboltCableSummary(
            name: name,
            vendor: vendor,
            productID: productID,
            serialNumber: serial,
            cableType: cableType,
            maxSpeed: maxSpeed,
            supportedProtocols: protocols,
            videoCapability: capability
        )
    }

    private static func determineVideoCapability(protocols: [String], cableType: String?, name: String) -> VideoCapability {
        let normalized = protocols.map { $0.lowercased() }
        if normalized.contains(where: { $0.contains("displayport") || $0.contains("dp ") || $0 == "dp" }) {
            return .capable
        }
        if let type = cableType?.lowercased(), type.contains("thunderbolt") {
            return .capable
        }
        if normalized.contains(where: { $0.contains("usb4") || $0.contains("thunderbolt") }) {
            return .capable
        }
        let haystack = name.lowercased()
        if haystack.contains("display") || haystack.contains("hdmi") {
            return .capable
        }
        if normalized.isEmpty {
            return .unknown
        }
        return .notCapable
    }
}

private extension JSONDict {
    var children: [JSONDict]? {
        if let nested = self["_items"] as? [JSONDict] {
            return nested
        }
        if let nested = self["items"] as? [JSONDict] {
            return nested
        }
        return nil
    }

    func stringValue(for keys: [String]) -> String? {
        for key in keys {
            if let value = self[key] as? String, !value.isEmpty {
                return value
            }
            if let value = self[key] as? NSNumber {
                return value.stringValue
            }
        }
        return nil
    }

    func stringArray(for keys: [String]) -> [String] {
        for key in keys {
            if let array = self[key] as? [String] {
                return array
            }
            if let array = self[key] as? [Any] {
                let values = array.compactMap { element -> String? in
                    if let value = element as? String {
                        return value
                    }
                    if let value = element as? NSNumber {
                        return value.stringValue
                    }
                    return nil
                }
                if !values.isEmpty {
                    return values
                }
            }
            if let value = self[key] as? String {
                return [value]
            }
        }
        return []
    }

    func intValue(for keys: [String]) -> Int? {
        for key in keys {
            if let number = self[key] as? NSNumber {
                return number.intValue
            }
            if let string = self[key] as? String, let value = Int(string) {
                return value
            }
        }
        return nil
    }
}
