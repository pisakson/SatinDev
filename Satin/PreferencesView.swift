//
//  PreferencesView.swift
//  Satin
//
//  Created by Philip Isakson on 2025-07-11.
//


import Foundation
import LaunchAtLogin
import SwiftUI

struct PreferencesView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Launch at Login")
                    Text("Start Satin automatically when you log in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                LaunchAtLogin.Toggle()
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
        }
        .frame(width: 320)
    }
}

class PreferencesWindowController: NSWindowController {
    convenience init(model: AppModel) {
        let preferencesView = PreferencesView(model: model)
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)

        self.init(window: window)
        window.title = NSLocalizedString("Preferences", comment: "Fönstertitel")
        window.styleMask = [.titled, .closable]
    }
}
