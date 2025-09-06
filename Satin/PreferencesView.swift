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
    let model: AppModel;
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal, 10)
            Form {
                VStack(alignment: .leading){
                    Section {
                        HStack{
                            Text("Launch at Login:")
                                .font(.headline)
                                .padding(.horizontal, 15)
                            Spacer()
                            
                            LaunchAtLogin.Toggle()
                                .labelsHidden()
                                .padding(.vertical, 5)
                                .padding(.horizontal, 20)
                        }
                        
                        Text("Enables the program to launch when the user logs in.")
                            .font(.caption)
                            .padding(.horizontal, 15)
                            .padding(.bottom, 15)
                    }

                }
            }
        }
        .frame(width: 300, height: 150)
    }
}

class PreferencesWindowController: NSWindowController {
    convenience init(model: AppModel) {
        let preferencesView = PreferencesView(model: model)
        let hostingController = NSHostingController(rootView: preferencesView)
        let window = NSWindow(contentViewController: hostingController)

        self.init(window: window)
        window.title = NSLocalizedString("Preferences", comment: "Fönstertitel")
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    }
}
