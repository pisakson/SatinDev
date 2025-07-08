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

    init(model: AppModel) {
        self.model = model
    }

    func startEventTap() {
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(model).toOpaque())

        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: eventMask,
                                               callback: EventTapHandler.eventTapCallback,
                                               userInfo: refcon) else {
            exit(1)
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    static let eventTapCallback: CGEventTapCallBack = { proxy, type, event, refcon in
        guard let nsEvent = NSEvent(cgEvent: event),
              let refcon = refcon else {
            return Unmanaged.passRetained(event)
        }

        let model = Unmanaged<AppModel>.fromOpaque(refcon).takeUnretainedValue()

        if nsEvent.modifierFlags.contains(.function) {
            if let shortcut = model.shortcuts.first(where: { short in nsEvent.keyCode == short.keycode }) {
                shortcut.bringToFront()
                return nil
            }
        }

        return Unmanaged.passRetained(event)
    }

}



