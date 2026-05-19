//
//  EventTapHandler.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation
import Cocoa

class EventTapHandler {
    let model: AppModel
    private var eventTap: CFMachPort?

    init(model: AppModel) {
        self.model = model
    }

    func startEventTap() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(model).toOpaque())

        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                          place: .headInsertEventTap,
                                          options: .defaultTap,
                                          eventsOfInterest: eventMask,
                                          callback: EventTapHandler.eventTapCallback,
                                          userInfo: refcon) else {
            DispatchQueue.main.async { self.showPermissionAlert() }
            return
        }

        eventTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func isTapEnabled() -> Bool {
        guard let tap = eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: tap)
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Open System Settings → Privacy & Security → Accessibility and enable Satin, then relaunch."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Dismiss")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }

    static let eventTapCallback: CGEventTapCallBack = { proxy, type, event, refcon in
        guard let nsEvent = NSEvent(cgEvent: event),
              let refcon = refcon else {
            return Unmanaged.passRetained(event)
        }

        let model = Unmanaged<AppModel>.fromOpaque(refcon).takeUnretainedValue()

        if nsEvent.modifierFlags.contains(.function) {
            if let shortcut = model.shortcuts.first(where: { $0.keycode == nsEvent.keyCode }) {
                shortcut.bringToFront()
                return nil
            }
        }

        return Unmanaged.passRetained(event)
    }
}
