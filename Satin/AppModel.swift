//
//  AppModel.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

//
//  AppModel.swift
//  Satin
//
//  Created by Philip Isakson on 2025-05-25.
//

import Foundation
import AppKit

// ──────────────────────────────────────────────────────────────
// MARK: – JSON wrapper (root object is { "keys": [ … ] })
struct ShortcutStore: Codable {
    var keys: [ShortcutModel]
}

// ──────────────────────────────────────────────────────────────
// MARK: – Model
final class AppModel: ObservableObject {

    // Published so SwiftUI refreshes when you add / remove
    @Published var shortcuts: [ShortcutModel] = []

    // ───────── Writable file location ─────────
    private var dataURL: URL {
        let fm      = FileManager.default
        let base    = fm.urls(for: .applicationSupportDirectory,
                              in: .userDomainMask).first!
        let appID   = Bundle.main.bundleIdentifier ?? "Satin"
        let dirURL  = base.appendingPathComponent(appID, isDirectory: true)
        try? fm.createDirectory(at: dirURL,
                                withIntermediateDirectories: true,
                                attributes: nil)
        return dirURL.appendingPathComponent("Shortcuts.json")
    }

    // ───────── Init – seed file if needed, then load ─────────
    init() {
        seedIfNeeded()
        load()
    }

    private func seedIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: dataURL.path) else { return }

        if let bundled = Bundle.main.url(forResource: "Shortcuts", withExtension: "json") {
            try? fm.copyItem(at: bundled, to: dataURL)
        }
    }

    // ───────── File I/O helpers ─────────
    private func load() {
        guard let data = try? Data(contentsOf: dataURL) else { return }
        if let store = try? JSONDecoder().decode(ShortcutStore.self, from: data) {
            shortcuts = store.keys
        }
    }

    private func persist() {
        let blob = ShortcutStore(keys: shortcuts)
        guard let data = try? JSONEncoder().encode(blob) else { return }
        try? data.write(to: dataURL, options: .atomic)     // crash-safe swap
    }

    // ───────── Public API called from the view ─────────
    func addNewShortcut(key: String, url path: String) {
        guard
            let model = ShortcutModel(shortcut: URL(fileURLWithPath: path), key: key),
            !shortcuts.contains(where: { $0.key == model.key })
        else { NSSound.beep(); return }

        shortcuts.append(model)
        persist()
    }

    func removeShortcut(key: String) {
        shortcuts.removeAll { $0.key == key }
        persist()
    }
}
