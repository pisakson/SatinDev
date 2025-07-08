//
//  AccessibilityWrapper.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation
import Cocoa

class AccessibilityWrapper: Comparable {
    private let element: AXUIElement;
    private let processId: pid_t;
    
    init(element: AXUIElement, processId: pid_t) {
        self.element = element;
        self.processId = processId;
    }
    
    private func copyAttributeValue<Type>(of attribute: String) -> Type? {
        var ref: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &ref)
        if result == .success { return ref as? Type }
        return nil
    }
    
    private func fetch(kAXAttribute: String) -> Bool {
        if let result: Bool = copyAttributeValue(of: kAXAttribute) {
            return result;
        }
        return false;
    }
    
    func getAXWindowPosition() -> CGPoint? {
        var positionValue: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)

        guard error == .success,
              let value = positionValue,
              CFGetTypeID(value) == AXValueGetTypeID(),
              AXValueGetType(value as! AXValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        if AXValueGetValue(value as! AXValue, .cgPoint, &point) {
            return point
        }

        return nil
    }
    
    func isMinimized() -> Bool {
        return fetch(kAXAttribute: kAXMinimizedAttribute);
    }
    
    func isHidden() -> Bool {
        return fetch(kAXAttribute: kAXHiddenAttribute)
    }
    
    func isFocused() -> Bool {
        let sysWide = AXUIElementCreateSystemWide()
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(sysWide,
                                         kAXFocusedWindowAttribute as CFString,
                                         &ref) == .success,
           let focusedWin = ref {
            return CFEqual(focusedWin, element)
        }
        return false
    }
    
    func isFrontmostWindow() -> Bool {
        let sysWide = AXUIElementCreateSystemWide()
        var ref: CFTypeRef?
        if AXUIElementCopyAttributeValue(sysWide,
                                         kAXFocusedWindowAttribute as CFString,
                                         &ref) == .success,
           let focused = ref {
            return CFEqual(focused, element)
        }
        return false
    }
    
    func focus() {
        if let app = NSRunningApplication(processIdentifier: self.processId) {
            app.activate()
        } else {
            NSSound.beep()
            return
        }
        AXUIElementSetAttributeValue(self.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(self.element, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        AXUIElementPerformAction(self.element, kAXRaiseAction as CFString)
    }
    
    func isMain() -> Bool{
        return fetch(kAXAttribute: kAXMainAttribute)
    }

    
    func windowElements() -> [AccessibilityWrapper]{
        if let elements = element.getValue(.windows) as? [AXUIElement]{
            return elements.map{element in AccessibilityWrapper(element: element, processId: processId)};
        }
        return [];
    }
    
    static func < (lhs: AccessibilityWrapper, rhs: AccessibilityWrapper) -> Bool {
        guard let lpos: CGPoint = lhs.getAXWindowPosition(),
                let rpos: CGPoint = rhs.getAXWindowPosition()
        else {
            return false
        }

        if lpos.x != rpos.x {
            return lpos.x < rpos.x
        } else {
            return lpos.y < rpos.y
        }
    }
    
    static func == (lhs: AccessibilityWrapper, rhs: AccessibilityWrapper) -> Bool {
        return lhs.element == rhs.element
    }
}

extension AXUIElement {
    func getValue(_ attribute: NSAccessibility.Attribute) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value
    }}
