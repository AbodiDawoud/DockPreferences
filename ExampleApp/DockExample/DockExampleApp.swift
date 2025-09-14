//
//  Demo.swift
//  DockExample
    

import SwiftUI
import DockPreferences

@main
struct DockExampleApp: App {
    var body: some Scene {
        WindowGroup {
            DockPreferencesDemoView()
        }
    }
}

struct DockPreferencesDemoView: View {
    @State private var prefs: DockPreferences? = nil
    @State private var errorMessage: String? = nil
    

    var body: some View {
        Group {
            if let prefs {
                Form {
                    Section("General") {
                        LabeledContent("Show Recents", value: prefs.showRecents.str)
                        LabeledContent("Autohide Dock", value: prefs.autohide.str)
                        LabeledContent("Shows Process Indicators", value: prefs.showsProcessIndicators.str)
                        LabeledContent("Minimize Effect", value: prefs.mineffect.rawValue.capitalized)
                        LabeledContent("Orientation", value: prefs.orientation.rawValue.capitalized)
                        
                        if let trashFull = prefs.trashFull {
                            LabeledContent("Trash State") {
                                Image(trashFull ? "Trash_Full" : "Trash_Empty")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        Button("Dock Preferences", action: prefs.openDockPreferences)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    Section("Persistent Apps") {
                        ForEach(prefs.persistentApps, id: \.tileData.bundleIdentifier) { app in
                            HStack {
                                if let icon = app.appIcon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                                
                                Text(app.tileData.fileLabel)
                                
                                Spacer()
                                
                                Button(action: app.launch) {
                                    Text("Launch")
                                        .font(.footnote.weight(.medium))
                                        .opacity(0.75)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(.gray.opacity(0.1), in: .capsule)
                                }
                                .buttonStyle(.borderless)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    if !prefs.recentApps.isEmpty && prefs.showRecents {
                        Section("Recent Apps") {
                            ForEach(prefs.recentApps, id: \.tileData.bundleIdentifier) { app in
                                HStack {
                                    if let icon = app.appIcon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                    }
                                    
                                    Text(app.tileData.fileLabel)
                                    
                                    Spacer()
                                    
                                    Button(action: app.terminate) {
                                        Text("Terminate")
                                            .font(.footnote.weight(.medium))
                                            .opacity(0.75)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(.gray.opacity(0.1), in: .capsule)
                                    }
                                    .buttonStyle(.borderless)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }
                    
                    if prefs.files.isEmpty == false {
                        Section("Files & Folders") {
                            ForEach(prefs.files, id: \.tileData.fileLabel) { file in
                                HStack {
                                    if let icon = file.fileIcon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(file.tileData.fileLabel)
                                            .font(.headline)
                                        Text(file.tileData.filePath)
                                            .font(.subheadline.weight(.light))
                                            .foregroundStyle(.gray)
                                    }
                                    .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                .formStyle(.grouped)
            } else if let errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding(30)
            } else {
                ProgressView("Loading Dock Preferences…")
                    .padding(30)
            }
        }
        .task { await loadPreferences() }
    }

    
    
    private func loadPreferences() async {
        do {
            prefs = try DockPreferencesLoader.load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension Bool {
    var str: String { String(self).capitalized }
}
