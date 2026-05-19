// ContentView.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Keyboard Badge
private struct KeyBadge: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
            )
    }
}

// MARK: - Shortcut Row
private struct ShortcutRow: View {
    let shortcut: ShortcutModel
    let icon: NSImage

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(shortcut.shortcut.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                    .font(.headline)
                Text("Activated with fn +")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                KeyBadge(label: "fn")
                Text("+")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                KeyBadge(label: shortcut.key)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Open") { shortcut.bringToFront() }
        }
    }
}

// MARK: - Empty State
private struct EmptyShortcutsView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "keyboard")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No Shortcuts")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add a shortcut to quickly switch to any app.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Main View
struct ContentView: View {
    @ObservedObject var model: AppModel

    @State private var showAddSheet = false
    @State private var selected: URL?

    var body: some View {
        VStack(spacing: 0) {
            if model.shortcuts.isEmpty {
                EmptyShortcutsView()
            } else {
                List(model.shortcuts, id: \.shortcut, selection: $selected) { shortcut in
                    ShortcutRow(shortcut: shortcut, icon: icon(for: shortcut))
                }
                .listStyle(.inset)
            }

            Divider()

            HStack(spacing: 8) {
                Button("Add Shortcut") { showAddSheet = true }

                Button("Remove", role: .destructive) {
                    if let selected = selected,
                       let shortcut = model.shortcuts.first(where: { $0.shortcut == selected }) {
                        model.removeShortcut(key: shortcut.key)
                        self.selected = nil
                    } else {
                        NSSound.beep()
                    }
                }
                .disabled(selected == nil)

                Spacer()

                Button("Done") { NSApplication.shared.keyWindow?.close() }
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

// MARK: - Add Shortcut Sheet
struct AddShortcutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: AppModel

    @State private var selectedURL: URL?
    @State private var keyString    = ""
    @State private var showImporter = false
    @State private var showAddError = false

    private var isDuplicateKey: Bool {
        !keyString.isEmpty && model.shortcuts.contains(where: { $0.key == keyString })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("New Shortcut")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            VStack(spacing: 0) {
                // App picker row
                HStack {
                    Text("App")
                        .frame(width: 60, alignment: .leading)

                    if let url = selectedURL {
                        Text(url.lastPathComponent.replacingOccurrences(of: ".app", with: ""))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    } else {
                        Text("None selected")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose…") { showImporter = true }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()
                    .padding(.leading, 20)

                // Key row
                HStack(spacing: 16) {
                    Text("Key")
                        .frame(width: 60, alignment: .leading)

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.08))
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(
                                Color.primary.opacity(keyString.isEmpty ? 0.18 : 0.28),
                                style: keyString.isEmpty
                                    ? StrokeStyle(lineWidth: 1, dash: [4, 3])
                                    : StrokeStyle(lineWidth: 1)
                            )
                        if keyString.isEmpty {
                            Text("A")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.tertiary)
                        }
                        TextField("", text: $keyString)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.primary)
                            .onChange(of: keyString) { newVal in
                                keyString = String(newVal.uppercased().prefix(1).filter { $0.isLetter })
                            }
                    }
                    .frame(width: 44, height: 32)

                    if !keyString.isEmpty {
                        HStack(spacing: 4) {
                            KeyBadge(label: "fn")
                            Text("+")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                            KeyBadge(label: keyString)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .animation(.easeInOut(duration: 0.15), value: keyString.isEmpty)

                if isDuplicateKey {
                    HStack {
                        Spacer().frame(width: 80)
                        Text("Key \"\(keyString)\" is already assigned.")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }

            Divider()

            HStack {
                Button("Cancel", role: .cancel) { dismiss() }
                Spacer()
                Button("Add") {
                    if let url = selectedURL {
                        if model.addNewShortcut(key: keyString, url: url) {
                            dismiss()
                        } else {
                            showAddError = true
                        }
                    }
                }
                .disabled(selectedURL == nil || keyString.isEmpty || isDuplicateKey)
                .keyboardShortcut(.defaultAction)
                .alert("Couldn't Add Shortcut", isPresented: $showAddError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("The app could not be read. Make sure it's a valid application.")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 360)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [UTType.application],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                _ = url.startAccessingSecurityScopedResource()
                selectedURL = url
            }
        }
    }
}

class ContentViewController: NSWindowController {
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
