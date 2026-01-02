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
        videoCapability: VideoCapability
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

        if let version = usbVersion?.lowercased() {
            if version.contains("4") {
                return .usb4
            }
            if version.contains("3.2") {
                return .usb32
            }
            if version.contains("3.1") {
                return .usb31
            }
            if version.contains("3.0") {
                return .usb3
            }
            if version.contains("2") {
                return .usb2
            }
            if version.contains("1") {
                return .usb1
            }
        }

        guard let speed = speedDescription?.lowercased() else {
            return .unknown
        }

        if speed.contains("40") {
            return .usb4
        }
        if speed.contains("20") {
            return .usb32
        }
        if speed.contains("10") {
            return .usb31
        }
        if speed.contains("5") {
            return .usb3
        }
        if speed.contains("480") || speed.contains("high") {
            return .usb2
        }
        if speed.contains("12") || speed.contains("full") {
            return .usb1
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
