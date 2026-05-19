//
//  ShortcutModel.swift
//  Satin
//
//  Created by Philip Isakson on 2025-07-08.
//

import Foundation
import AppKit
import CoreServices

class ShortcutModel: Encodable, Decodable, Identifiable, Equatable {
    let shortcut: URL
    let key: String
    let keycode: UInt16
    let bundleIdentifier: String
    private var cycleIndex = 0
    private var lastWindowCount = 0

    init?(shortcut: URL, key: String) {
        guard let code = Keycode.get(key: key) else { return nil }
        let url = URL(fileURLWithPath: shortcut.path, isDirectory: true)
        guard let bundleID = (Bundle(url: url) ?? Bundle(path: url.path))?.bundleIdentifier else { return nil }
        self.shortcut = url
        self.key = key
        self.keycode = code
        self.bundleIdentifier = bundleID
    }

    private enum CodingKeys: String, CodingKey {
        case shortcut, key
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tempShortcut = try container.decode(URL.self, forKey: .shortcut)
        let tempKey      = try container.decode(String.self, forKey: .key)
        guard let model = Self(shortcut: tempShortcut, key: tempKey) else {
            throw DecodingError.dataCorruptedError(forKey: .shortcut, in: container,
                debugDescription: "Could not initialise ShortcutModel from decoded values")
        }
        self.init(shortcut: model.shortcut, key: model.key)!
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(shortcut, forKey: .shortcut)
        try container.encode(key, forKey: .key)
    }

    static func == (lhs: ShortcutModel, rhs: ShortcutModel) -> Bool {
        lhs.shortcut == rhs.shortcut && lhs.keycode == rhs.keycode
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(shortcut)
        hasher.combine(keycode)
    }

    func windowsForPID(_ pid: pid_t) -> [AccessibilityWrapper] {
        let appElement = AXUIElementCreateApplication(pid)
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        if result == .success, let windowElements = value as? [AXUIElement] {
            return windowElements.map { AccessibilityWrapper(element: $0, processId: pid) }
        }
        return []
    }

    func bringToFront() {
        guard FileManager.default.fileExists(atPath: shortcut.path) else { NSSound.beep(); return }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open(shortcut, configuration: config) { runningApp, _ in
            guard let app = runningApp else { return }
            let pid = app.processIdentifier
            let wins = self.windowsForPID(pid)
                .filter { !$0.isMinimized() && !$0.isHidden() }
                .sorted()
            guard !wins.isEmpty else { return }

            if wins.count != self.lastWindowCount {
                self.cycleIndex = 0
                self.lastWindowCount = wins.count
            }

            wins[self.cycleIndex].focus()
            self.cycleIndex = (self.cycleIndex + 1) % wins.count
        }
    }
}
