import Foundation
import USBInspectorCore

let profiler = SystemProfiler()

do {
    let report = try profiler.collectReport()
    let usbDevices = USBTreeParser().parseDevices(from: report.usbNodes)
    let cables = ThunderboltParser().parseCables(from: report.thunderboltNodes)
    let printer = ConsolePrinter()
    printer.render(usbDevices: usbDevices, thunderboltCables: cables)
} catch {
    FileHandle.standardError.write(Data("Error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
