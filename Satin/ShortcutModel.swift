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
    var windows: [AccessibilityWrapper] = []
    
    init?(shortcut: URL, key: String) {
        guard let code = Keycode.get(key: key) else { return nil }
        self.shortcut = URL(fileURLWithPath: shortcut.path, isDirectory: true)
        self.key      = key
        self.keycode  = code
        self.bundleIdentifier = ((Bundle(url: self.shortcut) ?? Bundle(path: self.shortcut.path))?.bundleIdentifier)!

    }
    
    private enum CodingKeys: String, CodingKey {
            case shortcut, key
        }
        
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let tempShortcut = try container.decode(URL.self,    forKey: .shortcut)
        let tempKey      = try container.decode(String.self, forKey: .key)
        self.init(shortcut: tempShortcut, key: tempKey)!
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(shortcut, forKey: .shortcut)
        try container.encode(key,      forKey: .key)
    }
    
    static func == (lhs: ShortcutModel, rhs: ShortcutModel) -> Bool {
        lhs.shortcut == rhs.shortcut && lhs.keycode == rhs.keycode
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(shortcut)
        hasher.combine(keycode)
    }

    func processID() -> pid_t? {
        guard let bundleID = Bundle(url: shortcut)?.bundleIdentifier else { return nil }
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        return runningApps.first?.processIdentifier
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
        let fileManager = FileManager.default
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        if fileManager.fileExists(atPath: shortcut.path) {
            NSWorkspace.shared.open(shortcut, configuration: config, completionHandler: nil)
        } else {
            NSSound.beep()
        }
        
        guard let pid = processID() else {
            return
        }

        windows = windowsForPID(pid)
        windows.sort()
        if windows.count > 1{
            if let currentIndex = windows.firstIndex(where: { $0.isMain() }) {
                let nextIndex = (currentIndex + 1) % windows.count
                windows[nextIndex].focus()
            } else {
                NSSound.beep()
            }
        }
        
    }
}
