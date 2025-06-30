//
//  AccessibilityWrapper.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation
import Cocoa

class AccessibilityWrapper {
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
    
    func raiseWindow() {
        let result = AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        if result != .success {
            NSSound.beep()
        }
    }
    
    func  windowElements() -> [AccessibilityWrapper]{
        if let elements = element.getValue(.windows) as? [AXUIElement]{
            return elements.map{element in AccessibilityWrapper(element: element, processId: processId)};
        }
        return [];
    }
}

extension AXUIElement {
    func getValue(_ attribute: NSAccessibility.Attribute) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value
    }}
