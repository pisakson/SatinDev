//
//  AppDelegate.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-27.
//

import Foundation
import AppKit
import LaunchAtLogin
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let model = AppModel()
    

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        NSApp.hide(nil)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let image = NSImage(named: NSImage.Name("SBI")) {
                let scaledSize = NSSize(width: image.size.width * 0.27, height: image.size.height * 0.27)
                image.size = scaledSize
                button.image = image
                button.image?.isTemplate = true
            }
        }
        
        let menu = NSMenu()
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit Split", comment: "Statusbar item"), action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        checkIfAxOK()

        let eventTapHandler = EventTapHandler(model: model)
        eventTapHandler.startEventTap()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }

    func checkIfAxOK() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary?)
    }
}
