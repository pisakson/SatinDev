//
//  ShortcutModel.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation
import AppKit
import Carbon.HIToolbox


class ShortcutModel: Encodable, Decodable, Identifiable {
    let shortcut: URL
    let key: String
    let keycode: UInt16
    var id: String { shortcut.path }
    var windows: [AccessibilityWrapper] = []
    private var bundleIdentifier: String;
    
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
    
    func axsFromPid(pid: pid_t) -> [AccessibilityWrapper] {
        let appElement = AXUIElementCreateApplication(pid)
        
        var value: CFTypeRef?
        var axs: [AccessibilityWrapper] = []
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success,
           let windows = value as? [AXUIElement] {
            for window in windows {
                axs.append(AccessibilityWrapper(element: window, processId: pid))
            }
        }
        
        axs = axs.flatMap {window in window.windowElements() }
        
        return axs.filter{ wrapper in !wrapper.isMinimized() && !wrapper.isHidden()}
    }
    
    func bringToFront() {

        if let running = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
                            .first {
            print(bundleIdentifier)
            print(running)

            windows = axsFromPid(pid: running.processIdentifier)
            print(windows)
            guard !windows.isEmpty else { running.activate(); return }
            
            print(windows.map {window in window.isFrontmostWindow()})
            // 2. Find the currently focused window in that fresh list
            if let focusedIdx = windows.firstIndex(where: {window in window.isFocused()}) {
                print(focusedIdx)

                // 3. Pick the *next* window (wrap around)
                let nextIdx   = windows.index(after: focusedIdx)
                let targetWin = windows[nextIdx == windows.count ? 0 : nextIdx]

                targetWin.raiseWindow()
                running.activate()
                return
            }
            running.activate()
            print("now the app should be running")
            return
        }

        
        guard shortcut.isFileURL,
              shortcut.pathExtension == "app",
              FileManager.default.fileExists(atPath: shortcut.path) else {
            NSSound.beep(); return
        }

        let cfg = NSWorkspace.OpenConfiguration()

        NSWorkspace.shared.openApplication(at: shortcut,
                                           configuration: cfg) { app, error in
            if let app = app {
                self.windows = self.axsFromPid(pid: app.processIdentifier)
            } else {
                NSSound.beep()
            }
        }
    }


}
