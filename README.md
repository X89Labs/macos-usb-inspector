# USBInspector

USBInspector is a lightweight macOS diagnostics suite written in Swift. It consists of:

1. **USBInspector (CLI)** – A terminal-friendly reporter that surfaces the USB/USB‑C/Thunderbolt information that `system_profiler` already knows and reshapes it into a cable/port diagnostics report.
2. **USBInspectorApp (SwiftUI)** – A macOS GUI with filtering, status badges, and live refresh so you can quickly validate cables without leaving the desktop.

It focuses on the information most people look for when validating a USB‑C cable:

- whether the attached accessory negotiated a USB data connection (a good proxy for “data + power” vs. “power only” cables)
- the transport revision reported by the device (USB 2.0/3.0/3.1/3.2/USB4)
- negotiated bus power (current available vs. required)
- whether a smart USB4/Thunderbolt cable advertises DisplayPort/Alt-Mode support

> ⚠️ Limitations  
> macOS can only report what a connected device or e‑marked cable shares with the host. Passive/charging-only cables do not have firmware, so they never appear in the Thunderbolt section and cannot be inspected. Likewise, DisplayPort capability can only be inferred for e‑marked USB4/Thunderbolt cables that list DisplayPort in their descriptor; standard USB 2.0/3.x cables never expose that data.

## Building

The project uses Swift Package Manager and targets macOS 13+.

```bash
cd macos-usb-inspector
# Build the CLI
swift build -c release --product USBInspector

# Build the SwiftUI app (creates USBInspectorApp.app inside .build)
swift build -c release --product USBInspectorApp
```

The CLI binary lives at `.build/release/USBInspector`. Copy it to a location on your `$PATH` or run it in place (`swift run USBInspector` during development).

The SwiftUI target compiles into `.build/release/USBInspectorApp`. When built through Xcode you will also get a signed `.app` bundle that you can drag into `/Applications`.

> Tip: `open Package.swift` in Xcode to get proper SwiftUI previews and an app bundle. Both the CLI and the app share the same `USBInspectorCore` module, so fixes in the parser benefit both experiences.

## Usage

### CLI

```bash
./.build/debug/USBInspector
```

The tool internally runs:

```bash
/usr/sbin/system_profiler -json SPUSBDataType SPThunderboltDataType
```

and converts the JSON into two concise sections:

1. **USB Devices** – Each leaf node in the USB tree with transport, bus power, and data/power heuristics.
2. **USB4 / Thunderbolt Cables** – Any smart cable that macOS recognizes (Apple TB4, certified USB4 cables, etc.), including its advertised speed, supported protocols, and whether DisplayPort Alt‑Mode is listed.

Because `system_profiler` requires elevated hardware access, expect the command to take 1‑3 seconds. The tool exits with a non‑zero code if `system_profiler` returns an error so you can wrap it in scripts or CI diagnostics.

### SwiftUI app

1. Build/run the `USBInspectorApp` scheme in Xcode or execute `swift run USBInspectorApp`.
2. Click the refresh button (⌘R) to collect the latest report.
3. Filter devices/cables using the search field. Badges indicate transport, data vs. power-only cables, and inferred DisplayPort/Alt-Mode support.

The GUI uses the same heuristics as the CLI, so you can keep the app pinned while hot-plugging cables to watch capabilities change in real time.

## Packaging

For distribution you can script the following:

1. `swift build -c release --product USBInspector`  
   Copy `.build/release/USBInspector` to `/usr/local/bin` (or bundle it inside a `.pkg` via `pkgbuild --install-location /usr/local/bin --component USBInspector.pkg/USBInspector`).  
2. `swift build -c release --product USBInspectorApp`  
   Wrap `.build/release/USBInspectorApp.app` in a signed/notarized zip or use `productbuild` to ship an installer that drops it into `/Applications`.

Because both targets are plain SwiftPM products you can run these steps in CI and notarize/sign afterwards.

## Extending the heuristics

- **Better “data vs. power only” signal** – Today the tool assumes any enumerated device negotiated data. You can tighten that by also checking for descriptors such as `bDeviceClass == 0x00` (composite) or `bDeviceProtocol`.  
- **Charge-rate math** – The current draw/available fields are exposed as raw numbers; you could convert that into watts given the negotiated voltage retrieved from `IOUSBHostInterface`.  
- **USB-C ALT modes** – Full DisplayPort/TBT capability lives under `IOThunderboltPort` in the IORegistry. If you need to be more exact, add an IOKit query that looks for `IOThunderboltAlternateModeClient` entries attached to the relevant port.

Recent additions already improve these heuristics:

- The CLI and GUI label “power only” cables when `system_profiler` reports bus power but no data interfaces/VID/PID, and treat enumerated interfaces/BSD names as proof of data capability.
- Video capability now looks for DisplayPort/HDMI keywords on devices and USB4/Thunderbolt e-markers on cables, giving you a quick read before plugging into a monitor.

Pull requests welcome!
