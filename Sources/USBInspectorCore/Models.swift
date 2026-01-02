import Foundation

public typealias JSONDict = [String: Any]

public struct USBDeviceSummary: Identifiable {
    public let pathDescription: String
    public let name: String
    public let vendor: String?
    public let vendorID: String?
    public let productID: String?
    public let serialNumber: String?
    public let locationID: String?
    public let bsdName: String?
    public let usbVersion: String?
    public let deviceSpeed: String?
    public let currentRequired: MilliAmpValue?
    public let currentAvailable: MilliAmpValue?
    public let extraOperatingCurrent: MilliAmpValue?
    public let interfaceCount: Int
    public let deviceClass: String?
    public let deviceSubClass: String?
    public let deviceProtocol: String?
    public let transport: USBTransport
    public let dataPowerState: DataPowerState
    public let videoCapability: VideoCapability
    public let isBuiltIn: Bool

    public var id: String {
        serialNumber ?? locationID ?? pathDescription
    }

    public init(
        pathDescription: String,
        name: String,
        vendor: String?,
        vendorID: String?,
        productID: String?,
        serialNumber: String?,
        locationID: String?,
        bsdName: String?,
        usbVersion: String?,
        deviceSpeed: String?,
        currentRequired: MilliAmpValue?,
        currentAvailable: MilliAmpValue?,
        extraOperatingCurrent: MilliAmpValue?,
        interfaceCount: Int,
        deviceClass: String?,
        deviceSubClass: String?,
        deviceProtocol: String?,
        transport: USBTransport,
        dataPowerState: DataPowerState,
        videoCapability: VideoCapability,
        isBuiltIn: Bool
    ) {
        self.pathDescription = pathDescription
        self.name = name
        self.vendor = vendor
        self.vendorID = vendorID
        self.productID = productID
        self.serialNumber = serialNumber
        self.locationID = locationID
        self.bsdName = bsdName
        self.usbVersion = usbVersion
        self.deviceSpeed = deviceSpeed
        self.currentRequired = currentRequired
        self.currentAvailable = currentAvailable
        self.extraOperatingCurrent = extraOperatingCurrent
        self.interfaceCount = interfaceCount
        self.deviceClass = deviceClass
        self.deviceSubClass = deviceSubClass
        self.deviceProtocol = deviceProtocol
        self.transport = transport
        self.dataPowerState = dataPowerState
        self.videoCapability = videoCapability
        self.isBuiltIn = isBuiltIn
    }
}

public struct ThunderboltCableSummary: Identifiable {
    public let name: String
    public let vendor: String?
    public let productID: String?
    public let serialNumber: String?
    public let cableType: String?
    public let maxSpeed: String?
    public let supportedProtocols: [String]
    public let videoCapability: VideoCapability

    public var id: String {
        serialNumber ?? "\(vendor ?? "vendor")-\(productID ?? "pid")-\(name)"
    }

    public init(
        name: String,
        vendor: String?,
        productID: String?,
        serialNumber: String?,
        cableType: String?,
        maxSpeed: String?,
        supportedProtocols: [String],
        videoCapability: VideoCapability
    ) {
        self.name = name
        self.vendor = vendor
        self.productID = productID
        self.serialNumber = serialNumber
        self.cableType = cableType
        self.maxSpeed = maxSpeed
        self.supportedProtocols = supportedProtocols
        self.videoCapability = videoCapability
    }
}

public enum USBTransport: String {
    case usb1 = "USB 1.x"
    case usb2 = "USB 2.0"
    case usb3 = "USB 3.0"
    case usb31 = "USB 3.1"
    case usb32 = "USB 3.2"
    case usb4 = "USB4"
    case thunderbolt = "Thunderbolt / USB4"
    case unknown = "Unknown"

