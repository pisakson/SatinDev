//
//  ContentView.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

// ContentView.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Main View
struct ContentView: View {
    @ObservedObject var model: AppModel
    
    @State private var showAddSheet    = false
    @State private var selected: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            List(model.shortcuts, id: \.shortcut, selection: $selected) { shortcut in
                HStack(spacing: 12) {
                    Image(nsImage: icon(for: shortcut))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .cornerRadius(6)
                    
                    VStack(alignment: .leading) {
                        Text(shortcut.shortcut.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                            .font(.headline)
                        Text("Shortcut command: fn + \(shortcut.key)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .contextMenu {
                    Button("Open") { shortcut.bringToFront() }
                }
            }
            .listStyle(.inset)
            
            Divider()
            
            HStack {
                Button("Add Shortcut") { showAddSheet = true }
                Button("Remove Shortcut") { 
                    if let selected = selected,
                       let shortcut = model.shortcuts.first(where: { $0.shortcut == selected }) {
                        model.removeShortcut(key: shortcut.key)
                        self.selected = nil
                    } else {
                        NSSound.beep()
                    }
                }
                Spacer()
                Button("Cancel") { NSApplication.shared.keyWindow?.close() }
                 .keyboardShortcut(.defaultAction)
            }
            .padding(10)
        }
        .frame(minWidth: 420, minHeight: 300)
        .sheet(isPresented: $showAddSheet) {
            AddShortcutSheet(model: model)
        }
    }
    
    private func icon(for model: ShortcutModel) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: model.shortcut.path)
        image.size = NSSize(width: 32, height: 32)
        return image
    }
}

struct AddShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel
    
    @State private var selectedURL: URL?
    @State private var keyString    = ""
    @State private var showImporter = false
    
    var body: some View {
        VStack() {
            HStack{
                Text("New shortcut:").font(.title)
                    .fontWeight(.bold)
                    .padding([.top, .horizontal])
                Spacer()
            }
                
            VStack(spacing: 10){
                HStack {
                    Text("App:")
                    Spacer()
                    if let url = selectedURL {
                        Text(url.lastPathComponent).lineLimit(1)
                    } else {
                        Text("None selected").foregroundStyle(.secondary)
                    }
                    Button("Choose app...") { showImporter = true }
                }
                .padding([.top, .horizontal])
                
                TextField("Key:", text: $keyString)
                    .onChange(of: keyString) { newVal in
                        keyString = String(newVal.uppercased().prefix(1).filter { $0.isLetter })
                    }
                    .padding([.bottom, .horizontal])
            }
            .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            Color(nsColor: .disabledControlTextColor),
                            lineWidth: 2
                        )
                )
            .padding([.horizontal, .bottom])
            
            HStack {
                Button("Cancel") { dismiss() }
                Button("Add") {
                    if let url = selectedURL {
                        model.addNewShortcut(key: keyString, url: url.path())
                        dismiss()
                    }
                }
                .disabled(selectedURL == nil || keyString.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            
            .padding()
        }
        .frame(width: 320)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [UTType.application],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result { selectedURL = urls.first }
        }
    }
        
        
}

class ContentViewController:NSWindowController {
    convenience init(model: AppModel) {
        let contentView = ContentView(model: model)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        self.init(window: window)
        window.title = NSLocalizedString("Satin", comment: "Fönstertitel")
        window.styleMask = [.titled, .closable]
    }
}


// MARK: - Preview
#Preview {
    ContentView(model: AppModel())
}

