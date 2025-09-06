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
    var contentWindowController: ContentViewController?
    var preferencesWindowController: PreferencesWindowController?
    
    

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        NSApp.hide(nil)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let image = NSImage(named: NSImage.Name("SBI")) {
            let scaledSize = NSSize(width: image.size.width * 0.09, height: image.size.height * 0.09)
            image.size = scaledSize
            statusItem = NSStatusBar.system.statusItem(withLength: scaledSize.width * 0.9)
            if let button = statusItem.button {
                button.image = image
                button.image?.isTemplate = true
            }
        } else {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("Shortcuts", comment: "Statusbar item"), action: #selector(showContentWindow(_:)), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Preferences", comment: "Statusbar item"), action: #selector(showPreferencesWindow(_:)), keyEquivalent: "p"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit Satin", comment: "Statusbar item"), action: #selector(quit), keyEquivalent: "q"))
        
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
    
    @objc func showContentWindow(_ sender: Any?) {
        if contentWindowController == nil {
            contentWindowController = ContentViewController(model: model
            )
        }
        contentWindowController?.showWindow(nil)
        
        if let preferencesWindow = contentWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            preferencesWindow.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc func showPreferencesWindow(_ sender: Any?) {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(model: model
            )
        }
        preferencesWindowController?.showWindow(nil)
        
        if let preferencesWindow = preferencesWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            preferencesWindow.makeKeyAndOrderFront(nil)
        }
    }
    
}
