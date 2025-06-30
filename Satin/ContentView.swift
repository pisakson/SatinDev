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
    @State private var showRemoveSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ─────────── List of shortcuts ───────────
            List(model.shortcuts) { shortcut in
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
                Button("Remove Shortcut") { showRemoveSheet = true }
                Spacer()
                Button("Cancel") { NSApplication.shared.keyWindow?.close() }
            }
            .padding([.horizontal, .bottom])
        }
        .frame(minWidth: 300, minHeight: 300)
        .sheet(isPresented: $showAddSheet) {
            AddShortcutSheet(model: model)
        }
        .sheet(isPresented: $showRemoveSheet) {
            RemoveShortcutSheet(model: model)
        }
    }
    
    private func icon(for model: ShortcutModel) -> NSImage {
        let image = NSWorkspace.shared.icon(forFile: model.shortcut.path)
        image.size = NSSize(width: 32, height: 32)
        return image
    }
}

// MARK: - Add Shortcut Sheet
struct AddShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel
    
    @State private var selectedURL: URL?
    @State private var keyString    = ""
    @State private var showImporter = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Shortcut").font(.title2)
            
            HStack {
                Text("App:")
                if let url = selectedURL {
                    Text(url.lastPathComponent).lineLimit(1)
                } else {
                    Text("None selected").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Choose …") { showImporter = true }
            }
            
            TextField("Key (single letter)", text: $keyString)
                .onChange(of: keyString) { newVal in
                    // Accept only one alphabetic char
                    keyString = String(newVal.uppercased().prefix(1).filter { $0.isLetter })
                }
                .frame(width: 150)
            
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Add") {
                    if let url = selectedURL {
                        model.addNewShortcut(key: keyString, url: url.path())
                        dismiss()
                    }
                }
                .disabled(selectedURL == nil || keyString.isEmpty)
            }
        }
        .padding(24)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [UTType.application],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result { selectedURL = urls.first }
        }
        .frame(width: 420)
    }
}

// MARK: - Remove Shortcut Sheet
struct RemoveShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel
    
    @State private var selectedKey: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Remove Shortcut").font(.title2)
            
            Picker("Shortcut Key", selection: $selectedKey) {
                ForEach(model.shortcuts) { shortcut in
                    Text(shortcut.key).tag(Optional(shortcut.key))
                }
            }
            .pickerStyle(.radioGroup)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Remove") {
                    if let key = selectedKey { model.removeShortcut(key: key); dismiss() }
                }
                .disabled(selectedKey == nil)
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}

// MARK: - Preview
#Preview {
    ContentView(model: AppModel())
}
