import Cocoa
import CoreAudio

// MARK: - CoreAudio Helpers

func getAllAudioDevices() -> [AudioDeviceID] {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize) == noErr else { return [] }
    let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
    var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
    guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs) == noErr else { return [] }
    return deviceIDs
}

func getDeviceName(_ deviceID: AudioDeviceID) -> String {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceNameCFString,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var name: CFString = "" as CFString
    var dataSize = UInt32(MemoryLayout<CFString>.size)
    AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &dataSize, &name)
    return name as String
}

func deviceHasStreams(deviceID: AudioDeviceID, isInput: Bool) -> Bool {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyStreams,
        mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var dataSize: UInt32 = 0
    AudioObjectGetPropertyDataSize(deviceID, &propertyAddress, 0, nil, &dataSize)
    return dataSize > 0
}

func getDevices(isInput: Bool) -> [(id: AudioDeviceID, name: String)] {
    getAllAudioDevices()
        .filter { deviceHasStreams(deviceID: $0, isInput: isInput) }
        .map { (id: $0, name: getDeviceName($0)) }
}

func getDefaultDevice(isInput: Bool) -> AudioDeviceID {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var deviceID: AudioDeviceID = 0
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceID)
    return deviceID
}

func setDefaultDevice(_ deviceID: AudioDeviceID, isInput: Bool) {
    var propertyAddress = AudioObjectPropertyAddress(
        mSelector: isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    var mutableDeviceID = deviceID
    let dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, dataSize, &mutableDeviceID)
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "Audio Switcher")
            button.image?.isTemplate = true
        }

        statusItem?.menu = buildMenu()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.statusItem?.menu = self?.buildMenu()
        }
    }

    func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let defaultInput = getDefaultDevice(isInput: true)
        let defaultOutput = getDefaultDevice(isInput: false)
        let inputDevices = getDevices(isInput: true)
        let outputDevices = getDevices(isInput: false)

        // --- Output Section ---
        let outputHeader = NSMenuItem(title: "OUTPUT", action: nil, keyEquivalent: "")
        outputHeader.isEnabled = false
        outputHeader.attributedTitle = sectionHeader("OUTPUT")
        menu.addItem(outputHeader)

        for device in outputDevices {
            let item = NSMenuItem(
                title: device.name,
                action: #selector(selectOutputDevice(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.id
            item.state = device.id == defaultOutput ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // --- Input Section ---
        let inputHeader = NSMenuItem(title: "INPUT", action: nil, keyEquivalent: "")
        inputHeader.isEnabled = false
        inputHeader.attributedTitle = sectionHeader("INPUT")
        menu.addItem(inputHeader)

        for device in inputDevices {
            let item = NSMenuItem(
                title: device.name,
                action: #selector(selectInputDevice(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.id
            item.state = device.id == defaultInput ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Audio Switcher", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    func sectionHeader(_ title: String) -> NSAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        return NSAttributedString(string: title, attributes: attrs)
    }

    @objc func selectOutputDevice(_ sender: NSMenuItem) {
        guard let deviceID = sender.representedObject as? AudioDeviceID else { return }
        setDefaultDevice(deviceID, isInput: false)
        statusItem?.menu = buildMenu()
    }

    @objc func selectInputDevice(_ sender: NSMenuItem) {
        guard let deviceID = sender.representedObject as? AudioDeviceID else { return }
        setDefaultDevice(deviceID, isInput: true)
        statusItem?.menu = buildMenu()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
