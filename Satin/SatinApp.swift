//
//  SatinApp.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import SwiftUI

@main
struct SatinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings{
            EmptyView()
        }
    }
}
