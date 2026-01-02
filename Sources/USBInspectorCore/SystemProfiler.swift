import Foundation

public enum SystemProfilerError: Error, LocalizedError {
    case commandFailed(Int32, String)
    case malformedJSON

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(status, message):
            return "system_profiler exited with \(status): \(message)"
        case .malformedJSON:
            return "Failed to decode system_profiler JSON payload."
        }
    }
}

public struct SystemReport {
    public let usbNodes: [JSONDict]
    public let thunderboltNodes: [JSONDict]

    public init(jsonData: Data) throws {
        let object = try JSONSerialization.jsonObject(with: jsonData, options: [])
        guard let dict = object as? [String: Any] else {
            throw SystemProfilerError.malformedJSON
        }
        usbNodes = dict["SPUSBDataType"] as? [JSONDict] ?? []
        thunderboltNodes = dict["SPThunderboltDataType"] as? [JSONDict] ?? []
    }
}

public struct SystemProfiler {
    public init() {}

    public func collectReport() throws -> SystemReport {
        let data = try runSystemProfiler()
        return try SystemReport(jsonData: data)
    }

    private func runSystemProfiler() throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["-json", "SPUSBDataType", "SPThunderboltDataType"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
            throw SystemProfilerError.commandFailed(process.terminationStatus, errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outputPipe.fileHandleForReading.readDataToEndOfFile()
    }
}
