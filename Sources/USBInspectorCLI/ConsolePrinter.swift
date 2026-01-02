import Foundation
import USBInspectorCore

struct ConsolePrinter {
    func render(usbDevices: [USBDeviceSummary], thunderboltCables: [ThunderboltCableSummary]) {
        printSectionTitle("USB Devices")
        if usbDevices.isEmpty {
            print("No USB devices were reported by system_profiler.")
        } else {
            for device in usbDevices {
                printDevice(device)
                print("")
            }
        }

        printSectionTitle("USB4 / Thunderbolt Cables")
        if thunderboltCables.isEmpty {
            print("No smart USB-C / Thunderbolt cables detected (many passive cables lack firmware and will not appear).")
        } else {
            for cable in thunderboltCables {
                printCable(cable)
                print("")
            }
        }
    }

    private func printSectionTitle(_ title: String) {
        print("\n=== \(title) ===")
    }

    private func printDevice(_ device: USBDeviceSummary) {
        print("• \(device.name)")
        print("  Path: \(device.pathDescription)")
        if let vendor = device.vendor {
            print("  Vendor: \(vendor)")
        }
        if let vendorID = device.vendorID, let productID = device.productID {
            print("  VID:PID: \(vendorID):\(productID)")
        }
        if let serial = device.serialNumber {
            print("  Serial: \(serial)")
        }
        if let location = device.locationID {
            print("  Location: \(location)")
        }
        if let bsd = device.bsdName {
            print("  BSD Name: \(bsd)")
        }
        if let usbVersion = device.usbVersion {
            print("  USB Version: \(usbVersion)")
        }
        if let speed = device.deviceSpeed {
            print("  Speed: \(speed)")
        }
        if let currentAvailable = device.currentAvailable {
            print("  Current Available: \(currentAvailable)")
        }
        if let currentRequired = device.currentRequired {
            print("  Current Draw: \(currentRequired)")
        }
        if let extra = device.extraOperatingCurrent {
            print("  Extra Operating Current: \(extra)")
        }
        if device.interfaceCount > 0 {
            print("  Interfaces: \(device.interfaceCount)")
        }
        if let deviceClass = device.deviceClass {
            print("  Class/Subclass/Protocol: \(deviceClass)/\(device.deviceSubClass ?? "?")/\(device.deviceProtocol ?? "?")")
        }
        print("  Transport: \(device.transport.rawValue)")
        print("  Data/Power: \(device.dataPowerState.rawValue)")
        print("  Video: \(device.videoCapability.rawValue)")
    }

    private func printCable(_ cable: ThunderboltCableSummary) {
        print("• \(cable.name)")
        if let vendor = cable.vendor {
            print("  Vendor: \(vendor)")
        }
        if let productID = cable.productID {
            print("  Product ID: \(productID)")
        }
        if let serial = cable.serialNumber {
            print("  Serial: \(serial)")
        }
        if let type = cable.cableType {
            print("  Type: \(type)")
        }
        if let speed = cable.maxSpeed {
            print("  Max Speed: \(speed)")
        }
        if !cable.supportedProtocols.isEmpty {
            print("  Protocols: \(cable.supportedProtocols.joined(separator: ", "))")
        }
        print("  Video: \(cable.videoCapability.rawValue)")
    }
}