    static func infer(usbVersion: String?, speedDescription: String?, cableType: String? = nil) -> USBTransport {
        if let cableType, cableType.lowercased().contains("thunderbolt") {
            return .thunderbolt
        }

        // Prioritize speed over version as it's more reliable
        if let speed = speedDescription?.lowercased() {
            // Speed-based detection (most reliable)
            if speed.contains("40") || speed.contains("40 gb") {
                return .usb4
            }
            if speed.contains("20") || speed.contains("20 gb") {
                return .usb32
            }
            if speed.contains("10") || speed.contains("10 gb") {
                return .usb31
            }
            if speed.contains("5") || speed.contains("5 gb") || speed.contains("super") {
                return .usb3
            }
            if speed.contains("480") || speed.contains("high_speed") || speed.contains("high speed") {
                return .usb2
            }
            if speed.contains("12") || speed.contains("1.5") || speed.contains("full_speed") || speed.contains("low_speed") {
                return .usb1
            }
        }

        // Fall back to version string - use more precise matching
        if let version = usbVersion?.lowercased() {
            // Match patterns like "usb 4", "4.0", etc. but not "2.14" containing "4"
            if version.hasPrefix("4") || version.contains("usb 4") || version.contains("usb4") {
                return .usb4
            }
            if version.contains("3.2") {
                return .usb32
            }
            if version.contains("3.1") {
                return .usb31
            }
            if version.contains("3.0") || version.hasPrefix("3") {
                return .usb3
            }
            if version.contains("2.0") || version.hasPrefix("2") {
                return .usb2
            }
            if version.contains("1.0") || version.contains("1.1") || version.hasPrefix("1") {
                return .usb1
            }
        }

        return .unknown
    }
}

public enum DataPowerState: String {
    case dataAndPower = "Data + Power"
    case powerOnly = "Power Only"
    case unknown = "Unknown"

    static func infer(deviceSpeed: String?, currentRequired: MilliAmpValue?, bsdName: String?, interfaceCount: Int) -> DataPowerState {
        if let name = bsdName, !name.isEmpty {
            return .dataAndPower
        }
        if interfaceCount > 0 {
            return .dataAndPower
        }
        if let speed = deviceSpeed, !speed.isEmpty {
            return .dataAndPower
        }
        if currentRequired != nil {
            return .powerOnly
        }
        return .unknown
    }
}

public enum VideoCapability: String {
    case capable = "Video Ready"
    case notCapable = "Not Supported"
    case unknown = "Unknown"

    static func inferUSBDevice(path: String, nodeName: String, vendor: String?, productName: String?) -> VideoCapability {
        let haystack = [path, nodeName, vendor ?? "", productName ?? ""]
            .map { $0.lowercased() }
            .joined(separator: " ")

        let keywords = ["display", "displayport", "dp", "hdmi", "video", "monitor", "dock"]
        if keywords.contains(where: { haystack.contains($0) }) {
            return .capable
        }
        if haystack.contains("power adapter") || haystack.contains("charger") {
            return .notCapable
        }
        return .unknown
    }
}

public enum DeviceType {
    case builtIn
    case external

    static func infer(path: String, name: String, vendor: String?, vendorID: String?, deviceClass: String?) -> DeviceType {
        let haystack = [path, name, vendor ?? "", vendorID ?? ""]
            .map { $0.lowercased() }
            .joined(separator: " ")

        // Built-in device indicators
        let builtInKeywords = [
            "bluetooth", "camera", "facetime", "fhd camera", "isight",
            "fingerprint", "touch bar", "touchbar", "keyboard", "trackpad",
            "internal", "built-in", "controller hub", "root hub",
            "usb 2.0 bus", "usb 3.0 bus", "usb 3.1 bus", "usb bus",
            "apple internal", "t2 controller"
        ]

        // Check name and path for built-in indicators
        if builtInKeywords.contains(where: { haystack.contains($0) }) {
            return .builtIn
        }

        // Check for Apple vendor (0x05ac) with certain device patterns
        if vendorID?.lowercased() == "0x05ac" || vendorID?.lowercased() == "05ac" {
            let appleBuiltIns = ["keyboard", "trackpad", "mouse", "camera", "bluetooth"]
            if appleBuiltIns.contains(where: { haystack.contains($0) }) {
                return .builtIn
            }
        }

        // Check device class - USB hubs are typically built-in
        if let devClass = deviceClass?.lowercased(), devClass.contains("hub") {
            return .builtIn
        }

        // Path depth check - very short paths are usually built-in hubs
        let pathComponents = path.components(separatedBy: " > ")
        if pathComponents.count <= 2 && haystack.contains("hub") {
            return .builtIn
        }

        return .external
    }
}

public struct MilliAmpValue: CustomStringConvertible, Equatable {
    public let value: Int

    public var description: String {
        "\(value) mA"
    }

    public init?(string: String?) {
        guard let string else {
            return nil
        }
        let digits = string.compactMap { $0.isNumber ? $0 : nil }
        guard !digits.isEmpty, let parsed = Int(String(digits)) else {
            return nil
        }
        value = parsed
    }
}
